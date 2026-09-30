import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/match_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart' as md;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().fetchUserProfile();
      context.read<MatchProvider>().fetchHomeMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final matchProvider = context.watch<MatchProvider>();

    final user = appState.currentUser;
    final liveMatches = matchProvider.liveMatches;
    final upcomingMatches = matchProvider.upcomingMatches;

    if (appState.isLoading || matchProvider.isLoading || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('UFL'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.goldAccent),
                const SizedBox(width: 4),
                Text(
                  '${user.coins}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      user.username.substring(0, 1),
                      style: const TextStyle(color: AppTheme.backgroundBlack, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
                      Text(user.username, style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ],
              ),
            ),
            
            // Live Now Section
            if (liveMatches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: AppTheme.errorRed, size: 12),
                    const SizedBox(width: 8),
                    Text('LIVE NOW', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.errorRed)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...liveMatches.map((m) => _buildMatchCard(context, m)).toList(),
              const SizedBox(height: 24),
            ],

            // Upcoming Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('UPCOMING MATCHES', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 8),
            ...upcomingMatches.map((m) => _buildMatchCard(context, m)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, md.Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: match.isLive ? Border.all(color: AppTheme.primaryGreen, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to match details
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.competition, style: Theme.of(context).textTheme.bodySmall),
                    if (match.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${match.liveMinute} LIVE',
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(match.matchTime, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeam(context, match.homeTeam, match.homeLogo),
                    if (match.isLive)
                      Text('${match.homeScore} - ${match.awayScore}', style: Theme.of(context).textTheme.displayMedium)
                    else
                      Text('VS', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.textMuted)),
                    _buildTeam(context, match.awayTeam, match.awayLogo),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('JOIN GAME - 500 COINS'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeam(BuildContext context, String name, String logo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.backgroundBlack,
          child: Text(logo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        ),
        const SizedBox(height: 8),
        Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
