import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import 'player_stats_sheet.dart';

class TacticalPitchWidget extends StatelessWidget {
  final List<FootballPlayer> teamPlayers;
  final Function(PlayerPosition)? onPositionTap;

  const TacticalPitchWidget({
    super.key,
    required this.teamPlayers,
    this.onPositionTap,
  });

  FootballPlayer? _findPlayer(PlayerPosition pos) {
    try {
      return teamPlayers.firstWhere((p) => p.position == pos);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gk = _findPlayer(PlayerPosition.goalkeeper);
    final df = _findPlayer(PlayerPosition.defense);
    final mf = _findPlayer(PlayerPosition.midfield);
    final fw = _findPlayer(PlayerPosition.attack);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _PitchPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSlot(context, PlayerPosition.goalkeeper, gk, 'GK'),
                _buildSlot(context, PlayerPosition.defense, df, 'DF'),
                _buildSlot(context, PlayerPosition.midfield, mf, 'MF'),
                _buildSlot(context, PlayerPosition.attack, fw, 'FW'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(BuildContext context, PlayerPosition pos, FootballPlayer? player, String label) {
    final hasPlayer = player != null;

    return GestureDetector(
      onTap: () {
        if (hasPlayer) {
          PlayerStatsSheet.show(context, player);
        } else if (onPositionTap != null) {
          onPositionTap!(pos);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasPlayer ? AppTheme.surfaceCharcoal : Colors.black45,
              border: Border.all(
                color: hasPlayer ? AppTheme.primaryGreen : Colors.white24,
                width: hasPlayer ? 2.5 : 1.5,
              ),
              boxShadow: hasPlayer
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipOval(
              child: hasPlayer
                  ? (player.teamLogo.isNotEmpty
                      ? Image.network(
                          player.teamLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.primaryGreen),
                        )
                      : const Icon(Icons.person, color: AppTheme.primaryGreen))
                  : Center(
                      child: Text(
                        '+$label',
                        style: GoogleFonts.oswald(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasPlayer ? AppTheme.goldAccent : Colors.white12,
              ),
            ),
            child: Text(
              hasPlayer ? player.name : label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: hasPlayer ? AppTheme.textWhite : Colors.white54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasPlayer) ...[
            const SizedBox(height: 2),
            Text(
              '${player.points.toInt()} PTS',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: AppTheme.goldAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grass Stripes
    final grassDark = const Color(0xFF144D29);
    final grassLight = const Color(0xFF185A30);
    final stripeWidth = size.width / 6;

    for (int i = 0; i < 6; i++) {
      final paint = Paint()..color = (i % 2 == 0) ? grassDark : grassLight;
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }

    // 2. White Pitch Markings
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Pitch border
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), linePaint);

    // Halfway line
    canvas.drawLine(
      Offset(size.width / 2, 8),
      Offset(size.width / 2, size.height - 8),
      linePaint,
    );

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 36, linePaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, Paint()..color = Colors.white30);

    // Penalty box on the left (GK side)
    canvas.drawRect(Rect.fromLTWH(8, size.height * 0.25, 40, size.height * 0.5), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

