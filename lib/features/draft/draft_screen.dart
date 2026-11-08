import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart' as md;
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/draft_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../live_game/live_game_screen.dart';
import 'widgets/player_card_widget.dart';
import 'widgets/tactical_pitch_widget.dart';

class DraftScreen extends StatefulWidget {
  final md.Match match;
  final String gameId;

  const DraftScreen({super.key, required this.match, required this.gameId});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  md.PlayerPosition _selectedTab = md.PlayerPosition.attack;
  bool _showPitch = true;

  @override
  void initState() {
    super.initState();
    SoundService().playWhistle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppStateProvider>().currentUser?.id ?? '';
      context.read<DraftProvider>().connectAndJoin(widget.gameId, userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftProvider>();
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    if (draft.isLoading && draft.status == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (draft.status == 'PENDING' || draft.status == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceCharcoal,
                  border: Border.all(color: AppTheme.primaryGreen, width: 2),
                ),
                child: const Icon(Icons.sports_soccer, size: 56, color: AppTheme.primaryGreen),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1000.ms,
                  ),
              const SizedBox(height: 24),
              Text(
                locale.translate('GAME ROOM'),
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale.translate('Waiting for players...'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ),
      );
    }

    if (draft.status == 'LIVE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SoundService().playWhistle();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveGameScreen(match: widget.match, myTeam: draft.myTeam),
          ),
        );
      });
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    bool isMyTurn = true; // In live match: activeTurn['participantId'] == myParticipantId

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Column(
          children: [
            Text(
              locale.translate('SNAKE DRAFT'),
              style: GoogleFonts.oswald(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showPitch ? Icons.sports_soccer : Icons.grid_view_rounded,
              color: AppTheme.primaryGreen,
            ),
            tooltip: isArabic ? 'إظهار/إخفاء الملعب' : 'Toggle Pitch',
            onPressed: () {
              SoundService().playTap();
              setState(() {
                _showPitch = !_showPitch;
              });
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 1. Turn Status & Countdown Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: AppTheme.surfaceCharcoal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserStatus(context, isArabic ? 'فريقك' : 'YOUR SQUAD', true),
                Column(
                  children: [
                    Text(
                      '${locale.translate('TURN')} ${draft.currentTurn}',
                      style: GoogleFonts.oswald(
                        color: AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: draft.timerSeconds <= 10
                            ? AppTheme.errorRed.withValues(alpha: 0.2)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: draft.timerSeconds <= 10 ? AppTheme.errorRed : Colors.white24,
                        ),
                      ),
                      child: Text(
                        '${draft.timerSeconds}s',
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: draft.timerSeconds <= 10 ? AppTheme.errorRed : AppTheme.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildUserStatus(context, isArabic ? 'الخصم' : 'OPPONENT', false),
              ],
            ),
          ),

          // 2. Interactive Tactical Pitch Widget
          if (_showPitch)
            TacticalPitchWidget(
              teamPlayers: draft.myTeam,
              onPositionTap: (pos) {
                SoundService().playTap();
                setState(() {
                  _selectedTab = pos;
                });
              },
            ).animate().fadeIn(duration: 300.ms),

          // 3. Position Choice Tabs
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: md.PlayerPosition.values.map((pos) {
                final isSelected = _selectedTab == pos;
                String posLabel;
                switch (pos) {
                  case md.PlayerPosition.attack:
                    posLabel = isArabic ? 'الهجوم (FW)' : 'ATTACK (FW)';
                    break;
                  case md.PlayerPosition.midfield:
                    posLabel = isArabic ? 'الوسط (MF)' : 'MIDFIELD (MF)';
                    break;
                  case md.PlayerPosition.defense:
                    posLabel = isArabic ? 'الدفاع (DF)' : 'DEFENSE (DF)';
                    break;
                  case md.PlayerPosition.goalkeeper:
                    posLabel = isArabic ? 'الحراسة (GK)' : 'GOALKEEPER (GK)';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(posLabel),
                    selected: isSelected,
                    onSelected: (val) {
                      SoundService().playTap();
                      setState(() {
                        _selectedTab = pos;
                      });
                    },
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.surfaceCharcoal,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? AppTheme.backgroundBlack : AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 4. FUT Player Cards List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24.0),
              children: draft.availablePlayers
                  .where((p) => p.position == _selectedTab)
                  .map((player) {
                final alreadyPicked = draft.myTeam.any((p) => p.id == player.id);
                return PlayerCardWidget(
                  player: player,
                  isSelected: alreadyPicked,
                  onSelect: isMyTurn && !alreadyPicked
                      ? () {
                          draft.selectPlayer(player.id);
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatus(BuildContext context, String name, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(
          color: isActive ? AppTheme.primaryGreen : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isActive ? 'ACTIVE' : 'WAITING',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: isActive ? AppTheme.goldAccent : Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
