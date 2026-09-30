import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import '../models/models.dart';

class MatchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  List<Match> _liveMatches = [];
  List<Match> _upcomingMatches = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Match> get liveMatches => _liveMatches;
  List<Match> get upcomingMatches => _upcomingMatches;

  Future<void> fetchHomeMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final liveRes = await _apiService.get('/matches?status=LIVE');
      final upcomingRes = await _apiService.get('/matches?status=UPCOMING'); // Assuming UPCOMING is valid

      _liveMatches = (liveRes['data'] as List).map((m) => _parseMatch(m)).toList();
      _upcomingMatches = (upcomingRes['data'] as List).map((m) => _parseMatch(m)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Match _parseMatch(Map<String, dynamic> data) {
    return Match(
      id: data['id']?.toString() ?? '',
      competitionId: data['competitionId']?.toString() ?? '',
      competition: data['competitionName'] ?? 'Unknown',
      homeTeamId: data['homeTeamId']?.toString() ?? '',
      homeTeam: data['homeTeamName'] ?? 'Home',
      homeLogo: data['homeTeamLogo'] ?? 'H',
      awayTeamId: data['awayTeamId']?.toString() ?? '',
      awayTeam: data['awayTeamName'] ?? 'Away',
      awayLogo: data['awayTeamLogo'] ?? 'A',
      matchTime: data['fixtureDate'] ?? '',
      isLive: data['status'] == 'LIVE' || data['status'] == 'IN_PLAY',
      homeScore: data['homeScore'] ?? 0,
      awayScore: data['awayScore'] ?? 0,
      liveMinute: data['elapsed']?.toString() ?? '',
      status: data['status'] ?? 'UPCOMING',
    );
  }
}
