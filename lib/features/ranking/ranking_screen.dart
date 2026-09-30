import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ranking_provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankingProvider>().fetchRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranking = context.watch<RankingProvider>();

    if (ranking.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('GLOBAL RANKING')),
      body: Column(
        children: [
          if (ranking.myRank != null)
            Container(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(ranking.myRank!.avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR RANK', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(ranking.myRank!.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('#${ranking.myRank!.globalRank}', style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 24)),
                      Text('${ranking.myRank!.rankingPoints.toInt()} PTS', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppTheme.surfaceCharcoal),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<RankingProvider>().fetchRanking(),
              child: ListView.builder(
                itemCount: ranking.leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = ranking.leaderboard[index];
                  final isTop3 = index < 3;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTop3 ? AppTheme.goldAccent.withOpacity(0.2) : AppTheme.surfaceCharcoal,
                      backgroundImage: NetworkImage(entry.avatarUrl),
                    ),
                    title: Text(entry.username, style: const TextStyle(color: AppTheme.textWhite)),
                    subtitle: Text('${entry.rankingPoints.toInt()} PTS'),
                    trailing: Text(
                      '#${entry.globalRank}',
                      style: TextStyle(
                        color: isTop3 ? AppTheme.goldAccent : AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: isTop3 ? 20 : 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
