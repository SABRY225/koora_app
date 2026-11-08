import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/ad_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class AddEditAdScreen extends StatefulWidget {
  final AdModel? existingAd;

  const AddEditAdScreen({super.key, this.existingAd});

  @override
  State<AddEditAdScreen> createState() => _AddEditAdScreenState();
}

class _AddEditAdScreenState extends State<AddEditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _linkUrlController;
  late final TextEditingController _coinsController;

  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  String? _selectedFileName;

  VideoPlayerController? _previewController;
  bool _isPreviewReady = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.existingAd;
    _titleController = TextEditingController(text: ad?.title ?? '');
    _descriptionController = TextEditingController(text: ad?.description ?? '');
    _videoUrlController = TextEditingController(text: ad?.videoUrl ?? '');
    _linkUrlController = TextEditingController(text: ad?.linkUrl ?? '');
    _coinsController = TextEditingController(text: (ad?.rewardCoins ?? 500).toString());
    _isActive = ad?.isActive ?? true;
    _startDate = ad?.startDate ?? DateTime.now();
    _endDate = ad?.endDate;

    if (_videoUrlController.text.isNotEmpty) {
      _initPreviewPlayer(_videoUrlController.text);
    }
  }

  void _initPreviewPlayer(String url) async {
    _previewController?.dispose();
    _isPreviewReady = false;
    setState(() {});

    if (url.trim().isEmpty) return;

    final resolved = ApiService.resolveUrl(url.trim());
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0); // Muted preview
      controller.play();

      if (mounted) {
        setState(() {
          _previewController = controller;
          _isPreviewReady = true;
        });
      }
    } catch (e) {
      debugPrint('Preview player error: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _linkUrlController.dispose();
    _coinsController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    final adProvider = context.read<AdProvider>();
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (files.isNotEmpty) {
      final file = files.first;
      setState(() {
        _selectedFileName = file.name;
        if (_titleController.text.trim().isEmpty) {
          final cleanTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _titleController.text = cleanTitle;
        }
      });

      List<int>? bytes;
      if (file.path == null) {
        bytes = await file.readAsBytes();
      }

      final uploadedUrl = await adProvider.uploadVideoFile(
        filePath: file.path,
        fileBytes: bytes,
        filename: file.name,
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _videoUrlController.text = uploadedUrl;
        });
        _initPreviewPlayer(uploadedUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم رفع الفيديو بنجاح!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adProvider.errorMessage ?? 'فشل في رفع الفيديو',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              onPrimary: AppTheme.backgroundBlack,
              surface: AppTheme.surfaceCharcoal,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? now.add(const Duration(hours: 23, minutes: 59))),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryGreen,
                onPrimary: AppTheme.backgroundBlack,
                surface: AppTheme.surfaceCharcoal,
                onSurface: AppTheme.textWhite,
              ),
            ),
            child: child!,
          );
        },
      );

      final hour = pickedTime?.hour ?? 23;
      final minute = pickedTime?.minute ?? 59;

      setState(() {
        _endDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          hour,
          minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء رفع فيديو أو إدخال رابط الفيديو', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final adProvider = context.read<AdProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final videoUrl = _videoUrlController.text.trim();
    final linkUrl = _linkUrlController.text.trim();
    final coins = int.tryParse(_coinsController.text.trim()) ?? 500;

    bool success;
    if (widget.existingAd != null) {
      success = await adProvider.updateAd(
        id: widget.existingAd!.id,
        title: title,
        description: description.isNotEmpty ? description : null,
        videoUrl: videoUrl,
        linkUrl: linkUrl.isNotEmpty ? linkUrl : null,
        rewardCoins: coins,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      success = await adProvider.createAd(
        title: title,
        description: description.isNotEmpty ? description : null,
        videoUrl: videoUrl,
        linkUrl: linkUrl.isNotEmpty ? linkUrl : null,
        rewardCoins: coins,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingAd != null ? 'تم تعديل الإعلان بنجاح' : 'تم إضافة الإعلان بنجاح',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adProvider.errorMessage ?? 'حدث خطأ أثناء الحفظ'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<AdProvider>();
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Text(
          widget.existingAd != null
              ? (isArabic ? 'تعديل الإعلان' : 'Edit Ad')
              : (isArabic ? 'إضافة إعلان جديد' : 'New Video Ad'),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryGreen),
            onPressed: (_isSaving || adProvider.isUploading) ? null : _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Video Upload / Source Box
              _buildSectionHeader(isArabic ? 'الفيديو المخصص للإعلان' : 'Ad Video Source'),
              const SizedBox(height: 12),
              _buildVideoPickerCard(adProvider, isArabic),

              const SizedBox(height: 24),

              // 2. Video Details
              _buildSectionHeader(isArabic ? 'تفاصيل الإعلان' : 'Ad Details'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                label: isArabic ? 'عنوان الإعلان *' : 'Ad Title *',
                hint: isArabic ? 'مثال: إعلان مسابقة دوري الأبطال' : 'e.g. Champions League Ad',
                icon: Icons.title,
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? (isArabic ? 'يرجى إدخال العنوان' : 'Title is required')
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: isArabic ? 'وصف الإعلان' : 'Description (Optional)',
                hint: isArabic ? 'شاهد الفيديو بالكامل لتحصل على المكافأة' : 'Watch video to earn coins',
                icon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _coinsController,
                label: isArabic ? 'عدد نقاط المكافأة' : 'Reward Coins',
                hint: '500',
                icon: Icons.monetization_on,
                keyboardType: TextInputType.number,
                validator: (val) {
                  final n = int.tryParse(val ?? '');
                  if (n == null || n <= 0) {
                    return isArabic ? 'يرجى إدخال رقم صحيح أكبر من صفر' : 'Enter a valid number > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _linkUrlController,
                label: isArabic ? 'رابط الموقع / الإعلان الخارجي (اختياري)' : 'External Website / Action URL (Optional)',
                hint: 'https://example.com',
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 28),

              // 3. Expiration / Schedule & Active Status
              _buildSectionHeader(isArabic ? 'الجدولة وصلاحية العرض' : 'Schedule & Visibility'),
              const SizedBox(height: 12),
              _buildScheduleCard(isArabic),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || adProvider.isUploading) ? null : _handleSave,
                  icon: (_isSaving || adProvider.isUploading)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundBlack),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    (_isSaving || adProvider.isUploading)
                        ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                        : (isArabic ? 'حفظ ونشر الإعلان' : 'Save & Publish Ad'),
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.backgroundBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textWhite,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildVideoPickerCard(AdProvider adProvider, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Video Preview if available
          if (_previewController != null && _isPreviewReady) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _previewController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_previewController!),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic ? 'معاينة مباشرة' : 'Live Preview',
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Upload File Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: adProvider.isUploading ? null : _pickVideoFile,
              icon: adProvider.isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                    )
                  : const Icon(Icons.file_upload_outlined, color: AppTheme.primaryGreen),
              label: Text(
                adProvider.isUploading
                    ? (isArabic ? 'جاري رفع الفيديو إلى السيرفر...' : 'Uploading video...')
                    : (_selectedFileName != null
                        ? (isArabic ? 'تم اختيار: $_selectedFileName' : 'Selected: $_selectedFileName')
                        : (isArabic ? 'رفع فيديو من الجهاز (Upload File)' : 'Upload Video File')),
                style: GoogleFonts.inter(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              isArabic ? 'أو أدخل رابط الفيديو مباشرة:' : 'Or enter video URL directly:',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 8),

          // URL Text Input
          TextFormField(
            controller: _videoUrlController,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              hintText: 'https://example.com/video.mp4',
              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppTheme.backgroundBlack,
              prefixIcon: const Icon(Icons.link, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryGreen),
                onPressed: () {
                  _initPreviewPlayer(_videoUrlController.text);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              if (val.trim().endsWith('.mp4') || val.trim().contains('http')) {
                _initPreviewPlayer(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(bool isArabic) {
    final now = DateTime.now();
    final bool isExpired = _endDate != null && now.isAfter(_endDate!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Active Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryGreen,
            title: Text(
              isArabic ? 'تفعيل الإعلان (Active)' : 'Active Status',
              style: GoogleFonts.inter(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive
                  ? (isArabic ? 'الإعلان متاح للظهور للمستخدمين' : 'Ad is available to show')
                  : (isArabic ? 'الإعلان معطل حالياً ولن يظهر' : 'Ad is paused'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isActive ? AppTheme.primaryGreen : AppTheme.textMuted,
              ),
            ),
            value: _isActive,
            onChanged: (val) {
              setState(() {
                _isActive = val;
              });
            },
          ),

          const Divider(color: Colors.white12, height: 24),

          // Expiry Date Selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpired
                    ? AppTheme.errorRed.withValues(alpha: 0.15)
                    : AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.event_busy,
                color: isExpired ? AppTheme.errorRed : AppTheme.primaryGreen,
              ),
            ),
            title: Text(
              isArabic ? 'تاريخ ووقت انتهاء الصلاحية' : 'Expiration Date & Time',
              style: GoogleFonts.inter(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              _endDate != null
                  ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')} ${_endDate!.hour.toString().padLeft(2, '0')}:${_endDate!.minute.toString().padLeft(2, '0')}'
                      '${isExpired ? (isArabic ? ' (منتهي الصلاحية!)' : ' (Expired!)') : ''}'
                  : (isArabic ? 'غير محدد (يظل فعال دائماً ما دام مفعلاً)' : 'No expiration (Always active)'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isExpired ? AppTheme.errorRed : AppTheme.textMuted,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 20),
                    onPressed: () {
                      setState(() {
                        _endDate = null;
                      });
                    },
                  ),
                ElevatedButton(
                  onPressed: _selectExpiryDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.backgroundBlack,
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    isArabic ? 'تحديد' : 'Select',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.goldAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'عند انتهاء هذا التاريخ، سيتحول الإعلان تلقائياً إلى غير نشط (Deactivated) ولن يتم اختياره عند طلب المشاهدة.'
                        : 'After this date, the video will automatically deactivate and won\'t appear for players.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppTheme.textMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppTheme.surfaceCharcoal,
            prefixIcon: Icon(icon, color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
