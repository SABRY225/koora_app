import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/ranking_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../main/main_screen.dart';
import '../profile/widgets/avatar_selector_sheet.dart';

class FinalResultScreen extends StatefulWidget {
  final int myPoints;
  final Map<String, dynamic>? gameResult;

  const FinalResultScreen({
    super.key,
    required this.myPoints,
    this.gameResult,
  });

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    final currentUserResult = widget.gameResult?['currentUserResult'] as Map<String, dynamic>?;
    final int rank = currentUserResult?['rank'] ?? (widget.myPoints >= 100 ? 1 : 2);
    final isWinner = rank == 1 || rank == 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isWinner) {
        SoundService().playWin();
        _confettiController.play();
      } else {
        SoundService().playWhistle();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    final currentUserResult = widget.gameResult?['currentUserResult'] as Map<String, dynamic>?;
    final int rank = currentUserResult?['rank'] ?? (widget.myPoints >= 100 ? 1 : 2);
    final int coinsWon = currentUserResult?['coinReward'] ?? (rank == 1 ? 1000 : rank == 2 ? 500 : 0);
    final int rpChange = currentUserResult?['rpChange'] ?? (rank == 1 ? 3 : rank == 2 ? 1 : rank == 3 ? 0 : -1);
    final int finalPoints = currentUserResult?['totalPoints'] ?? widget.myPoints;
    final bool isWinner = rank == 1 || rank == 2;

    final List<dynamic> participantsResults = (widget.gameResult?['results'] as List<dynamic>?) ?? [];

    Color accentColor = AppTheme.primaryGreen;
    if (rank == 1) {
      accentColor = AppTheme.goldAccent;
    } else if (rank == 2) {
      accentColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      accentColor = const Color(0xFFCD7F32);
    } else {
      accentColor = AppTheme.textMuted;
    }

    String rankTitle;
    if (rank == 1) {
      rankTitle = isArabic ? '🥇 المركز الأول - بطل المباراة!' : '🥇 1st PLACE CHAMPION';
    } else if (rank == 2) {
      rankTitle = isArabic ? '🥈 المركز الثاني - وصيف رائع!' : '🥈 2nd PLACE RUNNER-UP';
    } else if (rank == 3) {
      rankTitle = isArabic ? '🥉 المركز الثالث - أداء جيد!' : '🥉 3rd PLACE';
    } else {
      rankTitle = isArabic ? '⚽ المركز الرابع - حظاً أفضل!' : '4th PLACE';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // Background stadium ambient glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    AppTheme.backgroundBlack,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Full Time Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_soccer, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          locale.translate('FULL TIME'),
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    locale.translate('FINAL RANKING'),
                    style: GoogleFonts.oswald(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                      letterSpacing: 1,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 16),

                  // Main Result Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.8),
                        width: isWinner ? 2.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Trophy / Medal Icon
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            rank == 1
                                ? Icons.emoji_events
                                : rank == 2
                                    ? Icons.military_tech
                                    : Icons.sports_score,
                            size: 52,
                            color: accentColor,
                          ),
                        ).animate().scale(delay: 200.ms, duration: 450.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 14),

                        Text(
                          rankTitle,
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '$finalPoints ${isArabic ? 'نقطة فانتسي' : 'FANTASY POINTS'}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Reward Pills Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRewardBox(
                              title: locale.translate('+ COINS'),
                              amount: '+$coinsWon',
                              icon: Icons.monetization_on,
                              color: AppTheme.goldAccent,
                            ),
                            Container(width: 1, height: 40, color: Colors.white12),
                            _buildRewardBox(
                              title: isArabic ? 'نقاط RP' : 'RANKING RP',
                              amount: '${rpChange >= 0 ? '+$rpChange' : '$rpChange'} RP',
                              icon: rpChange >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: rpChange >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms).scale(),

                  const SizedBox(height: 16),

                  // 4-Player Match Standings Table
                  if (participantsResults.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isArabic ? 'ترتيب مدربي الغرفة' : 'ROOM MANAGERS STANDINGS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: participantsResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final p = participantsResults[index] as Map<String, dynamic>;
                          final int pRank = p['rank'] ?? (index + 1);
                          final String pUsername = p['username'] ?? 'Player';
                          final String? pAvatar = p['avatarUrl'];
                          final int pPoints = p['totalPoints'] ?? 0;
                          final int pCoins = p['coinReward'] ?? 0;
                          final bool isMe = currentUserResult != null && p['userId'] == currentUserResult['userId'];

                          Color pColor = AppTheme.textMuted;
                          if (pRank == 1) pColor = AppTheme.goldAccent;
                          else if (pRank == 2) pColor = const Color(0xFFC0C0C0);
                          else if (pRank == 3) pColor = const Color(0xFFCD7F32);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                  : AppTheme.surfaceCharcoal,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMe ? AppTheme.primaryGreen : Colors.white10,
                                width: isMe ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '#$pRank',
                                    style: GoogleFonts.oswald(
                                      color: pColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                UserAvatarView(
                                  avatarUrl: pAvatar,
                                  username: pUsername,
                                  radius: 14,
                                  showGlow: false,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isMe ? '$pUsername (${isArabic ? 'أنت' : 'YOU'})' : pUsername,
                                    style: GoogleFonts.inter(
                                      color: isMe ? AppTheme.primaryGreen : AppTheme.textWhite,
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$pPoints pts',
                                      style: GoogleFonts.oswald(
                                        color: AppTheme.textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (pCoins > 0)
                                      Text(
                                        '+$pCoins coins',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.goldAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    const Spacer(),

                  const SizedBox(height: 12),

                  // Return Home & Sync Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        SoundService().playTap();
                        // Refetch profile, wallet transactions, and ranking to keep entire app perfectly in sync
                        await Future.wait([
                          context.read<AppStateProvider>().fetchUserProfile(),
                          context.read<WalletProvider>().fetchTransactions(),
                          context.read<RankingProvider>().fetchRanking(),
                        ]);

                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.home, size: 20),
                      label: Text(
                        locale.translate('RETURN TO HOME'),
                        style: GoogleFonts.oswald(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.backgroundBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // down
              maxBlastForce: 6,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [
                AppTheme.goldAccent,
                AppTheme.primaryGreen,
                Colors.white,
                Colors.orangeAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBox({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.oswald(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}
