import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart' as md;
import '../../core/theme/app_theme.dart';
import '../../core/providers/draft_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../live_game/live_game_screen.dart';

class DraftScreen extends StatefulWidget {
  final md.Match match;
  final String gameId;
  
  const DraftScreen({super.key, required this.match, required this.gameId});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  md.PlayerPosition _selectedTab = md.PlayerPosition.attack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppStateProvider>().currentUser?.id ?? '';
      context.read<DraftProvider>().connectAndJoin(widget.gameId, userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftProvider>();
    final userId = context.watch<AppStateProvider>().currentUser?.id;

    if (draft.isLoading && draft.status == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (draft.status == 'PENDING' || draft.status == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.watch<LocaleProvider>().translate('GAME ROOM'), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              Text(context.watch<LocaleProvider>().translate('Waiting for players...'), style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppTheme.primaryGreen),
            ],
          ),
        ),
      );
    }

    if (draft.status == 'LIVE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LiveGameScreen(match: widget.match, myTeam: draft.myTeam)),
        );
      });
      return const Scaffold(
        body: Center(child: Text('Navigating to Live Game...')),
      );
    }

    // Determine current active turn
    final activeTurn = draft.turns.firstWhere(
      (t) => t['turnNumber'] == draft.currentTurn,
      orElse: () => null,
    );
    
    // We assume we know our participant ID or we deduce it by matching userId (needs backend mapping, stubbed for now)
    bool isMyTurn = true; // In a full implementation, `activeTurn['participantId'] == myParticipantId`

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.watch<LocaleProvider>().translate('SNAKE DRAFT'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
            Text('${widget.match.homeTeam} vs ${widget.match.awayTeam}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Draft Status Area
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppTheme.surfaceCharcoal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserStatus(context, 'TEAM 1', true), // Simplified for MVP
                Column(
                  children: [
                    Text('${context.watch<LocaleProvider>().translate('TURN')} ${draft.currentTurn}', style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${draft.timerSeconds}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: draft.timerSeconds <= 10 ? AppTheme.errorRed : AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                _buildUserStatus(context, 'TEAM 2', false),
              ],
            ),
          ),
          
          // Position Tabs
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: md.PlayerPosition.values.map((pos) {
                final isSelected = _selectedTab == pos;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(pos.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedTab = pos;
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

          // Player List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: draft.availablePlayers
                  .where((p) => p.position == _selectedTab)
                  .map((player) => _buildPlayerCard(context, player, draft, isMyTurn))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUserStatus(BuildContext context, String name, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.transparent,
        border: Border.all(color: isActive ? AppTheme.primaryGreen : AppTheme.textMuted),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(context.read<LocaleProvider>().translate('Waiting...')),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, md.FootballPlayer player, DraftProvider draft, bool isMyTurn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCharcoal,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(player.teamLogo),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load player team logo: ${player.teamLogo}');
          },
        ),
        title: Text(player.name, style: const TextStyle(color: AppTheme.textWhite)),
        subtitle: Text(player.teamName),
        trailing: ElevatedButton(
          onPressed: isMyTurn ? () => draft.selectPlayer(player.id) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(80, 36),
          ),
          child: draft.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.read<LocaleProvider>().translate('SELECT')),
        ),
      ),
    );
  }
}
