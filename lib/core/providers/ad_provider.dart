import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../network/api_service.dart';

class AdProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AdModel> _ads = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  List<AdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  // Counts for quick admin stats
  int get totalAdsCount => _ads.length;
  int get activeAdsCount => _ads.where((a) => a.isEffectiveActive).length;
  int get totalViewsCount => _ads.fold(0, (sum, a) => sum + a.viewsCount);
  int get totalCompletionsCount => _ads.fold(0, (sum, a) => sum + a.completionsCount);

  Future<void> fetchAds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/ads');
      final list = (response['data'] as List? ?? []);
      _ads = list.map((item) => AdModel.fromJson(item)).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAd({
    required String title,
    String? description,
    required String videoUrl,
    String? linkUrl,
    int rewardCoins = 500,
    bool isActive = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/ads', {
        'title': title,
        if (description != null) 'description': description,
        'videoUrl': videoUrl,
        if (linkUrl != null && linkUrl.isNotEmpty) 'linkUrl': linkUrl,
        'rewardCoins': rewardCoins,
        'isActive': isActive,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      });

      final newAd = AdModel.fromJson(response['data']);
      _ads.insert(0, newAd);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAd({
    required String id,
    String? title,
    String? description,
    String? videoUrl,
    String? linkUrl,
    int? rewardCoins,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/ads/$id', {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (linkUrl != null) 'linkUrl': linkUrl,
        if (rewardCoins != null) 'rewardCoins': rewardCoins,
        if (isActive != null) 'isActive': isActive,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      });

      final updated = AdModel.fromJson(response['data']);
      final index = _ads.indexWhere((a) => a.id == id);
      if (index != -1) {
        _ads[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAdActive(String id, bool currentStatus) async {
    final nextStatus = !currentStatus;
    // Optimistic local update
    final index = _ads.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = _ads[index];
      _ads[index] = AdModel(
        id: old.id,
        title: old.title,
        description: old.description,
        videoUrl: old.videoUrl,
        linkUrl: old.linkUrl,
        rewardCoins: old.rewardCoins,
        isActive: nextStatus,
        startDate: old.startDate,
        endDate: old.endDate,
        viewsCount: old.viewsCount,
        completionsCount: old.completionsCount,
        isExpired: old.isExpired,
        isEffectiveActive: nextStatus && !old.isExpired,
      );
      notifyListeners();
    }

    try {
      await _apiService.put('/ads/$id', {
        'isActive': nextStatus,
      });
      return true;
    } catch (e) {
      // Revert if error
      await fetchAds();
      return false;
    }
  }

  Future<bool> deleteAd(String id) async {
    try {
      await _apiService.delete('/ads/$id');
      _ads.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadVideoFile({
    String? filePath,
    List<int>? fileBytes,
    required String filename,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.uploadMultipart(
        '/ads/upload',
        fieldName: 'video',
        filePath: filePath,
        fileBytes: fileBytes,
        filename: filename,
      );

      _isUploading = false;
      notifyListeners();
      return response['data']?['url'];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  Future<AdModel?> getRandomAd() async {
    try {
      final response = await _apiService.get('/ads/random');
      if (response['data'] != null) {
        return AdModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error getting random ad: $e');
    }
    return null;
  }
}

