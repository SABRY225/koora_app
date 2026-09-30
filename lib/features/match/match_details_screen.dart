import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart' as md;
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/network/api_service.dart';
import '../draft/draft_screen.dart';

class MatchDetailsScreen extends StatelessWidget {
  final md.Match match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCH DETAILS'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Match Header
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCharcoal,
                borderRadius: BorderRadius.circular(16),
                border: match.isLive ? Border.all(color: AppTheme.primaryGreen, width: 2) : null,
              ),
              child: Column(
                children: [
                  Text(match.competition, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(context, match.homeTeam, match.homeLogo),
                      if (match.isLive)
                        Column(
                          children: [
                            Text('${match.homeScore} - ${match.awayScore}', style: Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('LIVE ${match.liveMinute}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text('VS', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(match.matchTime, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      _buildTeam(context, match.awayTeam, match.awayLogo),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Info text
            Text('AVAILABLE PLAYERS: 34', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('ENTRY FEE: 500 COINS', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.goldAccent)),
            const Spacer(),
            
            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleJoinGame(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('JOIN GAME', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTeam(BuildContext context, String name, String logo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.backgroundBlack,
          child: Text(logo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textWhite)),
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _handleJoinGame(BuildContext context) async {
    final appState = context.read<AppStateProvider>();
    if (appState.currentUser == null || appState.currentUser!.coins < 500) {
      _showOutOfCoinsDialog(context);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
    );

    try {
      final apiService = ApiService();
      // 1. Create a Game Room for this fixture
      final createRes = await apiService.post('/games', {
        'fixtureId': match.id,
        'entryFee': '500',
      });
      
      final gameId = createRes['data']['id'];

      // 2. Join the Game Room
      await apiService.post('/games/$gameId/join', {});

      // Success, deduct coins locally to reflect UI immediately
      appState.deductCoins(500);

      // Pop loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to draft screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DraftScreen(match: match, gameId: gameId)),
        );
      }
    } catch (e) {
      // Pop loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join game: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _showOutOfCoinsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Out of Coins', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 48, color: AppTheme.goldAccent),
            const SizedBox(height: 16),
            const Text(
              'Watch a short 30-second video and get 500 Coins to play your next game.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text('500 COINS REWARD', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate ad viewing
              Navigator.pop(ctx);
              _simulateAdAndReward(context);
            },
            child: const Text('WATCH 30s AD'),
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
        context.read<AppStateProvider>().addCoins(500);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+500 Coins added! You can now join the game.'), backgroundColor: AppTheme.primaryGreenDark),
        );
      }
    });
  }
}
