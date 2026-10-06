import '../config/api_config.dart';
import '../models/banner_model.dart';
import 'api_service.dart';

class BannerService {
  /// Lấy danh sách banner đang hoạt động cho Trang chủ
  static Future<List<BannerModel>> getActiveBanners() async {
    try {
      final data = await ApiService.get(ApiConfig.banners);
      if (data is List) {
        return data.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy tất cả banner cho Admin
  static Future<List<BannerModel>> getAllBanners() async {
    final data = await ApiService.get(ApiConfig.adminBanners);
    if (data is List) {
      return data.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Tạo banner mới
  static Future<BannerModel> createBanner(Map<String, dynamic> body) async {
    final data = await ApiService.post(ApiConfig.adminBanners, body: body);
    return BannerModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật banner
  static Future<BannerModel> updateBanner(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('${ApiConfig.adminBanners}/$id', body: body);
    return BannerModel.fromJson(data as Map<String, dynamic>);
  }

  /// Bật/Tắt nhanh trạng thái hiển thị
  static Future<BannerModel> toggleStatus(int id, bool active) async {
    final data = await ApiService.patch('${ApiConfig.adminBanners}/$id/status', body: {'active': active});
    return BannerModel.fromJson(data as Map<String, dynamic>);
  }

  /// Xóa banner
  static Future<void> deleteBanner(int id) async {
    await ApiService.delete('${ApiConfig.adminBanners}/$id');
  }

  /// Khởi tạo dữ liệu mẫu nếu chưa có
  static Future<List<BannerModel>> seedDefaultBanners() async {
    final data = await ApiService.post('${ApiConfig.adminBanners}/seed');
    if (data is List) {
      return data.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
