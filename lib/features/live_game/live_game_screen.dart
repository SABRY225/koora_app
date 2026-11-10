import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart' as md;
import '../../core/network/api_service.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/ranking_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../draft/widgets/tactical_pitch_widget.dart';
import 'final_result_screen.dart';

class LiveGameScreen extends StatefulWidget {
  final md.Match match;
  final List<md.FootballPlayer> myTeam;
  final String? gameId;

  const LiveGameScreen({
    super.key,
    required this.match,
    required this.myTeam,
    this.gameId,
  });

  @override
  State<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends State<LiveGameScreen> {
  final List<md.LiveEvent> _events = [];
  Timer? _eventTimer;
  int _totalPoints = 0;
  bool _isSettling = false;

  late final List<md.LiveEvent> _generatedEvents;
  int _eventIndex = 0;

  @override
  void initState() {
    super.initState();
    _totalPoints = widget.myTeam.fold(0, (sum, p) => sum + p.currentPoints);
    SoundService().playWhistle();
    _generateMatchEvents();
    _startLiveFeed();
  }

  void _generateMatchEvents() {
    // Generate dynamic match events based on the real players drafted by the user
    final players = widget.myTeam;
    final List<md.LiveEvent> events = [];

    if (players.isNotEmpty) {
      final p1 = players[0];
      final p2 = players.length > 1 ? players[1] : p1;

      // Event 1: Early buildup pass or tackle
      if (p1.position == md.PlayerPosition.defense || p1.position == md.PlayerPosition.goalkeeper) {
        events.add(md.LiveEvent(
          id: '1',
          title: 'CLEAN TACKLE',
          playerName: p1.name,
          pointsDelta: 10,
          time: '18:30',
        ));
      } else {
        events.add(md.LiveEvent(
          id: '1',
          title: 'KEY PASS',
          playerName: p1.name,
          pointsDelta: 8,
          time: '24:12',
        ));
      }

      // Event 2: Action from second player
      if (p2.position == md.PlayerPosition.attack) {
        events.add(md.LiveEvent(
          id: '2',
          title: 'SHOT ON TARGET',
          playerName: p2.name,
          pointsDelta: 12,
          time: '41:05',
        ));
      } else {
        events.add(md.LiveEvent(
          id: '2',
          title: 'INTERCEPTION',
          playerName: p2.name,
          pointsDelta: 8,
          time: '43:50',
        ));
      }

      // Event 3: Midfield play / Assist
      events.add(md.LiveEvent(
        id: '3',
        title: 'KEY ASSIST',
        playerName: p1.name,
        pointsDelta: 20,
        time: '65:10',
      ));

      // Event 4: Big Goal Moment
      events.add(md.LiveEvent(
        id: '4',
        title: 'GOOOAAAL!',
        playerName: (p2.position == md.PlayerPosition.attack ? p2.name : p1.name),
        pointsDelta: 40,
        time: '78:44',
      ));

      // Event 5: Late clean sheet / match impact bonus
      events.add(md.LiveEvent(
        id: '5',
        title: 'MATCH IMPACT BONUS',
        playerName: p2.name,
        pointsDelta: 15,
        time: '90+2\'',
      ));
    } else {
      // Fallback using match teams
      events.addAll([
        md.LiveEvent(id: '1', title: 'PASS COMPLETED', playerName: widget.match.homeTeam, pointsDelta: 5, time: '22:15'),
        md.LiveEvent(id: '2', title: 'TACKLE WON', playerName: widget.match.awayTeam, pointsDelta: 10, time: '45:00'),
        md.LiveEvent(id: '3', title: 'KEY ASSIST', playerName: widget.match.homeTeam, pointsDelta: 20, time: '68:10'),
        md.LiveEvent(id: '4', title: 'GOOOAAAL!', playerName: widget.match.homeTeam, pointsDelta: 40, time: '82:30'),
        md.LiveEvent(id: '5', title: 'FULL TIME WHISTLE', playerName: 'Match Official', pointsDelta: 10, time: '90:00'),
      ]);
    }

    _generatedEvents = events;
  }

  void _startLiveFeed() {
    _eventTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_eventIndex < _generatedEvents.length) {
        final event = _generatedEvents[_eventIndex];

        // Trigger realistic game sounds
        if (event.title.contains('GOAL') || event.title.contains('GOOOAAAL')) {
          SoundService().playGoal();
        } else if (event.pointsDelta > 0) {
          SoundService().playCoin();
        } else {
          SoundService().playTap();
        }

        setState(() {
          _events.insert(0, event);
          _totalPoints += event.pointsDelta;
          _eventIndex++;
        });
      } else {
        _eventTimer?.cancel();
        _finalizeAndSettleGame();
      }
    });
  }

  Future<void> _finalizeAndSettleGame() async {
    setState(() {
      _isSettling = true;
    });

    SoundService().playWhistle();

    Map<String, dynamic>? gameResultData;

    try {
      final apiService = ApiService();
      final gameId = widget.gameId;

      if (gameId != null && gameId.isNotEmpty) {
        // 1. Trigger backend settlement (awards RP, distributes Coins to wallet, calculates ranks)
        try {
          await apiService.post('/games/$gameId/settle', {});
        } catch (e) {
          debugPrint('Game settlement API call note: $e');
        }

        // 2. Fetch authoritative settlement results
        try {
          final res = await apiService.get('/games/$gameId/result');
          if (res['data'] != null) {
            gameResultData = res['data'] as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Get game result API call note: $e');
        }

        // 3. Immediately refresh user profile, wallet balance, and rankings in background
        if (mounted) {
          await Future.wait([
            context.read<AppStateProvider>().fetchUserProfile(),
            context.read<WalletProvider>().fetchTransactions(),
            context.read<RankingProvider>().fetchRanking(),
          ]);
        }
      }
    } catch (e) {
      debugPrint('Error finalizing game: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinalResultScreen(
            myPoints: _totalPoints,
            gameResult: gameResultData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    if (_isSettling) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'جاري احتساب النقاط وتوزيع الجوائز...' : 'CALCULATING POINTS & DISTRIBUTING REWARDS...',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'تحديث رصيد العملات ونقاط الـ RP' : 'Updating Coins & RP Rankings',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Column(
          children: [
            Text(
              '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: AppTheme.errorRed, size: 8),
                const SizedBox(width: 4),
                Text(
                  '${widget.match.liveMinute.isNotEmpty ? widget.match.liveMinute : '72\''} ${locale.translate('LIVE')}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 1. Live Stadium Score Board
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCharcoal,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamBadge(widget.match.homeTeam, widget.match.homeLogo),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundBlack,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${widget.match.homeScore} - ${widget.match.awayScore}',
                    style: GoogleFonts.oswald(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _buildTeamBadge(widget.match.awayTeam, widget.match.awayLogo),
              ],
            ),
          ),

          // 2. Tactical Pitch with User's Team
          TacticalPitchWidget(teamPlayers: widget.myTeam),

          // 3. Live Points Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCharcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: AppTheme.goldAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'نقاط فريقك المباشرة' : 'SQUAD LIVE POINTS',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_totalPoints PTS',
                  style: GoogleFonts.oswald(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Live Events Feed Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.feed_outlined, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  locale.translate('LIVE EVENT FEED'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 5. Live Events Feed List
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'بانتظار أحداث المباراة...' : 'Awaiting match events...',
                      style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final isPositive = event.pointsDelta > 0;
                      final isGoal = event.title.contains('GOAL') || event.title.contains('GOOOAAAL');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCharcoal,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isGoal
                                ? AppTheme.goldAccent
                                : (isPositive
                                    ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                    : AppTheme.errorRed.withValues(alpha: 0.3)),
                            width: isGoal ? 1.8 : 1,
                          ),
                          boxShadow: isGoal
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldAccent.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.time,
                                style: GoogleFonts.oswald(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: GoogleFonts.oswald(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isGoal ? AppTheme.goldAccent : AppTheme.textWhite,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    event.playerName,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                                    : AppTheme.errorRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPositive ? '+${event.pointsDelta} PTS' : '${event.pointsDelta} PTS',
                                style: GoogleFonts.oswald(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.2, end: 0, duration: 250.ms).fadeIn();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String teamName, String logoUrl) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black26,
            border: Border.all(color: Colors.white12),
          ),
          child: ClipOval(
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white70),
                  )
                : const Icon(Icons.sports_soccer, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            teamName,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
