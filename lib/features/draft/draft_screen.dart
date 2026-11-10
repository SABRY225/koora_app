import 'dart:async';
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
import '../match/game_lobby_screen.dart';
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
  Timer? _waitingPollingTimer;
  bool _hasNavigatedToLive = false;

  @override
  void initState() {
    super.initState();
    SoundService().playWhistle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppStateProvider>().currentUser?.id ?? '';
      final draft = context.read<DraftProvider>();
      draft.connectAndJoin(widget.gameId, userId);

      // Setup periodic poll if room is in WAITING state
      _waitingPollingTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final status = draft.status;
        if (status == 'WAITING' || status == 'PENDING' || status == null) {
          draft.fetchDraftState();
        } else if (status == 'DRAFTING' || status == 'LIVE') {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _waitingPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftProvider>();
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    // 1. Initial Loading Spinner
    if (draft.isLoading && draft.status == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    // 2. Waiting Room State (Route to Challengers Lobby if waiting for players)
    if (draft.status == 'WAITING' && draft.participants.length < 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameLobbyScreen(match: widget.match, gameId: widget.gameId),
          ),
        );
      });
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    // 3. Live Match Transition
    if (draft.status == 'LIVE') {
      if (!_hasNavigatedToLive) {
        _hasNavigatedToLive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SoundService().playWhistle();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveGameScreen(
                match: widget.match,
                myTeam: draft.myTeam,
                gameId: draft.gameId ?? widget.gameId,
              ),
            ),
          );
        });
      }
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    final isMyTurn = draft.isMyTurn;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppTheme.goldAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  isArabic ? 'سنيك درافت' : 'SNAKE DRAFT',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            Text(
              '${widget.match.homeTeam} VS ${widget.match.awayTeam}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showPitch ? Icons.view_agenda_outlined : Icons.stadium_outlined,
              color: AppTheme.primaryGreen,
            ),
            tooltip: isArabic ? 'الملعب التكتيكي' : 'Tactical Pitch',
            onPressed: () {
              SoundService().playTap();
              setState(() {
                _showPitch = !_showPitch;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 4-Player Managers Carousel
          _buildParticipantsBar(context, draft, isArabic),

          // 2. Active Turn & Countdown Banner
          _buildTurnBanner(context, draft, isArabic, isMyTurn),

          // 3. Interactive Tactical Pitch Widget
          if (_showPitch)
            TacticalPitchWidget(
              teamPlayers: draft.myTeam,
              onPositionTap: (pos) {
                SoundService().playTap();
                setState(() {
                  _selectedTab = pos;
                });
              },
            ).animate().fadeIn(duration: 250.ms),

          // 4. Position Choice Tabs with Player Counts
          _buildPositionTabs(context, draft, isArabic),

          // 5. FUT Player Cards List
          Expanded(
            child: _buildPlayerCardsList(context, draft, isArabic, isMyTurn),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsBar(BuildContext context, DraftProvider draft, bool isArabic) {
    final participants = draft.participants;
    if (participants.isEmpty) return const SizedBox.shrink();

    final activeParticipantId = draft.activeTurn?['participantId'];

    return Container(
      color: AppTheme.surfaceCharcoal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: participants.map((p) {
          final isTurn = p['id'] == activeParticipantId;
          final isMe = p['id'] == draft.myParticipantId;
          final selectionsCount = draft.selections.where((s) => s['participantId'] == p['id']).length;
          final rawUsername = p['username']?.toString() ?? 'Player';
          final username = isMe ? (isArabic ? '$rawUsername (أنت)' : '$rawUsername (You)') : rawUsername;
          final avatarUrl = p['avatarUrl']?.toString() ?? '';

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isTurn ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.surfaceObsidian,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTurn ? AppTheme.primaryGreen : Colors.white12,
                  width: isTurn ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isTurn ? AppTheme.primaryGreen : Colors.white24,
                        backgroundImage: avatarUrl.startsWith('http')
                            ? NetworkImage(avatarUrl)
                            : (avatarUrl.isNotEmpty ? AssetImage(avatarUrl) : null) as ImageProvider?,
                        child: avatarUrl.isEmpty
                            ? Text(
                                username.isNotEmpty ? username[0].toUpperCase() : 'P',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      if (selectionsCount > 0)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.goldAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$selectionsCount',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isTurn ? FontWeight.bold : FontWeight.w500,
                      color: isTurn ? AppTheme.primaryGreen : AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    isTurn ? (isArabic ? 'يختار الآن' : 'PICKING') : (isArabic ? 'انتظار' : 'WAITING'),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isTurn ? AppTheme.goldAccent : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTurnBanner(BuildContext context, DraftProvider draft, bool isArabic, bool isMyTurn) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
            : AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyTurn ? AppTheme.primaryGreen : Colors.white12,
          width: isMyTurn ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isMyTurn ? Icons.touch_app : Icons.hourglass_top_rounded,
                color: isMyTurn ? AppTheme.primaryGreen : AppTheme.goldAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyTurn
                        ? (isArabic ? '🔥 دورك الآن! اختر لاعباً' : '🔥 YOUR TURN! PICK A PLAYER')
                        : (isArabic ? '⏳ دور: ${draft.activePlayerName}' : '⏳ Turn: ${draft.activePlayerName}'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isMyTurn ? AppTheme.primaryGreen : AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    '${isArabic ? 'الجولة' : 'ROUND'} ${draft.currentTurn <= 4 ? 1 : 2} • ${isArabic ? 'الدور' : 'TURN'} ${draft.currentTurn}/8',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: draft.timerSeconds <= 5
                  ? AppTheme.errorRed.withValues(alpha: 0.3)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: draft.timerSeconds <= 5 ? AppTheme.errorRed : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: draft.timerSeconds <= 5 ? AppTheme.errorRed : AppTheme.textWhite,
                ),
                const SizedBox(width: 4),
                Text(
                  '${draft.timerSeconds}s',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: draft.timerSeconds <= 5 ? AppTheme.errorRed : AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionTabs(BuildContext context, DraftProvider draft, bool isArabic) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: md.PlayerPosition.values.map((pos) {
          final isSelected = _selectedTab == pos;
          final count = draft.availablePlayers.where((p) => p.position == pos).length;

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
              label: Text('$posLabel ($count)'),
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
    );
  }

  Widget _buildPlayerCardsList(BuildContext context, DraftProvider draft, bool isArabic, bool isMyTurn) {
    final filteredPlayers = draft.availablePlayers.where((p) => p.position == _selectedTab).toList();

    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'لا يوجد لاعبين متاحين في هذا المركز' : 'No available players in this position',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24.0),
      itemCount: filteredPlayers.length,
      itemBuilder: (ctx, index) {
        final player = filteredPlayers[index];
        final alreadyPicked = draft.myTeam.any((p) => p.id == player.id);

        return PlayerCardWidget(
          player: player,
          isSelected: alreadyPicked,
          onSelect: isMyTurn && !alreadyPicked
              ? () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await draft.selectPlayer(player.id);
                  if (ok && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تم اختيار ${player.name} بنجاح!' : 'Selected ${player.name} successfully!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              : () {
                  if (!isMyTurn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'انتظر دورك في الاختيار (دور: ${draft.activePlayerName})'
                              : 'Wait for your turn (Current: ${draft.activePlayerName})',
                        ),
                        backgroundColor: AppTheme.surfaceCharcoal,
                        duration: const Duration(milliseconds: 1200),
                      ),
                    );
                  }
                },
        );
      },
    );
  }
}
