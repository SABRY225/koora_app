import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_theme.dart';
import 'player_stats_sheet.dart';

class PlayerCardWidget extends StatelessWidget {
  final FootballPlayer player;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool compact;

  const PlayerCardWidget({
    super.key,
    required this.player,
    this.isSelected = false,
    this.onSelect,
    this.compact = false,
  });

  Color _getPositionColor() {
    switch (player.position) {
      case PlayerPosition.attack:
        return const Color(0xFFFF416C); // Fiery red/crimson
      case PlayerPosition.midfield:
        return AppTheme.primaryGreen; // Electric green
      case PlayerPosition.defense:
        return const Color(0xFF2193B0); // Deep cyan/blue
      case PlayerPosition.goalkeeper:
        return AppTheme.goldAccent; // Gold
    }
  }

  String _getPositionCode() {
    switch (player.position) {
      case PlayerPosition.attack:
        return 'FW';
      case PlayerPosition.midfield:
        return 'MF';
      case PlayerPosition.defense:
        return 'DF';
      case PlayerPosition.goalkeeper:
        return 'GK';
    }
  }

  int _getCalculatedRating() {
    int base = 78;
    if (player.goals > 0) base += player.goals * 4;
    if (player.assists > 0) base += player.assists * 3;
    if (player.tackles > 0) base += player.tackles * 2;
    if (player.cleanSheet > 0) base += player.cleanSheet * 3;
    if (player.points > 0) base += (player.points / 2).round();
    return base.clamp(72, 98);
  }

  @override
  Widget build(BuildContext context) {
    final posColor = _getPositionColor();
    final posCode = _getPositionCode();
    final rating = _getCalculatedRating();

    if (compact) {
      return _buildCompactCard(context, posColor, posCode, rating);
    }

    return GestureDetector(
      onTap: () {
        SoundService().playTap();
        PlayerStatsSheet.show(context, player);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              posColor.withValues(alpha: 0.18),
              AppTheme.surfaceCharcoal,
              AppTheme.surfaceCharcoal,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected ? AppTheme.goldAccent : posColor.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.goldAccent.withValues(alpha: 0.25)
                  : posColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Rating + Position Shield
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundBlack.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: posColor.withValues(alpha: 0.6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rating',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldAccent,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      posCode,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: posColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 2. Team Logo / Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipOval(
                  child: player.teamLogo.isNotEmpty
                      ? Image.network(
                          player.teamLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.sports_soccer,
                            color: AppTheme.textMuted,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.sports_soccer,
                          color: AppTheme.textMuted,
                          size: 22,
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // 3. Name & Team & Stats Pills
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: GoogleFonts.oswald(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.info_outline, color: Colors.white38, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.teamName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Quick Mini-Stats Pills
                    Row(
                      children: [
                        _buildMiniStat('PTS', '${player.points.toInt()}'),
                        const SizedBox(width: 6),
                        if (player.goals > 0) ...[
                          _buildMiniStat('G', '${player.goals}', color: AppTheme.primaryGreen),
                          const SizedBox(width: 6),
                        ],
                        if (player.assists > 0) ...[
                          _buildMiniStat('A', '${player.assists}', color: AppTheme.goldAccent),
                          const SizedBox(width: 6),
                        ],
                        if (player.tackles > 0) ...[
                          _buildMiniStat('TK', '${player.tackles}'),
                          const SizedBox(width: 6),
                        ],
                        if (player.cleanSheet > 0) ...[
                          _buildMiniStat('CS', '${player.cleanSheet}', color: Colors.blueAccent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 4. Action Button: Select
              if (onSelect != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    SoundService().playDraftPick();
                    onSelect!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppTheme.goldAccent : posColor,
                    foregroundColor: AppTheme.backgroundBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isSelected ? '✓ PICKED' : 'DRAFT',
                    style: GoogleFonts.oswald(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Color posColor, String posCode, int rating) {
    return GestureDetector(
      onTap: () {
        SoundService().playTap();
        PlayerStatsSheet.show(context, player);
      },
      child: Container(
        width: 78,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCharcoal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: posColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: posColor.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$rating',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldAccent,
                  ),
                ),
                Text(
                  posCode,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: posColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black26,
              backgroundImage: player.teamLogo.isNotEmpty ? NetworkImage(player.teamLogo) : null,
              child: player.teamLogo.isEmpty
                  ? const Icon(Icons.sports_soccer, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              player.name,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

