import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/theme/app_theme.dart';

class FullScreenVideoAdScreen extends StatefulWidget {
  final AdModel ad;
  final bool isPreview;

  const FullScreenVideoAdScreen({
    super.key,
    required this.ad,
    this.isPreview = false,
  });

  @override
  State<FullScreenVideoAdScreen> createState() => _FullScreenVideoAdScreenState();
}

class _FullScreenVideoAdScreenState extends State<FullScreenVideoAdScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasCompleted = false;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    final resolvedUrl = ApiService.resolveUrl(widget.ad.videoUrl);
    debugPrint('[FullScreenVideoAd] Loading video from: $resolvedUrl');

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: const {
          'Access-Control-Allow-Origin': '*',
        },
      );
      _controller = controller;

      await controller.initialize();
      controller.play();

      controller.addListener(() {
        if (!mounted) return;
        final position = controller.value.position;
        final duration = controller.value.duration;

        if (duration > Duration.zero && position >= duration && !_hasCompleted) {
          _onVideoFinished();
        }
        setState(() {});
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('[FullScreenVideoAd] VideoPlayer initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onVideoFinished() async {
    if (_hasCompleted || _isClaiming) return;

    setState(() {
      _hasCompleted = true;
    });

    // Admin in preview mode gets NO reward and NO claim request
    if (widget.isPreview) {
      return;
    }

    final user = context.read<AppStateProvider>().currentUser;
    if (user != null && user.isAdmin) {
      // Admin accounts never earn ad coins
      return;
    }

    setState(() {
      _isClaiming = true;
    });

    try {
      final response = await ApiService().post('/wallet/reward', {
        'adId': widget.ad.id,
      });

      final data = response['data'];
      if (data != null && data['balance'] != null) {
        if (mounted) {
          context.read<AppStateProvider>().updateCoinsOptimistically(data['balance']);
          context.read<WalletProvider>().fetchTransactions();
        }
      }
    } catch (e) {
      debugPrint('[FullScreenVideoAd] Reward claiming error: $e');
    }

    if (mounted) {
      setState(() {
        _isClaiming = false;
      });
    }
  }

  Future<void> _launchAdUrl() async {
    final rawUrl = widget.ad.linkUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) return;

    var urlStr = rawUrl.trim();
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[FullScreenVideoAd] Could not launch URL: $e');
    }
  }

  Future<bool> _handleWillPop() async {
    // Admin in preview mode can close at ANY time immediately without any dialog!
    if (widget.isPreview) {
      return true;
    }

    if (_hasCompleted) return true;

    // Pause video while showing dialog
    _controller?.pause();

    final locale = context.read<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.5), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.goldAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic ? 'إلغاء المكافأة؟' : 'Skip Reward?',
                style: GoogleFonts.inter(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'إذا أغلقت الفيديو الآن، فلن تحصل على ${widget.ad.rewardCoins} نقطة!\n\nهل ترغب بالخروج حقاً بدون مكافأة؟'
              : 'If you close the video now, you will NOT receive the ${widget.ad.rewardCoins} coins reward!\n\nAre you sure you want to exit without reward?',
          style: GoogleFonts.inter(
            color: AppTheme.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true); // Confirm Exit
            },
            child: Text(
              isArabic ? 'خروج بدون مكافأة' : 'Exit Without Reward',
              style: GoogleFonts.inter(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, false); // Stay & Resume
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.backgroundBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isArabic ? 'متابعة المشاهدة' : 'Keep Watching',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'لم تكتمل مشاهدة الإعلان، لم يتم إضافة أي نقاط!'
                  : 'Ad was not fully watched, no reward was granted!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return true;
    } else {
      _controller?.play();
      return false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    // Calculate progress
    double progress = 0.0;
    int secondsLeft = 0;
    if (_controller != null && _isInitialized) {
      final pos = _controller!.value.position.inSeconds;
      final dur = _controller!.value.duration.inSeconds;
      if (dur > 0) {
        progress = (pos / dur).clamp(0.0, 1.0);
        secondsLeft = (dur - pos).clamp(0, dur);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(_hasCompleted);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Video Content
            GestureDetector(
              onTap: () {
                if (_controller != null && _isInitialized) {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                  setState(() {});
                }
              },
              child: Center(
                child: _buildVideoContent(isArabic),
              ),
            ),

            // Top Header: Reward Chip or Admin Preview Chip & Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge (Admin Preview or Reward Badge)
                  if (widget.isPreview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCharcoal.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? 'معاينة الأدمن (يمكنك الإغلاق في أي وقت)' : 'ADMIN PREVIEW',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCharcoal.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldAccent.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.ad.rewardCoins} ${isArabic ? 'نقطة' : 'COINS'}',
                            style: GoogleFonts.oswald(
                              color: AppTheme.goldAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Countdown & Close Button
                  Row(
                    children: [
                      if (!_hasCompleted && !widget.isPreview && _isInitialized)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppTheme.textMuted, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${secondsLeft}s',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Close (X) button
                      InkWell(
                        onTap: () async {
                          if (widget.isPreview) {
                            Navigator.of(context).pop();
                            return;
                          }
                          final shouldPop = await _handleWillPop();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop(_hasCompleted);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center Play / Pause Indicator on Tap
            if (_controller != null && _isInitialized && !_controller!.value.isPlaying && !_hasCompleted)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
                ),
              ),

            // Replay Button if video ended in Preview mode
            if (widget.isPreview && _hasCompleted)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _controller?.seekTo(Duration.zero);
                    _controller?.play();
                    setState(() {
                      _hasCompleted = false;
                    });
                  },
                  icon: const Icon(Icons.replay),
                  label: Text(
                    isArabic ? 'إعادة تشغيل الفيديو' : 'Replay Video',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceCharcoal,
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),

            // Bottom Progress & Title Overlay
            if (_isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.ad.title,
                        style: GoogleFonts.inter(
                          color: AppTheme.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.ad.description != null && widget.ad.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.ad.description!,
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (widget.ad.linkUrl != null && widget.ad.linkUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _launchAdUrl,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.open_in_new, color: AppTheme.backgroundBlack, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'زيارة الموقع / عرض المزيد ↗' : 'VISIT WEBSITE ↗',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.backgroundBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Linear Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Completion Celebration Dialog Overlay (ONLY for normal players, NEVER for admin)
            if (_hasCompleted && !widget.isPreview)
              _buildCelebrationOverlay(isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(bool isArabic) {
    if (_controller != null && _isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    if (_hasError) {
      return Container(
        color: const Color(0xFF0D1117),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCharcoal,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.ad.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? 'تعذر تشغيل الفيديو من السيرفر' : 'Failed to load video from server',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.errorRed,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeVideo,
              icon: const Icon(Icons.refresh),
              label: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceCharcoal,
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
    );
  }

  Widget _buildCelebrationOverlay(bool isArabic) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCharcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.goldAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldAccent.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'تهانينا! 🎉' : 'Awesome! 🎉',
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? 'لقد شاهدت الفيديو بالكامل وتمت إضافة\n+${widget.ad.rewardCoins} نقطة إلى محفظتك بنجاح!'
                    : 'You watched the full video!\n+${widget.ad.rewardCoins} Coins added to your wallet!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textWhite,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.ad.linkUrl != null && widget.ad.linkUrl!.trim().isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: _launchAdUrl,
                  icon: const Icon(Icons.open_in_new, color: AppTheme.primaryGreen, size: 18),
                  label: Text(
                    isArabic ? 'زيارة موقع الإعلان' : 'Visit Sponsor Website',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.backgroundBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'استلام ومتابعة اللعب' : 'CLAIM & CONTINUE',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
