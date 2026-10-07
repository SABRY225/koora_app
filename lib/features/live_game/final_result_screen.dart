import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/locale_provider.dart';
import '../main/main_screen.dart';

class FinalResultScreen extends StatelessWidget {
  final int myPoints;

  const FinalResultScreen({super.key, required this.myPoints});

  @override
  Widget build(BuildContext context) {
    // Determine winner based on mock points
    final isWinner = myPoints > 142; // We mock opponent 1 with 142 points
    final position = isWinner ? '1st' : '2nd';
    final coinsWon = isWinner ? 1000 : 500;
    final rankPoints = isWinner ? 3 : 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.watch<LocaleProvider>().translate('FULL TIME'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 32),
              
              Text(context.watch<LocaleProvider>().translate('FINAL RANKING'), style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 48),

              // Winner / Your result
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(24),
                  border: isWinner ? Border.all(color: AppTheme.goldAccent, width: 2) : null,
                  boxShadow: isWinner ? [
                    BoxShadow(color: AppTheme.goldAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                  ] : [],
                ),
                child: Column(
                  children: [
                    Text(
                      isWinner ? '🥇 1st PLACE' : '🥈 2nd PLACE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isWinner ? AppTheme.goldAccent : AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('$myPoints ${context.watch<LocaleProvider>().translate('POINTS')}', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(context.watch<LocaleProvider>().translate('+ COINS'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$coinsWon', style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(context.watch<LocaleProvider>().translate('+ RANKING'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$rankPoints', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back to home
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(context.watch<LocaleProvider>().translate('RETURN TO HOME'), style: const TextStyle(fontSize: 18)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
