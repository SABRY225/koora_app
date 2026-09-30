import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/api_service.dart';
import '../utils/token_manager.dart';
import '../models/models.dart' as md;

class DraftProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  IO.Socket? _socket;
  
  bool _isLoading = false;
  String? _errorMessage;

  String? _gameId;
  String? _status;
  int _currentTurn = 1;
  int _timerSeconds = 35;
  String? _myParticipantId;
  
  List<dynamic> _turns = [];
  List<dynamic> _selections = [];
  List<md.FootballPlayer> _availablePlayers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get status => _status;
  int get currentTurn => _currentTurn;
  int get timerSeconds => _timerSeconds;
  List<dynamic> get turns => _turns;
  List<dynamic> get selections => _selections;
  List<md.FootballPlayer> get availablePlayers => _availablePlayers;

  List<md.FootballPlayer> get myTeam {
    if (_myParticipantId == null) return [];
    return _selections
        .where((s) => s['participantId'] == _myParticipantId)
        .map<md.FootballPlayer>((s) => md.FootballPlayer(
              id: s['playerId']?.toString() ?? '',
              name: s['playerName'] ?? '',
              position: md.PlayerPosition.values.firstWhere(
                (e) => e.name.toUpperCase() == (s['playerPosition'] ?? ''),
                orElse: () => md.PlayerPosition.attack,
              ),
              teamName: 'Team',
              teamLogo: 'T',
              points: 0.0,
            ))
        .toList();
  }

  Timer? _localTimer;

  Future<void> connectAndJoin(String gameId, String userId) async {
    _gameId = gameId;
    final token = await TokenManager.getToken();
    
    // Fetch game details to get participant ID
    try {
      final gameRes = await _apiService.get('/games/$_gameId');
      final participants = gameRes['data']['participants'] as List? ?? [];
      final me = participants.firstWhere((p) => p['userId'] == userId, orElse: () => null);
      if (me != null) {
        _myParticipantId = me['id'];
      }
    } catch (e) {
      print('Failed to get game details: $e');
    }

    // Initial fetch to get state before socket takes over
    await fetchDraftState();

    _socket = IO.io(ApiService.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .build());

    _socket?.onConnect((_) {
      print('Socket connected');
      _socket?.emit('join:room', gameId);
    });

    _socket?.on('game:draft-start', (data) {
      _status = data['status'];
      _currentTurn = data['currentTurn'] ?? 1;
      _startLocalTimer(data['expiresAt']);
      fetchDraftState(); // Refresh full state just in case
    });

    _socket?.on('game:draft-turn', (data) {
      _currentTurn = data['turnNumber'] ?? _currentTurn;
      _startLocalTimer(data['expiresAt']);
      notifyListeners();
    });

    _socket?.on('game:player-selected', (data) {
      // Re-fetch state to get updated lists
      fetchDraftState();
    });

    _socket?.on('game:auto-pick', (data) {
      fetchDraftState();
    });

    _socket?.on('game:draft-completed', (data) {
      _status = data['status'];
      _localTimer?.cancel();
      notifyListeners();
    });
  }

  void _startLocalTimer(String? expiresAtStr) {
    _localTimer?.cancel();
    if (expiresAtStr == null) return;
    
    final expiresAt = DateTime.parse(expiresAtStr).toLocal();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = expiresAt.difference(now).inSeconds;
      if (diff >= 0) {
        _timerSeconds = diff;
        notifyListeners();
      } else {
        _timerSeconds = 0;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void disconnect() {
    _localTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> fetchDraftState() async {
    if (_gameId == null) return;
    try {
      final response = await _apiService.get('/games/$_gameId/draft');
      final data = response['data'];
      _status = data['status'];
      _currentTurn = data['currentDraftTurn'] ?? 1;
      _turns = data['turns'] ?? [];
      _selections = data['selections'] ?? [];
      
      final activeTurn = data['activeTurn'];
      if (activeTurn != null) {
        _startLocalTimer(activeTurn['expiresAt']);
      }

      final rawPlayers = data['availablePlayers'] as List? ?? [];
      _availablePlayers = rawPlayers.map<md.FootballPlayer>((p) => md.FootballPlayer(
        id: p['id'].toString(),
        name: p['name'],
        position: md.PlayerPosition.values.firstWhere(
          (e) => e.name.toUpperCase() == p['position'],
          orElse: () => md.PlayerPosition.attack,
        ),
        teamName: 'Team',
        teamLogo: p['photoUrl'] ?? 'T',
        points: p['avgPoints']?.toDouble() ?? 0.0,
      )).toList();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> selectPlayer(String playerId) async {
    if (_gameId == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post('/games/$_gameId/draft/select', {
        'playerId': playerId,
        'turnNumber': _currentTurn.toString(),
      });
      // The socket event will trigger a state refresh, but we can also manually refresh
      // await fetchDraftState();
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
