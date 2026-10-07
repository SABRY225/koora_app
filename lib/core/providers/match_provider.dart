import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import '../models/models.dart';

class MatchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  List<Match> _liveMatches = [];
  List<Match> _upcomingMatches = [];
  List<Match> _allMatches = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Match> get liveMatches => _liveMatches;
  List<Match> get upcomingMatches => _upcomingMatches;
  List<Match> get allMatches => _allMatches;

  Future<void> fetchHomeMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all matches since the backend uses SCHEDULED/LIVE/FT etc.
      final allRes = await _apiService.get('/matches');
      final allData = (allRes['data'] as List?)?.map((m) => _parseMatch(m)).toList() ?? [];
      
      _allMatches = allData;
      _liveMatches = allData.where((m) => m.isLive).toList();
      _upcomingMatches = allData.where((m) => 
        m.status == 'SCHEDULED' || m.status == 'NS' || m.status == 'TBD'
      ).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MatchProvider error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Match _parseMatch(Map<String, dynamic> data) {
    final comp = data['competition'] ?? {};
    final home = data['homeTeam'] ?? {};
    final away = data['awayTeam'] ?? {};

    return Match(
      id: data['id']?.toString() ?? '',
      competitionId: data['competitionId']?.toString() ?? '',
      competition: comp['name'] ?? data['competitionName'] ?? 'Unknown',
      homeTeamId: data['homeTeamId']?.toString() ?? '',
      homeTeam: home['name'] ?? data['homeTeamName'] ?? 'Home',
      homeLogo: home['logoUrl'] ?? data['homeTeamLogo'] ?? 'https://via.placeholder.com/150',
      awayTeamId: data['awayTeamId']?.toString() ?? '',
      awayTeam: away['name'] ?? data['awayTeamName'] ?? 'Away',
      awayLogo: away['logoUrl'] ?? data['awayTeamLogo'] ?? 'https://via.placeholder.com/150',
      matchTime: data['startTime'] ?? data['fixtureDate'] ?? '',
      isLive: data['status'] == 'LIVE' || data['status'] == 'IN_PLAY' || data['status'] == '1H' || data['status'] == '2H',
      homeScore: data['homeScore'] ?? 0,
      awayScore: data['awayScore'] ?? 0,
      liveMinute: data['elapsed']?.toString() ?? '',
      status: data['status'] ?? 'SCHEDULED',
    );
  }
}

