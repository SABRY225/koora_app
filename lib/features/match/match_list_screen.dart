import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart' as md;
import '../../core/theme/app_theme.dart';
import '../../core/providers/match_provider.dart';
import 'match_details_screen.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Premier League',
    'La Liga',
    'Saudi Pro League',
    'Champions League',
    'Egyptian Premier League'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().fetchHomeMatches(); // Ensure matches are loaded
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();

    if (matchProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    // Combine live and upcoming for the list
    List<md.Match> allMatches = [...matchProvider.liveMatches, ...matchProvider.upcomingMatches];
    
    if (_selectedFilter != 'All') {
      allMatches = allMatches.where((m) => m.competition.contains(_selectedFilter)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCHES'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.surfaceCharcoal,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.backgroundBlack : AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: allMatches.length,
        itemBuilder: (context, index) {
          final match = allMatches[index];
          return _buildMatchCard(context, match);
        },
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MatchDetailsScreen(match: match)),
            );
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MatchDetailsScreen(match: match)),
                      );
                    },
                    child: const Text('JOIN GAME - 500 COINS'),
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
