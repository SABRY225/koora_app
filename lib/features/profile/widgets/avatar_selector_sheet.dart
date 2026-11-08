import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_theme.dart';

class AvatarHelper {
  static const List<String> avatarAssets = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
    'assets/avatars/avatar_7.png',
    'assets/avatars/avatar_8.png',
    'assets/avatars/avatar_9.png',
    'assets/avatars/avatar_10.png',
    'assets/avatars/avatar_11.png',
    'assets/avatars/avatar_12.png',
  ];

  static const List<String> avatarNames = [
    'El Matador',
    'La Pulga',
    'The Captain',
    'Robo Striker',
    'Playmaker 10',
    'The Wall',
    'Iron Keeper',
    'Speedy Winger',
    'The Boss',
    'Golden Legend',
    'Wonderkid',
    'Mastermind',
  ];
}

class UserAvatarView extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final bool showGlow;
  final bool showEditBadge;
  final VoidCallback? onEdit;

  const UserAvatarView({
    super.key,
    this.avatarUrl,
    required this.username,
    this.radius = 48,
    this.showGlow = true,
    this.showEditBadge = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent;

    final url = avatarUrl?.trim() ?? '';
    if (url.startsWith('assets/')) {
      avatarContent = Image.asset(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackLetter(),
      );
    } else if (url.startsWith('http')) {
      avatarContent = Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackLetter(),
      );
    } else {
      avatarContent = _fallbackLetter();
    }

    final avatarCircle = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceCharcoal,
        border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipOval(child: avatarContent),
    );

    if (!showEditBadge) return avatarCircle;

    return GestureDetector(
      onTap: onEdit,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.backgroundBlack, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.edit, size: 14, color: AppTheme.backgroundBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackLetter() {
    return Container(
      color: AppTheme.surfaceCharcoal,
      alignment: Alignment.center,
      child: Text(
        username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U',
        style: GoogleFonts.oswald(
          fontSize: radius * 0.9,
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AvatarSelectorSheet extends StatelessWidget {
  const AvatarSelectorSheet({super.key});

  static void show(BuildContext context) {
    SoundService().playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AvatarSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentAvatar = appState.currentUser?.avatarUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اختر شخصيتك الكروية / CHOOSE AVATAR',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: AvatarHelper.avatarAssets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final asset = AvatarHelper.avatarAssets[index];
                final name = AvatarHelper.avatarNames[index];
                final isSelected = currentAvatar == asset;

                return GestureDetector(
                  onTap: () async {
                    SoundService().playCoin();
                    await context.read<AppStateProvider>().updateUserAvatar(asset);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.goldAccent : Colors.white12,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.goldAccent.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              asset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppTheme.goldAccent : AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

