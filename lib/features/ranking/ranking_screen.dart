import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

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
                'GLOBAL RANKING',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textWhite,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 60),
          if (ranking.myRank != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.2),
                    AppTheme.primaryGreen.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(ranking.myRank!.avatarUrl),
                      backgroundColor: AppTheme.surfaceCharcoal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR RANK',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ranking.myRank!.username,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '#${ranking.myRank!.globalRank}',
                        style: GoogleFonts.oswald(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          height: 1,
                        ),
                      ),
                      Text(
                        '${ranking.myRank!.rankingPoints.toInt()} PTS',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.surfaceCharcoal,
              onRefresh: () => context.read<RankingProvider>().fetchRanking(),
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                itemCount: ranking.leaderboard.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = ranking.leaderboard[index];
                  final isTop3 = index < 3;
                  
                  Color rankColor = AppTheme.textMuted;
                  if (index == 0) rankColor = const Color(0xFFFFD700); // Gold
                  else if (index == 1) rankColor = const Color(0xFFC0C0C0); // Silver
                  else if (index == 2) rankColor = const Color(0xFFCD7F32); // Bronze

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(12),
                      border: isTop3 ? Border.all(color: rankColor.withOpacity(0.5)) : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${entry.globalRank}',
                              style: GoogleFonts.oswald(
                                color: isTop3 ? rankColor : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: isTop3 ? 24 : 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.backgroundBlack,
                            backgroundImage: NetworkImage(entry.avatarUrl),
                          ),
                        ],
                      ),
                      title: Text(
                        entry.username,
                        style: GoogleFonts.inter(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Text(
                        '${entry.rankingPoints.toInt()} PTS',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
