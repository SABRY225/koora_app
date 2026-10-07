import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import 'app_state_provider.dart';

class Transaction {
  final String id;
  final String description;
  final int amount;
  final String type;
  final String createdAt;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? 'Transaction',
      amount: json['amount'] ?? 0,
      type: json['type'] ?? 'CREDIT',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AppStateProvider _appStateProvider;

  bool _isLoading = false;
  String? _errorMessage;
  List<Transaction> _transactions = [];

  WalletProvider(this._appStateProvider);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Transaction> get transactions => _transactions;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/wallet/transactions');
      _transactions = (response['data'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRewardCoins(int amount) async {
    try {
      final response = await _apiService.post('/wallet/reward', {});
      // Use the backend's authoritative balance for immediate UI update
      final data = response['data'];
      if (data != null && data['balance'] != null) {
        _appStateProvider.updateCoinsOptimistically(data['balance']);
      }
      // Refresh transactions and user profile to fully sync with backend
      await fetchTransactions();
      await _appStateProvider.fetchUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
