import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../core/models/models.dart' as md;
import '../../core/network/api_service.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../draft/draft_screen.dart';
import '../profile/widgets/avatar_selector_sheet.dart';

class GameLobbyScreen extends StatefulWidget {
  final md.Match match;
  final String gameId;

  const GameLobbyScreen({
    super.key,
    required this.match,
    required this.gameId,
  });

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  IO.Socket? _socket;
  Timer? _pollingTimer;
  List<dynamic> _participants = [];
  bool _hasStartedDraft = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLobbyState();
    _connectSocket();
    _startPollingFallback();
  }

  void _connectSocket() {
    try {
      _socket = IO.io(
        '${ApiService.socketUrl}/game',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        _socket?.emit('game:join-room', {'gameId': widget.gameId});
        _socket?.emit('join:room', widget.gameId);
      });

      _socket?.on('game:participant-joined', (data) {
        if (!mounted || _hasStartedDraft) return;
        SoundService().playTap();
        _fetchLobbyState();
      });

      _socket?.on('game:draft-started', (_) {
        _triggerDraftStart();
      });

      _socket?.on('game:draft-turn', (_) {
        _triggerDraftStart();
      });
    } catch (e) {
      debugPrint('Lobby socket connection error: $e');
    }
  }

  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_hasStartedDraft) {
        _fetchLobbyState();
      }
    });
  }

  Future<void> _fetchLobbyState() async {
    try {
      final api = ApiService();
      final res = await api.get('/games/${widget.gameId}');
      final data = res['data'];
      if (data == null || !mounted) return;

      final status = data['status'];
      final parts = data['participants'] as List? ?? [];

      setState(() {
        _participants = parts;
        _isLoading = false;
      });

      if ((status == 'DRAFTING' || status == 'LIVE' || parts.length >= 4) && !_hasStartedDraft) {
        _triggerDraftStart();
      }
    } catch (e) {
      debugPrint('Error fetching lobby state: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _triggerDraftStart() {
    if (_hasStartedDraft || !mounted) return;
    _hasStartedDraft = true;
    _pollingTimer?.cancel();
    SoundService().playWhistle();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DraftScreen(match: widget.match, gameId: widget.gameId),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';
    final currentCount = _participants.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Text(
          isArabic ? 'غرفة انتظار المتحدين' : 'CHALLENGERS LOBBY',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppTheme.textWhite,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldAccent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '500 COINS',
                  style: GoogleFonts.oswald(
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading && _participants.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Match Header Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.match.homeTeam,
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'VS',
                            style: GoogleFonts.oswald(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        Text(
                          widget.match.awayTeam,
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Room Progress Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withValues(alpha: 0.15),
                          AppTheme.surfaceCharcoal,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isArabic
                                  ? 'بانتظار اكتمال اللاعبين ($currentCount / 4)'
                                  : 'WAITING FOR PLAYERS ($currentCount / 4)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic
                            ? 'ستبدأ مرحلة الدرافت فور انضمام 4 لاعبين حقيقيين إلى الغرفة'
                            : 'The draft will start as soon as 4 real challengers join this room',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // 4 Challenger Slots Grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final bool isFilled = index < _participants.length;
                        final part = isFilled ? _participants[index] as Map<String, dynamic> : null;
                        final String? username = part?['username'];
                        final String? avatar = part?['avatarUrl'];
                        final int pos = isFilled ? (part?['draftPosition'] ?? (index + 1)) : (index + 1);

                        return Container(
                          decoration: BoxDecoration(
                            color: isFilled
                                ? AppTheme.surfaceCharcoal
                                : AppTheme.surfaceCharcoal.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFilled
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.7)
                                  : Colors.white12,
                              width: isFilled ? 1.5 : 1,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SLOT #$pos',
                                  style: GoogleFonts.oswald(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isFilled) ...[
                                UserAvatarView(
                                  avatarUrl: avatar,
                                  username: username ?? 'Player',
                                  radius: 28,
                                  showGlow: true,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  username ?? 'Challenger',
                                  style: GoogleFonts.oswald(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      isArabic ? 'جاهز' : 'READY',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Icon(Icons.person_add_alt_1, color: Colors.white24, size: 26),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isArabic ? 'بانتظار لاعب...' : 'Waiting...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ).animate(target: isFilled ? 1 : 0).scale(duration: 300.ms);
                      },
                    ),
                  ),

                  // Exit Lobby Button
                  TextButton.icon(
                    onPressed: () {
                      SoundService().playTap();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                    label: Text(
                      isArabic ? 'الخروج من الغرفة' : 'LEAVE LOBBY',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

