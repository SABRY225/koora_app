import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;
    final walletProvider = context.watch<WalletProvider>();

    if (user == null || walletProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('WALLET')),
      body: user.coins == 0 ? _buildZeroCoinsState(context) : _buildWalletDashboard(context, user.coins, walletProvider.transactions),
    );
  }

  Widget _buildWalletDashboard(BuildContext context, int coins, List<Transaction> transactions) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.surfaceCharcoal, AppTheme.backgroundBlack],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.monetization_on, size: 64, color: AppTheme.goldAccent),
                const SizedBox(height: 16),
                Text('$coins', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48, color: AppTheme.goldAccent)),
                Text('COINS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _simulateAdAndReward(context);
              },
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('WATCH AD FOR +500 COINS'),
            ),
          ),

          const SizedBox(height: 32),
          
          // Transaction History
          Text('TRANSACTION HISTORY', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions yet', style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return _buildTransaction(t.description, t.type == 'CREDIT' ? t.amount : -t.amount);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildZeroCoinsState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 24),
          Text("You're out of Coins", style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 16),
          Text(
            'Watch a short video and get 500 Coins to play your next game.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAccent),
            ),
            child: const Column(
              children: [
                Text('500 COINS', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 24)),
                Text('REWARD', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _simulateAdAndReward(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('WATCH 30s AD', style: TextStyle(fontSize: 18)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransaction(String title, int amount) {
    final isPositive = amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            isPositive ? '+$amount' : '$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateAdAndReward(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watching ad...'), duration: Duration(seconds: 2)),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.read<WalletProvider>().addRewardCoins(500);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceCharcoal,
            title: const Text('Reward Added!', style: TextStyle(color: AppTheme.goldAccent)),
            content: const Text('+500 COINS\n\nYou are ready for your next game!', style: TextStyle(color: AppTheme.textWhite)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('AWESOME'),
              ),
            ],
          ),
        );
      }
    });
  }
}
