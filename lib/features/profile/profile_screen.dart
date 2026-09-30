import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/auth_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final user = appState.currentUser;

    if (appState.isLoading || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppStateProvider>().fetchUserProfile();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  user.username.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 40,
                    color: AppTheme.backgroundBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.username,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldAccent),
                ),
                child: Text(
                  'Global Rank: #${user.globalRank}',
                  style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(context, 'GAMES', '${user.totalGames}'),
                    _buildStatCard(context, 'WINS', '${user.wins}'),
                    _buildStatCard(context, 'POINTS', '${user.rankingPoints}'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Coins Earned',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${user.totalCoinsEarned}',
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
