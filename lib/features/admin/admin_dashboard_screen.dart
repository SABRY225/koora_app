import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart';
import '../../core/providers/ad_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../ads/full_screen_video_ad_screen.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';
import 'add_edit_ad_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, INACTIVE, EXPIRED

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdProvider>().fetchAds();
      context.read<AppStateProvider>().fetchUserProfile();
    });
  }

  void _handleLogout() async {
    final isArabic = context.read<LocaleProvider>().locale.languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isArabic ? 'تسجيل الخروج' : 'Logout',
          style: GoogleFonts.inter(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟' : 'Are you sure you want to log out?',
          style: GoogleFonts.inter(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _openPlayerMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _confirmDeleteAd(AdModel ad) async {
    final isArabic = context.read<LocaleProvider>().locale.languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.errorRed, size: 24),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'حذف الإعلان نهائياً' : 'Permanent Ad Deletion',
              style: GoogleFonts.inter(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف الإعلان "${ad.title}" نهائياً؟\nسيتم مسح ملف الفيديو الفعلي من سيرفر التخزين لتوفير المساحة.'
              : 'Are you sure you want to permanently delete "${ad.title}"?\nThe physical video file will be permanently removed from server disk to save storage space.',
          style: GoogleFonts.inter(color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'حذف نهائي من السيرفر' : 'Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AdProvider>().deleteAd(ad.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isArabic ? 'تم حذف الإعلان وملف الفيديو من السيرفر بنجاح' : 'Ad and video file deleted from server')
                  : (isArabic ? 'فشل في حذف الإعلان' : 'Failed to delete ad'),
            ),
            backgroundColor: success ? AppTheme.primaryGreen : AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<AdProvider>();
    final user = context.watch<AppStateProvider>().currentUser;
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.locale.languageCode == 'ar';

    // Filter ads
    final filteredAds = adProvider.ads.where((ad) {
      if (_selectedFilter == 'ACTIVE') return ad.isEffectiveActive;
      if (_selectedFilter == 'INACTIVE') return !ad.isActive;
      if (_selectedFilter == 'EXPIRED') return ad.isExpired;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCharcoal,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryGreen),
              ),
              child: Text(
                'ADMIN',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic ? 'لوحة إدارة الإعلانات' : 'Ads Management',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Switch to Player View Button
          TextButton.icon(
            onPressed: _openPlayerMode,
            icon: const Icon(Icons.sports_soccer, color: AppTheme.goldAccent, size: 18),
            label: Text(
              isArabic ? 'تطبيق اللاعب' : 'Player View',
              style: GoogleFonts.inter(
                color: AppTheme.goldAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            tooltip: isArabic ? 'تسجيل الخروج' : 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final adProvider = context.read<AdProvider>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAdScreen()),
          );
          if (result == true && mounted) {
            adProvider.fetchAds();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.backgroundBlack,
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: Text(
          isArabic ? 'إضافة إعلان جديد' : 'NEW AD',
          style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AdProvider>().fetchAds();
        },
        color: AppTheme.primaryGreen,
        backgroundColor: AppTheme.surfaceCharcoal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Profile Card
              _buildAdminProfileCard(user, isArabic),
              const SizedBox(height: 20),

              // Statistics Metrics Grid
              _buildStatsGrid(adProvider, isArabic),
              const SizedBox(height: 24),

              // Filters Row
              _buildFilterChips(adProvider, isArabic),
              const SizedBox(height: 16),

              // Ads List
              if (adProvider.isLoading && adProvider.ads.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                )
              else if (filteredAds.isEmpty)
                _buildEmptyState(isArabic)
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredAds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final ad = filteredAds[index];
                    return _buildAdCard(ad, isArabic);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfileCard(User? user, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.backgroundBlack,
            child: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.username ?? 'admin',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUPER ADMIN',
                        style: GoogleFonts.oswald(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'a@gmail.com',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${user?.coins ?? 10000}',
                  style: GoogleFonts.oswald(
                    color: AppTheme.goldAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdProvider provider, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: isArabic ? 'إجمالي الإعلانات' : 'Total Ads',
            value: '${provider.totalAdsCount}',
            icon: Icons.video_library_outlined,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: isArabic ? 'إعلانات نشطة' : 'Active Ads',
            value: '${provider.activeAdsCount}',
            icon: Icons.check_circle_outline,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: isArabic ? 'المشاهدات' : 'Total Views',
            value: '${provider.totalViewsCount}',
            icon: Icons.visibility_outlined,
            color: AppTheme.goldAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: isArabic ? 'المكتملة' : 'Completed',
            value: '${provider.totalCompletionsCount}',
            icon: Icons.task_alt,
            color: const Color(0xFF00D1FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AdProvider provider, bool isArabic) {
    final filters = [
      {'key': 'ALL', 'label': isArabic ? 'الكل (${provider.ads.length})' : 'All (${provider.ads.length})'},
      {'key': 'ACTIVE', 'label': isArabic ? 'نشطة (${provider.activeAdsCount})' : 'Active (${provider.activeAdsCount})'},
      {'key': 'INACTIVE', 'label': isArabic ? 'معطلة' : 'Inactive'},
      {'key': 'EXPIRED', 'label': isArabic ? 'منتهية الصلاحية' : 'Expired'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = f['key']!;
                  });
                }
              },
              selectedColor: AppTheme.primaryGreen,
              backgroundColor: AppTheme.surfaceCharcoal,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? AppTheme.backgroundBlack : AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : Colors.white12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdCard(AdModel ad, bool isArabic) {
    Color statusColor;
    String statusText;

    if (ad.isExpired) {
      statusColor = AppTheme.errorRed;
      statusText = isArabic ? 'منتهي الصلاحية' : 'Expired';
    } else if (ad.isActive) {
      statusColor = AppTheme.primaryGreen;
      statusText = isArabic ? 'نشط' : 'Active';
    } else {
      statusColor = AppTheme.textMuted;
      statusText = isArabic ? 'معطل (Inactive)' : 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Status Chip + Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${ad.rewardCoins} ${isArabic ? 'نقطة' : 'Coins'}',
                            style: GoogleFonts.oswald(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Direct Toggle Switch
              Switch(
                value: ad.isActive,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) {
                  context.read<AdProvider>().toggleAdActive(ad.id, ad.isActive);
                },
              ),
            ],
          ),

          if (ad.description != null && ad.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ad.description!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(color: Colors.white12, height: 20),

          // Schedule & Stats details
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ad.endDate != null
                      ? '${isArabic ? 'ينتهي في:' : 'Expires:'} ${ad.endDate!.year}-${ad.endDate!.month.toString().padLeft(2, '0')}-${ad.endDate!.day.toString().padLeft(2, '0')} ${ad.endDate!.hour.toString().padLeft(2, '0')}:${ad.endDate!.minute.toString().padLeft(2, '0')}'
                      : (isArabic ? 'بدون تاريخ انتهاء (دائم)' : 'No expiry (Permanent)'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ad.isExpired ? AppTheme.errorRed : AppTheme.textMuted,
                    fontWeight: ad.isExpired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              // Stats
              Row(
                children: [
                  const Icon(Icons.visibility, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${ad.viewsCount}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${ad.completionsCount}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          if (ad.linkUrl != null && ad.linkUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ad.linkUrl!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons: Preview as Player, Edit, Delete
          Row(
            children: [
              // Preview Full Ad Player
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenVideoAdScreen(ad: ad, isPreview: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill, size: 16, color: AppTheme.primaryGreen),
                  label: Text(
                    isArabic ? 'معاينة الإعلان' : 'Preview Ad',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.textWhite, size: 20),
                tooltip: isArabic ? 'تعديل' : 'Edit',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditAdScreen(existingAd: ad),
                    ),
                  );
                  if (result == true && mounted) {
                    context.read<AdProvider>().fetchAds();
                  }
                },
              ),
              const SizedBox(width: 6),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                tooltip: isArabic ? 'حذف' : 'Delete',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _confirmDeleteAd(ad),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.video_collection_outlined, size: 60, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد إعلانات مطابقة' : 'No Ads Found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'اضغط على زر "إضافة إعلان جديد" لرفع فيديوهات وحملات إعلانية بمكافأة.'
                : 'Click "NEW AD" below to create and schedule your video ads.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
