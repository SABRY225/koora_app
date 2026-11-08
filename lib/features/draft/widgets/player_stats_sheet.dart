import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class PlayerStatsSheet extends StatelessWidget {
  final FootballPlayer player;

  const PlayerStatsSheet({super.key, required this.player});

  static void show(BuildContext context, FootballPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PlayerStatsSheet(player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: ClipOval(
                  child: player.teamLogo.isNotEmpty
                      ? Image.network(
                          player.teamLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 28),
                        )
                      : const Icon(Icons.sports_soccer, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.oswald(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      '${player.teamName} • ${player.position.name.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldAccent),
                ),
                child: Text(
                  '${player.points.toInt()} PTS',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Text(
            'MATCH STATS / إحصائيات المباراة',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatTile('Goals / أهداف', '${player.goals}', Icons.sports_soccer, AppTheme.primaryGreen),
              _buildStatTile('Assists / صناعة', '${player.assists}', Icons.assistant_photo, AppTheme.goldAccent),
              _buildStatTile('Big Chances / فرص', '${player.bigChances}', Icons.star_border, Colors.amber),
              _buildStatTile('Passes / تمريرات', '${player.passes}', Icons.swap_horiz, Colors.cyan),
              _buildStatTile('Tackles / تدخلات', '${player.tackles}', Icons.shield, Colors.blue),
              _buildStatTile('Clean Sheet / نظافة شباك', '${player.cleanSheet}', Icons.verified, Colors.teal),
              _buildStatTile('Saves / تصديات', '${player.saves}', Icons.front_hand, Colors.orange),
              _buildStatTile('Yellow Cards / إنذارات', '${player.yellowCards}', Icons.crop_portrait, Colors.yellow),
              _buildStatTile('Red Cards / طرد', '${player.redCards}', Icons.crop_portrait, AppTheme.errorRed),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

