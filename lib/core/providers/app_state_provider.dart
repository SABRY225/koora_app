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
        coins: (wallet['balance'] as num?)?.toInt() ?? (data['coins'] as num?)?.toInt() ?? 0,
        role: data['role']?.toString() ?? 'user',
        globalRank: ((stats['rankPosition'] as num?)?.toInt() != null && (stats['rankPosition'] as num).toInt() > 0)
            ? (stats['rankPosition'] as num).toInt()
            : (((data['globalRank'] as num?)?.toInt() != null && (data['globalRank'] as num).toInt() > 0)
                ? (data['globalRank'] as num).toInt()
                : 1),
        rankingPoints: (stats['rankingPoints'] as num?)?.toInt() ?? (data['rankingPoints'] as num?)?.toInt() ?? 1000,
        totalGames: (stats['gamesPlayed'] as num?)?.toInt() ?? (data['totalGames'] as num?)?.toInt() ?? 0,
        wins: (stats['gamesWon'] as num?)?.toInt() ?? (data['wins'] as num?)?.toInt() ?? 0,
        totalCoinsEarned: (wallet['careerCoins'] as num?)?.toInt() ?? (data['totalCoinsEarned'] as num?)?.toInt() ?? 0,
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
      role: _currentUser!.role,
    );
    notifyListeners();
  }

  Future<bool> updateUserAvatar(String newAvatarUrl) async {
    if (_currentUser == null) return false;
    final oldAvatar = _currentUser!.avatarUrl;
    _currentUser = _currentUser!.copyWith(avatarUrl: newAvatarUrl);
    notifyListeners();

    try {
      await _apiService.put('/me/avatar', {
        'avatarUrl': newAvatarUrl,
      });
      return true;
    } catch (e) {
      debugPrint('updateUserAvatar error: $e');
      _currentUser = _currentUser!.copyWith(avatarUrl: oldAvatar);
      notifyListeners();
      return false;
    }
  }
}
