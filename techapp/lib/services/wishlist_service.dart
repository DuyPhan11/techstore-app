import '../config/api_config.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class WishlistService {
  /// Lấy danh sách toàn bộ sản phẩm yêu thích của người dùng
  static Future<List<ProductModel>> getWishlist() async {
    final res = await ApiService.get(ApiConfig.wishlist);
    if (res is List) {
      return res.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy danh sách ID các sản phẩm yêu thích (nhẹ, nhanh)
  static Future<List<int>> getWishlistIds() async {
    final res = await ApiService.get('${ApiConfig.wishlist}/ids');
    if (res is List) {
      return res.map((item) => (item as num).toInt()).toList();
    }
    return [];
  }

  /// Thêm hoặc bỏ yêu thích sản phẩm (Toggle)
  static Future<bool> toggleWishlist(int productId) async {
    final res = await ApiService.post('${ApiConfig.wishlist}/toggle/$productId');
    if (res is bool) {
      return res;
    }
    return true;
  }

  /// Thêm sản phẩm vào yêu thích
  static Future<void> addToWishlist(int productId) async {
    await ApiService.post('${ApiConfig.wishlist}/$productId');
  }

  /// Xóa sản phẩm khỏi yêu thích
  static Future<void> removeFromWishlist(int productId) async {
    await ApiService.delete('${ApiConfig.wishlist}/$productId');
  }
}
