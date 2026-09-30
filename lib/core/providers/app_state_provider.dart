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
      
      _currentUser = User(
        id: data['id']?.toString() ?? '',
        username: data['username'] ?? 'Player',
        avatarUrl: data['avatarUrl'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${data['username']}',
        coins: data['coins'] ?? 0,
        globalRank: data['globalRank'] ?? 0,
        rankingPoints: data['rankingPoints'] ?? 0,
        totalGames: data['totalGames'] ?? 0,
        wins: data['wins'] ?? 0,
        totalCoinsEarned: data['totalCoinsEarned'] ?? 0,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void addCoins(int amount) {
    if (_currentUser == null) return;
    _currentUser = User(
      id: _currentUser!.id,
      username: _currentUser!.username,
      avatarUrl: _currentUser!.avatarUrl,
      coins: _currentUser!.coins + amount,
      globalRank: _currentUser!.globalRank,
      rankingPoints: _currentUser!.rankingPoints,
      totalGames: _currentUser!.totalGames,
      wins: _currentUser!.wins,
      totalCoinsEarned: _currentUser!.totalCoinsEarned + amount,
    );
    notifyListeners();
  }

  bool deductCoins(int amount) {
    if (_currentUser == null) return false;
    if (_currentUser!.coins >= amount) {
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        avatarUrl: _currentUser!.avatarUrl,
        coins: _currentUser!.coins - amount,
        globalRank: _currentUser!.globalRank,
        rankingPoints: _currentUser!.rankingPoints,
        totalGames: _currentUser!.totalGames,
        wins: _currentUser!.wins,
        totalCoinsEarned: _currentUser!.totalCoinsEarned,
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}
