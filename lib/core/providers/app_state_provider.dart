import 'package:flutter/material.dart';
import '../models/models.dart';
import '../network/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/me');
      final data = response['data'];
      final wallet = data['wallet'] ?? {};
      final stats = data['stats'] ?? {};
      
      _currentUser = User(
        id: data['id']?.toString() ?? '',
        username: data['username'] ?? 'Player',
        avatarUrl: data['avatarUrl'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${data['username']}',
        coins: wallet['balance'] ?? data['coins'] ?? 0,
        globalRank: (stats['rankPosition'] != null && (stats['rankPosition'] as num) > 0)
            ? (stats['rankPosition'] as num).toInt()
            : ((data['globalRank'] != null && (data['globalRank'] as num) > 0)
                ? (data['globalRank'] as num).toInt()
                : 1),
        rankingPoints: stats['rankingPoints'] ?? data['rankingPoints'] ?? 1000,
        totalGames: stats['gamesPlayed'] ?? data['totalGames'] ?? 0,
        wins: stats['gamesWon'] ?? data['wins'] ?? 0,
        totalCoinsEarned: wallet['careerCoins'] ?? data['totalCoinsEarned'] ?? 0,
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AppStateProvider fetchUserProfile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Updates coins locally for immediate UI feedback using the backend's
  /// authoritative balance. Always prefer this over manual arithmetic.
  void updateCoinsOptimistically(int newBalance) {
    if (_currentUser == null) return;
    _currentUser = User(
      id: _currentUser!.id,
      username: _currentUser!.username,
      avatarUrl: _currentUser!.avatarUrl,
      coins: newBalance,
      globalRank: _currentUser!.globalRank,
      rankingPoints: _currentUser!.rankingPoints,
      totalGames: _currentUser!.totalGames,
      wins: _currentUser!.wins,
      totalCoinsEarned: _currentUser!.totalCoinsEarned,
    );
    notifyListeners();
  }
}
