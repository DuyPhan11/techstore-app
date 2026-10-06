import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class RecentlyViewedService {
  static const String _key = 'recently_viewed_products';
  static const int _maxItems = 12;

  /// Lấy danh sách sản phẩm vừa xem từ SharedPreferences
  static Future<List<ProductModel>> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key);
      if (jsonList == null || jsonList.isEmpty) return [];

      final List<ProductModel> products = [];
      for (final itemStr in jsonList) {
        try {
          final map = jsonDecode(itemStr) as Map<String, dynamic>;
          products.add(ProductModel.fromJson(map));
        } catch (_) {}
      }
      return products;
    } catch (_) {
      return [];
    }
  }

  /// Thêm hoặc đẩy sản phẩm vừa xem lên vị trí đầu tiên
  static Future<void> addProduct(ProductModel product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key) ?? [];

      // Xóa nếu sản phẩm này đã có trong danh sách (để đưa lên đầu)
      jsonList.removeWhere((itemStr) {
        try {
          final map = jsonDecode(itemStr) as Map<String, dynamic>;
          return map['id'] == product.id;
        } catch (_) {
          return false;
        }
      });

      // Chèn lên vị trí đầu
      jsonList.insert(0, jsonEncode(product.toJson()));

      // Giới hạn tối đa _maxItems sản phẩm
      if (jsonList.length > _maxItems) {
        jsonList.removeRange(_maxItems, jsonList.length);
      }

      await prefs.setStringList(_key, jsonList);
    } catch (_) {}
  }

  /// Xóa 1 sản phẩm khỏi lịch sử xem
  static Future<void> removeProduct(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key) ?? [];
      jsonList.removeWhere((itemStr) {
        try {
          final map = jsonDecode(itemStr) as Map<String, dynamic>;
          return map['id'] == productId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_key, jsonList);
    } catch (_) {}
  }

  /// Xóa toàn bộ lịch sử xem
  static Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
