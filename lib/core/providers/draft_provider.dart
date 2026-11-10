import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/api_service.dart';
import '../services/sound_service.dart';
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
  int _timerSeconds = 30;
  String? _myParticipantId;

  List<dynamic> _participants = [];
  List<dynamic> _turns = [];
  List<dynamic> _selections = [];
  List<md.FootballPlayer> _availablePlayers = [];
  Map<String, dynamic>? _activeTurn;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get status => _status;
  int get currentTurn => _currentTurn;
  int get timerSeconds => _timerSeconds;
  String? get myParticipantId => _myParticipantId;
  List<dynamic> get participants => _participants;
  List<dynamic> get turns => _turns;
  List<dynamic> get selections => _selections;
  List<md.FootballPlayer> get availablePlayers => _availablePlayers;
  Map<String, dynamic>? get activeTurn => _activeTurn;

  static md.PlayerPosition parsePosition(dynamic raw) {
    if (raw == null) return md.PlayerPosition.attack;
    final p = raw.toString().toUpperCase();
    if (p.contains('DEF')) return md.PlayerPosition.defense;
    if (p.contains('MID')) return md.PlayerPosition.midfield;
    if (p.contains('GOAL') || p.contains('GK')) return md.PlayerPosition.goalkeeper;
    return md.PlayerPosition.attack;
  }

  bool get isMyTurn {
    if (_activeTurn == null || _myParticipantId == null) return false;
    return _activeTurn?['participantId'] == _myParticipantId;
  }

  String get activePlayerName {
    if (isMyTurn) return 'أنت';
    final p = _participants.firstWhere(
      (part) => part['id'] == _activeTurn?['participantId'],
      orElse: () => null,
    );
    return p?['username'] ?? _activeTurn?['username'] ?? 'الخصم';
  }

  List<md.FootballPlayer> get myTeam {
    if (_myParticipantId == null) return [];
    return _selections
        .where((s) => s['participantId'] == _myParticipantId)
        .map<md.FootballPlayer>((s) => md.FootballPlayer(
              id: s['playerId']?.toString() ?? '',
              name: s['playerName'] ?? '',
              position: parsePosition(s['playerPosition']),
              teamName: 'Team',
              teamLogo: s['photoUrl'] ?? 'T',
              points: (s['avgPoints'] is num) ? (s['avgPoints'] as num).toDouble() : 0.0,
            ))
        .toList();
  }

  Timer? _localTimer;

  Future<void> connectAndJoin(String gameId, String userId) async {
    _gameId = gameId;
    final token = await TokenManager.getToken();

    // Fetch initial draft state and game participants
    await fetchDraftState();

    // Determine my participant ID
    if (_participants.isNotEmpty && userId.isNotEmpty) {
      final me = _participants.firstWhere(
        (p) => p['userId'] == userId,
        orElse: () => null,
      );
      if (me != null) {
        _myParticipantId = me['id'];
        notifyListeners();
      }
    }

    // Connect to Socket.IO namespace /game (with fallback support)
    try {
      final socketUri = '${ApiService.socketUrl}/game';
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('[Socket.IO] Connected to $socketUri');
        _socket?.emit('game:join-room', {'gameId': gameId});
        _socket?.emit('join:room', gameId);
      });

      _socket?.on('game:draft-start', (data) {
        debugPrint('[Socket.IO] draft-start: $data');
        _status = data['status'] ?? 'DRAFTING';
        _currentTurn = data['currentTurn'] ?? 1;
        _startLocalTimer(data['expiresAt']);
        fetchDraftState();
      });

      _socket?.on('game:draft-turn', (data) {
        debugPrint('[Socket.IO] draft-turn: $data');
        _currentTurn = data['turnNumber'] ?? _currentTurn;
        _activeTurn = Map<String, dynamic>.from(data as Map);
        _startLocalTimer(data['expiresAt']);

        // If it just became my turn, play alert sound
        if (data['participantId'] == _myParticipantId) {
          SoundService().playWhistle();
        }

        notifyListeners();
      });

      _socket?.on('game:player-selected', (data) {
        debugPrint('[Socket.IO] player-selected: $data');
        SoundService().playDraftPick();
        fetchDraftState();
      });

      _socket?.on('game:auto-pick', (data) {
        debugPrint('[Socket.IO] auto-pick: $data');
        SoundService().playDraftPick();
        fetchDraftState();
      });

      _socket?.on('game:draft-completed', (data) {
        debugPrint('[Socket.IO] draft-completed: $data');
        _status = data['status'] ?? 'LIVE';
        _localTimer?.cancel();
        SoundService().playWhistle();
        notifyListeners();
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('[Socket.IO Error] $e');
    }
  }

  void _startLocalTimer(String? expiresAtStr) {
    _localTimer?.cancel();
    if (expiresAtStr == null) return;

    try {
      final expiresAt = DateTime.parse(expiresAtStr).toLocal();
      final initialDiff = expiresAt.difference(DateTime.now()).inSeconds;
      _timerSeconds = initialDiff > 0 ? initialDiff : 0;
      notifyListeners();

      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final diff = expiresAt.difference(now).inSeconds;
        if (diff > 0) {
          _timerSeconds = diff;
          notifyListeners();
        } else {
          _timerSeconds = 0;
          timer.cancel();
          notifyListeners();
        }
      });
    } catch (_) {}
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
      if (data == null) return;

      _status = data['status'];
      _currentTurn = data['currentDraftTurn'] ?? 1;
      _turns = data['turns'] ?? [];
      _selections = data['selections'] ?? [];
      _participants = data['participants'] ?? [];

      final activeTurnData = data['activeTurn'];
      if (activeTurnData != null) {
        _activeTurn = Map<String, dynamic>.from(activeTurnData as Map);
        _startLocalTimer(activeTurnData['expiresAt']);
      }

      final rawPlayers = data['availablePlayers'] as List? ?? [];
      _availablePlayers = rawPlayers.map<md.FootballPlayer>((p) => md.FootballPlayer(
        id: p['id'].toString(),
        name: p['name'] ?? 'Player',
        position: parsePosition(p['position']),
        teamName: 'Team',
        teamLogo: p['photoUrl'] ?? 'T',
        points: (p['avgPoints'] is num) ? (p['avgPoints'] as num).toDouble() : 0.0,
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
      SoundService().playDraftPick();
      await _apiService.post('/games/$_gameId/draft/select', {
        'playerId': playerId,
        'turnNumber': _currentTurn.toString(),
      });

      _isLoading = false;
      await fetchDraftState();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
