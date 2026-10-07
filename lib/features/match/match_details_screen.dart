import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart' as md;
import '../../core/theme/app_theme.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../draft/draft_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  final md.Match match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LocaleProvider>().translate('MATCH DETAILS')),
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
                border: widget.match.isLive ? Border.all(color: AppTheme.primaryGreen, width: 2) : null,
              ),
              child: Column(
                children: [
                  Text(widget.match.competition, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeam(context, widget.match.homeTeam, widget.match.homeLogo),
                      if (widget.match.isLive)
                        Column(
                          children: [
                            Text('${widget.match.homeScore} - ${widget.match.awayScore}', style: Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${context.watch<LocaleProvider>().translate('LIVE')} ${widget.match.liveMinute}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text(context.watch<LocaleProvider>().translate('VS'), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(_formatMatchTime(widget.match.matchTime), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      _buildTeam(context, widget.match.awayTeam, widget.match.awayLogo),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Info text
            Text(context.watch<LocaleProvider>().translate('PLAYERS PER ROOM: 4'), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(context.watch<LocaleProvider>().translate('ENTRY FEE: 500 COINS'), style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.goldAccent)),
            const Spacer(),
            
            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isJoining ? null : () => _handleJoinGame(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _isJoining 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppTheme.surfaceObsidian, strokeWidth: 2))
                      : Text(context.watch<LocaleProvider>().translate('JOIN GAME'), style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatMatchTime(String rawTime) {
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return rawTime;
    }
  }

  Widget _buildTeam(BuildContext context, String name, String logo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(logo),
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _handleJoinGame(BuildContext context) async {
    final appState = context.read<AppStateProvider>();
    
    // Always refresh profile before checking balance to avoid stale data
    await appState.fetchUserProfile();
    
    if (appState.currentUser == null || appState.currentUser!.coins < 500) {
      _showOutOfCoinsDialog(context);
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final apiService = ApiService();
      
      // Check if we already joined a game for this fixture
      final gamesRes = await apiService.get('/games');
      final games = gamesRes['data'] as List;
      
      String? existingGameId;
      for (var g in games) {
        if (g['fixtureId'] == widget.match.id && g['hasJoined'] == true && g['status'] != 'CANCELLED' && g['status'] != 'FINISHED') {
          existingGameId = g['id'];
          break;
        }
      }
      
      String gameId;
      if (existingGameId != null) {
        gameId = existingGameId;
        // Don't deduct coins locally, we already paid
      } else {
        if (!context.mounted) return;
        // Confirmation modal before deducting coins and starting
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final loc = ctx.watch<LocaleProvider>();
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    loc.translate('CONFIRM_ENTRY'),
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Text(
                loc.translate('CONFIRM_ENTRY_DESC'),
                style: const TextStyle(color: AppTheme.textMuted, height: 1.5, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.translate('CANCEL'), style: const TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.backgroundBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.translate('CONFIRM & JOIN'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );

        if (confirmed != true) {
          setState(() {
            _isJoining = false;
          });
          return;
        }

        // 1. Create a Game Room for this fixture
        final createRes = await apiService.post('/games', {
          'fixtureId': widget.match.id,
          'entryFee': '500',
        });
        
        gameId = createRes['data']['id'];

        // 2. Join the Game Room
        final joinRes = await apiService.post('/games/$gameId/join', {});

        // Use the backend's authoritative remainingBalance for UI update
        final remainingBalance = joinRes['data']?['remainingBalance'];
        if (remainingBalance != null) {
          appState.updateCoinsOptimistically(remainingBalance);
        } else {
          // Fallback: re-fetch profile to get accurate balance
          await appState.fetchUserProfile();
        }
      }

      // Navigate to draft screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DraftScreen(match: widget.match, gameId: gameId)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.read<LocaleProvider>().translate('Failed to join game:')} $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showOutOfCoinsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final locale = ctx.watch<LocaleProvider>();
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCharcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(locale.translate('Out of Coins'), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 48, color: AppTheme.goldAccent),
            const SizedBox(height: 16),
            Text(
              locale.translate('Watch a short video and get 500 Coins to play your next game.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Text(locale.translate('500 COINS REWARD'), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.translate('Maybe Later'), style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate ad viewing
              Navigator.pop(ctx);
              _simulateAdAndReward(context);
            },
            child: Text(locale.translate('WATCH 30s AD')),
          ),
        ],
      );
      },
    );
  }

  void _simulateAdAndReward(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocaleProvider>().translate('Watching ad...')), duration: const Duration(seconds: 2)),
    );
    Future.delayed(const Duration(seconds: 2), () async {
      if (context.mounted) {
        try {
          await context.read<WalletProvider>().addRewardCoins(500);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.read<LocaleProvider>().translate('+500 Coins added! You can now join the game.')), backgroundColor: AppTheme.primaryGreenDark),
            );
          }
        } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.read<LocaleProvider>().translate('Failed to claim reward:')} $e'), backgroundColor: AppTheme.errorRed),
            );
          }
        }
      }
    });
  }
}

