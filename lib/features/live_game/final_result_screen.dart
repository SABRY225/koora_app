import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../main/main_screen.dart';

class FinalResultScreen extends StatefulWidget {
  final int myPoints;

  const FinalResultScreen({super.key, required this.myPoints});

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    final isWinner = widget.myPoints >= 100;

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
    final isWinner = widget.myPoints >= 100;
    final coinsWon = isWinner ? 1000 : 500;
    final rankPoints = isWinner ? 15 : 5;

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
                    isWinner
                        ? AppTheme.goldAccent.withValues(alpha: 0.2)
                        : Colors.blueAccent.withValues(alpha: 0.15),
                    AppTheme.backgroundBlack,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
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

                  const SizedBox(height: 16),

                  Text(
                    locale.translate('FINAL RANKING'),
                    style: GoogleFonts.oswald(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                      letterSpacing: 1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Champion / Runner-up Trophy Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isWinner ? AppTheme.goldAccent : Colors.white24,
                        width: isWinner ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isWinner ? AppTheme.goldAccent : Colors.white12)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Medal / Trophy Icon
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isWinner ? AppTheme.goldAccent : Colors.white10)
                                .withValues(alpha: 0.15),
                            border: Border.all(
                              color: isWinner ? AppTheme.goldAccent : Colors.white30,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isWinner ? Icons.emoji_events : Icons.military_tech,
                            size: 64,
                            color: isWinner ? AppTheme.goldAccent : Colors.white70,
                          ),
                        ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 18),

                        Text(
                          isWinner
                              ? (isArabic ? '🥇 المركز الأول - بطل المباراة!' : '🥇 1st PLACE CHAMPION')
                              : (isArabic ? '🥈 المركز الثاني - أداء رائع!' : '🥈 2nd PLACE RUNNER-UP'),
                          style: GoogleFonts.oswald(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isWinner ? AppTheme.goldAccent : AppTheme.textWhite,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '${widget.myPoints} ${isArabic ? 'نقطة إجمالية' : 'TOTAL POINTS'}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 28),

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
                            Container(width: 1, height: 44, color: Colors.white12),
                            _buildRewardBox(
                              title: isArabic ? '+ نقاط RP' : '+ RANKING RP',
                              amount: '+$rankPoints RP',
                              icon: Icons.trending_up,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms).scale(),

                  const Spacer(),

                  // Return Home Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SoundService().playTap();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home, size: 22),
                      label: Text(
                        locale.translate('RETURN TO HOME'),
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.backgroundBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
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
