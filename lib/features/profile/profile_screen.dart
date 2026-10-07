import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().fetchUserProfile();
      context.read<WalletProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final locale = context.watch<LocaleProvider>();
    final user = appState.currentUser;

    if (appState.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (user == null && !appState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.errorRed),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile.',
                style: GoogleFonts.inter(color: AppTheme.errorRed),
              ),
              ElevatedButton(
                onPressed: () => context.read<AppStateProvider>().fetchUserProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) return const SizedBox.shrink();

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
                locale.translate('PROFILE'),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textWhite,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language, color: AppTheme.primaryGreen),
                  onPressed: () {
                    context.read<LocaleProvider>().toggleLanguage();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: AppTheme.surfaceCharcoal,
        onRefresh: () async {
          await Future.wait([
            context.read<AppStateProvider>().fetchUserProfile(),
            context.read<WalletProvider>().fetchTransactions(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 100,
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    user.username.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.oswald(
                      fontSize: 56,
                      color: AppTheme.backgroundBlack,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user.username,
                style: GoogleFonts.oswald(
                  fontSize: 32,
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldAccent.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: AppTheme.goldAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${locale.translate('Global Rank')}: #${user.globalRank > 0 ? user.globalRank : 1}',
                      style: GoogleFonts.inter(
                        color: AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(context, locale.translate('GAMES'), '${user.totalGames}')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, locale.translate('WINS'), '${user.wins}')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, locale.translate('POINTS'), '${user.rankingPoints}')),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Coins Balance & Career Overview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surfaceCharcoal,
                      AppTheme.surfaceCharcoal.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, color: AppTheme.goldAccent, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              locale.translate('Current Balance'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${user.coins} ${locale.translate('COINS')}',
                          style: GoogleFonts.oswald(
                            color: AppTheme.goldAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.military_tech, color: AppTheme.primaryGreen, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              locale.translate('Total Coins Earned'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${user.totalCoinsEarned}',
                          style: GoogleFonts.oswald(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Coins Sources Breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.translate('COINS BREAKDOWN'),
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<WalletProvider>(
                      builder: (context, wallet, _) {
                        if (wallet.transactions.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCharcoal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                locale.translate('No transactions yet'),
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: wallet.transactions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final t = wallet.transactions[index];
                            final isPositive = t.amount > 0;
                            String title = locale.translate(t.type);
                            if (title == t.type) {
                              title = locale.translate(t.description);
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCharcoal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    isPositive ? '+${t.amount}' : '${t.amount}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 28,
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
