import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/locale_provider.dart';

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
      // Always refresh user profile to get accurate coin balance
      context.read<AppStateProvider>().fetchUserProfile();
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;
    final walletProvider = context.watch<WalletProvider>();
    final locale = context.watch<LocaleProvider>();

    if (user == null || walletProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.backgroundBlack.withOpacity(0.8),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                locale.translate('WALLET'),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textWhite,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      body: user.coins == 0 ? _buildZeroCoinsState(context) : _buildWalletDashboard(context, user.coins, walletProvider.transactions),
    );
  }

  Widget _buildWalletDashboard(BuildContext context, int coins, List<Transaction> transactions) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        left: 16,
        right: 16,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceCharcoal,
                  AppTheme.surfaceCharcoal.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldAccent.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.monetization_on, size: 64, color: AppTheme.goldAccent),
                const SizedBox(height: 16),
                Text(
                  '$coins',
                  style: GoogleFonts.oswald(
                    fontSize: 64,
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  context.watch<LocaleProvider>().translate('COINS'),
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
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
              icon: const Icon(Icons.play_circle_fill, color: AppTheme.goldAccent),
              label: Text(
                context.watch<LocaleProvider>().translate('WATCH AD FOR +500 COINS'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppTheme.textWhite,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.goldAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.goldAccent.withOpacity(0.05),
              ),
            ),
          ),

          const SizedBox(height: 48),
          
          // Transaction History
          Text(
            context.watch<LocaleProvider>().translate('TRANSACTION HISTORY'),
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(context.watch<LocaleProvider>().translate('No transactions yet'), style: const TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = transactions[index];
                return _buildTransaction(t.type, t.description, t.amount);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildZeroCoinsState(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        left: 24,
        right: 24,
        bottom: 100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 24),
          Text(
            context.watch<LocaleProvider>().translate("You're out of Coins"),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.watch<LocaleProvider>().translate('Watch a short video and get 500 Coins to play your next game.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent),
            ),
            child: Column(
              children: [
                Text(
                  context.watch<LocaleProvider>().translate('500 COINS'),
                  style: GoogleFonts.oswald(
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                Text(
                  context.watch<LocaleProvider>().translate('REWARD'),
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _simulateAdAndReward(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.backgroundBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.watch<LocaleProvider>().translate('WATCH 30s AD'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (walletProvider.transactions.isNotEmpty) ...[
            const SizedBox(height: 48),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.watch<LocaleProvider>().translate('TRANSACTION HISTORY'),
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: walletProvider.transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = walletProvider.transactions[index];
                return _buildTransaction(t.type, t.description, t.amount);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransaction(String type, String description, int amount) {
    final isPositive = amount > 0;
    
    // Attempt to translate the type, fallback to translated description, or just description
    final locale = context.read<LocaleProvider>();
    String title = locale.translate(type);
    if (title == type) {
      title = locale.translate(description);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
          ),
          Text(
            isPositive ? '+$amount' : '$amount',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateAdAndReward(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<LocaleProvider>().translate('Watching ad...'), style: GoogleFonts.inter()),
        backgroundColor: AppTheme.surfaceCharcoal,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () async {
      if (context.mounted) {
        await context.read<WalletProvider>().addRewardCoins(500);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                context.read<LocaleProvider>().translate('Reward Added!'),
                style: GoogleFonts.inter(
                  color: AppTheme.goldAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                context.read<LocaleProvider>().translate('+500 COINS\n\nYou are ready for your next game!'),
                style: GoogleFonts.inter(
                  color: AppTheme.textWhite,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    context.read<LocaleProvider>().translate('AWESOME'),
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    });
  }
}
