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

  // Simulate ad reward and sync with backend (assuming a POST endpoint to add coins exists, 
  // if not, we can just hit /me again or simulate locally depending on backend support)
  // For now, we update local AppStateProvider.
  Future<void> addRewardCoins(int amount) async {
    // If backend has an endpoint like /wallet/add, we call it here.
    // For now we update AppStateProvider and maybe fake a transaction locally.
    _appStateProvider.addCoins(amount);
    _transactions.insert(
      0, 
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        description: 'Ad Reward', 
        amount: amount, 
        type: 'CREDIT', 
        createdAt: DateTime.now().toIso8601String()
      )
    );
    notifyListeners();
  }
}
