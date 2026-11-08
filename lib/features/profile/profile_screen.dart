import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../ranking/ranking_screen.dart';
import 'widgets/avatar_selector_sheet.dart';

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
    final isArabic = locale.locale.languageCode == 'ar';
    final user = appState.currentUser ??
        User(
          id: '',
          username: 'Player',
          avatarUrl: 'assets/avatars/avatar_1.png',
          coins: 500,
          globalRank: 1,
          rankingPoints: 1000,
          totalGames: 0,
          wins: 0,
          totalCoinsEarned: 500,
        );
    final sound = SoundService();

    if (appState.isLoading && appState.currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (appState.errorMessage != null && user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.errorRed),
              onPressed: () async {
                sound.playTap();
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
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  sound.playTap();
                  context.read<AppStateProvider>().fetchUserProfile();
                },
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
              backgroundColor: AppTheme.backgroundBlack.withValues(alpha: 0.8),
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
                // Sound toggle button
                IconButton(
                  icon: Icon(
                    sound.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: sound.isMuted ? AppTheme.textMuted : AppTheme.primaryGreen,
                  ),
                  tooltip: isArabic ? 'كتم/تشغيل الصوت' : 'Mute/Unmute Audio',
                  onPressed: () {
                    sound.playTap();
                    sound.toggleMute();
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.language, color: AppTheme.primaryGreen),
                  onPressed: () {
                    sound.playTap();
                    context.read<LocaleProvider>().toggleLanguage();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                  onPressed: () async {
                    sound.playTap();
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
            top: MediaQuery.of(context).padding.top + 70,
            bottom: 100,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 1. Interactive Avatar with Edit Button
              UserAvatarView(
                avatarUrl: user.avatarUrl,
                username: user.username,
                radius: 54,
                showEditBadge: true,
                onEdit: () => AvatarSelectorSheet.show(context),
              ).animate().fadeIn(duration: 400.ms).scale(),

              const SizedBox(height: 16),

              // Username
              Text(
                user.username,
                style: GoogleFonts.oswald(
                  fontSize: 32,
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 10),

              // Global Rank Badge (Clickable)
              InkWell(
                onTap: () {
                  sound.playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RankingScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldAccent.withValues(alpha: 0.2),
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
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, color: AppTheme.goldAccent, size: 12),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // 2. 4-Stat Game Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(context, locale.translate('GAMES'), '${user.totalGames}')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(context, locale.translate('WINS'), '${user.wins}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'RP',
                        '${user.rankingPoints}',
                        onTap: () {
                          sound.playTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RankingScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(context, isArabic ? 'الفوز' : 'WIN %', '${user.winRate}%', highlightColor: AppTheme.primaryGreen)),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // 4. Badges & Achievements Section
              _buildAchievementsSection(user, isArabic).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 28),

              // 5. Coins Balance & Career Overview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surfaceCharcoal,
                      AppTheme.surfaceCharcoal.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
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
                              locale.translate('BALANCE'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${user.coins}',
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
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 28),

              // 6. Coins Breakdown
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
                    const SizedBox(height: 14),
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

  Widget _buildAchievementsSection(User user, bool isArabic) {
    final achievements = [
      {
        'title': isArabic ? 'أول انتصار' : 'First Blood',
        'desc': isArabic ? 'الفوز في أول مباراة' : 'Win 1 match',
        'icon': Icons.emoji_events,
        'unlocked': user.wins >= 1,
        'color': AppTheme.goldAccent,
      },
      {
        'title': isArabic ? 'محارب مخضرم' : 'Veteran',
        'desc': isArabic ? 'خوض 5 مباريات' : 'Play 5 matches',
        'icon': Icons.shield,
        'unlocked': user.totalGames >= 5,
        'color': Colors.blueAccent,
      },
      {
        'title': isArabic ? 'جامع العملات' : 'Coin Tycoon',
        'desc': isArabic ? 'جمع 2000 كوينز' : 'Earn 2,000 coins',
        'icon': Icons.monetization_on,
        'unlocked': user.totalCoinsEarned >= 2000,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': isArabic ? 'نجم الترتيب' : 'Rank Master',
        'desc': isArabic ? 'تجاوز 1200 نقطة RP' : 'Reach 1,200 RP',
        'icon': Icons.star,
        'unlocked': user.rankingPoints >= 1200,
        'color': Colors.purpleAccent,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: AppTheme.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الإنجازات والأوسمة' : 'ACHIEVEMENTS & BADGES',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final a = achievements[index];
              final unlocked = a['unlocked'] as bool;
              final color = a['color'] as Color;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked ? color.withValues(alpha: 0.6) : Colors.white10,
                    width: unlocked ? 1.5 : 1,
                  ),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: unlocked ? color.withValues(alpha: 0.15) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        size: 20,
                        color: unlocked ? color : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: unlocked ? AppTheme.textWhite : Colors.white38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a['desc'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: unlocked ? AppTheme.textMuted : Colors.white24,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
    Color? highlightColor,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: onTap != null
            ? Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 24,
              color: highlightColor ?? (onTap != null ? AppTheme.goldAccent : AppTheme.textWhite),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: onTap != null ? AppTheme.goldAccent : AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.goldAccent, size: 9),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }
}
