import 'package:flutter/foundation.dart';
import '../network/api_service.dart';

class RankEntry {
  final String userId;
  final String username;
  final String avatarUrl;
  final double rankingPoints;
  final int globalRank;

  RankEntry({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.rankingPoints,
    required this.globalRank,
  });

  factory RankEntry.fromJson(Map<String, dynamic> json) {
    return RankEntry(
      userId: json['userId']?.toString() ?? '',
      username: json['username'] ?? 'Player',
      avatarUrl: json['avatarUrl'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${json['username']}',
      rankingPoints: json['rankingPoints']?.toDouble() ?? 0.0,
      globalRank: json['globalRank'] ?? 0,
    );
  }
}

class RankingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  List<RankEntry> _leaderboard = [];
  RankEntry? _myRank;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RankEntry> get leaderboard => _leaderboard;
  RankEntry? get myRank => _myRank;

  Future<void> fetchRanking() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final leaderboardRes = await _apiService.get('/ranking');
      final myRankRes = await _apiService.get('/ranking/me');

      _leaderboard = (leaderboardRes['data'] as List).map((e) => RankEntry.fromJson(e)).toList();
      _myRank = RankEntry.fromJson(myRankRes['data']);
      
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
