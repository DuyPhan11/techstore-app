import '../config/api_config.dart';
import '../models/coupon_model.dart';
import 'api_service.dart';

class CouponService {
  /// Lấy danh sách mã giảm giá cho Admin kèm phân trang & lọc
  static Future<Map<String, dynamic>> getAdminCoupons({
    String? search,
    String? discountType,
    bool? isActive,
    int page = 0,
    int size = 15,
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (discountType != null && discountType.isNotEmpty) {
      params['discountType'] = discountType;
    }
    if (isActive != null) {
      params['isActive'] = isActive;
    }

    final data = await ApiService.get(ApiConfig.adminCoupons, params: params);
    final List<dynamic> content = (data is Map && data['content'] is List) ? data['content'] : [];
    final List<CouponModel> coupons = content.map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList();
    final int totalPages = (data is Map && data['totalPages'] is num) ? (data['totalPages'] as num).toInt() : 1;
    final int totalElements = (data is Map && data['totalElements'] is num) ? (data['totalElements'] as num).toInt() : coupons.length;

    return {
      'coupons': coupons,
      'totalPages': totalPages,
      'totalElements': totalElements,
    };
  }

  /// Lấy thống kê tổng quan về mã giảm giá cho Admin
  static Future<AdminCouponStatsModel> getAdminCouponStats() async {
    final data = await ApiService.get(ApiConfig.adminCouponStats);
    return AdminCouponStatsModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin tạo mã giảm giá mới
  static Future<CouponModel> createCoupon(Map<String, dynamic> body) async {
    final data = await ApiService.post(ApiConfig.adminCoupons, body: body);
    return CouponModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin chỉnh sửa mã giảm giá
  static Future<CouponModel> updateCoupon(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('${ApiConfig.adminCoupons}/$id', body: body);
    return CouponModel.fromJson(data as Map<String, dynamic>);
  }

  /// Bật/Tắt nhanh trạng thái hoạt động của mã
  static Future<CouponModel> toggleCouponStatus(int id, bool active) async {
    final data = await ApiService.patch('${ApiConfig.adminCoupons}/$id/status', body: {'active': active});
    return CouponModel.fromJson(data as Map<String, dynamic>);
  }

  /// Xóa mã giảm giá
  static Future<void> deleteCoupon(int id) async {
    await ApiService.delete('${ApiConfig.adminCoupons}/$id');
  }

  /// Lấy danh sách mã giảm giá khả dụng cho khách hàng (mua sắm / checkout)
  static Future<List<CouponModel>> getAvailableCoupons() async {
    try {
      final data = await ApiService.get(ApiConfig.coupons);
      if (data is List) {
        return data.map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
