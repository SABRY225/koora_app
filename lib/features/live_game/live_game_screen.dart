import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/models/models.dart' as md;
import '../../core/theme/app_theme.dart';
import 'final_result_screen.dart';

class LiveGameScreen extends StatefulWidget {
  final md.Match match;
  final List<md.FootballPlayer> myTeam;

  const LiveGameScreen({super.key, required this.match, required this.myTeam});

  @override
  State<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends State<LiveGameScreen> {
  final List<md.LiveEvent> _events = [];
  Timer? _eventTimer;
  int _totalPoints = 0;

  final List<md.LiveEvent> _mockEvents = [
    md.LiveEvent(id: '1', title: 'PASS COMPLETED', playerName: 'Pedri', pointsDelta: 1, time: '67:45'),
    md.LiveEvent(id: '2', title: 'TACKLE', playerName: 'Antonio Rudiger', pointsDelta: 3, time: '68:12'),
    md.LiveEvent(id: '3', title: 'YELLOW CARD', playerName: 'Ronald Araujo', pointsDelta: -5, time: '69:04'),
    md.LiveEvent(id: '4', title: 'ASSIST', playerName: 'Jude Bellingham', pointsDelta: 20, time: '71:22'),
    md.LiveEvent(id: '5', title: 'GOAL', playerName: 'Vinicius Jr', pointsDelta: 40, time: '71:22'),
  ];
  int _eventIndex = 0;

  @override
  void initState() {
    super.initState();
    _totalPoints = widget.myTeam.fold(0, (sum, p) => sum + p.currentPoints);
    _startLiveFeed();
  }

  void _startLiveFeed() {
    _eventTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_eventIndex < _mockEvents.length) {
        setState(() {
          final event = _mockEvents[_eventIndex];
          _events.insert(0, event); // Add to top
          
          // If the event belongs to our player, update points
          if (widget.myTeam.any((p) => p.name == event.playerName)) {
            _totalPoints += event.pointsDelta;
          }
          
          _eventIndex++;
        });
      } else {
        _eventTimer?.cancel();
        // Simulate match end after all events
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => FinalResultScreen(myPoints: _totalPoints)),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('${widget.match.homeTeam} vs ${widget.match.awayTeam}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: AppTheme.errorRed, size: 10),
                const SizedBox(width: 4),
                Text('${widget.match.liveMinute} LIVE', style: const TextStyle(fontSize: 12, color: AppTheme.errorRed)),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Score Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: AppTheme.surfaceCharcoal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamLogo(widget.match.homeLogo),
                Text('${widget.match.homeScore} - ${widget.match.awayScore}', style: Theme.of(context).textTheme.displayLarge),
                _buildTeamLogo(widget.match.awayLogo),
              ],
            ),
          ),

          // Your Team & Points
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.myTeam.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(p.name, style: Theme.of(context).textTheme.bodyLarge),
                  )).toList(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TOTAL POINTS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
                    Text('$_totalPoints', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.primaryGreen)),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(color: AppTheme.surfaceCharcoal),
          
          // Live Event Feed Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.goldAccent),
                const SizedBox(width: 8),
                Text('LIVE FEED', style: Theme.of(context).textTheme.displaySmall),
              ],
            ),
          ),

          // Live Event Feed List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                final isNewest = index == 0;
                return _buildEventCard(event, isNewest);
              },
            ),
          ),
          
          // Live Ranking Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceCharcoal,
                foregroundColor: AppTheme.textWhite,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () => _showLiveRanking(context),
              child: const Text('VIEW LIVE RANKING', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String logo) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.backgroundBlack,
      child: Text(logo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textWhite)),
    );
  }

  Widget _buildEventCard(md.LiveEvent event, bool isNewest) {
    final isPositive = event.pointsDelta > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: isNewest ? Border.all(color: AppTheme.primaryGreen, width: 1) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(event.time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed)),
                  Text(event.playerName, style: const TextStyle(color: AppTheme.textWhite)),
                ],
              ),
            ],
          ),
          Text(
            isPositive ? '+${event.pointsDelta}' : '${event.pointsDelta}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isPositive ? AppTheme.primaryGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveRanking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LIVE RANKING', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 24),
              _buildRankingRow('1st', 'Opponent1', 142, false),
              _buildRankingRow('2nd', 'YOU', _totalPoints, true),
              _buildRankingRow('3rd', 'Opponent2', 89, false),
              _buildRankingRow('4th', 'Opponent3', 45, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingRow(String pos, String name, int points, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: AppTheme.primaryGreen) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(pos, style: TextStyle(fontWeight: FontWeight.bold, color: pos == '1st' ? AppTheme.goldAccent : AppTheme.textWhite)),
              const SizedBox(width: 16),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Text('$points PTS', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
