import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/wishlist_service.dart';

class FavoriteProvider extends ChangeNotifier {
  static const String _prefKeyFavorites = 'techstore_favorite_ids';

  final Set<int> _favoriteIds = {};
  List<ProductModel> _favorites = [];
  bool _isLoading = false;

  Set<int> get favoriteIds => _favoriteIds;
  List<ProductModel> get favorites => _favorites;
  int get count => _favoriteIds.length;
  bool get isLoading => _isLoading;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  Future<void> initialize() async {
    await _loadLocalCache();
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      await fetchWishlist();
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKeyFavorites) ?? [];
      _favoriteIds.clear();
      for (var idStr in list) {
        final id = int.tryParse(idStr);
        if (id != null) {
          _favoriteIds.add(id);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _favoriteIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_prefKeyFavorites, list);
    } catch (_) {}
  }

  /// Tải danh sách yêu thích từ máy chủ Backend
  Future<void> fetchWishlist() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final list = await WishlistService.getWishlist();
      _favorites = list;
      _favoriteIds.clear();
      for (var p in list) {
        _favoriteIds.add(p.id);
      }
      await _saveLocalCache();
    } catch (_) {
      // Backend offline or error -> keep local cache
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm hoặc bỏ yêu thích sản phẩm (Đồng bộ tức thì lên UI và Backend)
  Future<bool> toggleFavorite(ProductModel product) async {
    final bool wasFavorite = _favoriteIds.contains(product.id);
    final bool isNowFavorite = !wasFavorite;

    // 1. Optimistic UI update (phản hồi ngay lập tức, không delay)
    if (isNowFavorite) {
      _favoriteIds.add(product.id);
      if (!_favorites.any((p) => p.id == product.id)) {
        _favorites.insert(0, product);
      }
    } else {
      _favoriteIds.remove(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    }
    notifyListeners();
    await _saveLocalCache();

    // 2. Đồng bộ lên Backend nếu đã đăng nhập
    try {
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty) {
        await WishlistService.toggleWishlist(product.id);
      }
    } catch (e) {
      // Nếu máy chủ lỗi, giữ nguyên offline hoặc có thể retry
    }

    return isNowFavorite;
  }

  /// Xóa sản phẩm khỏi danh sách yêu thích
  Future<void> removeFavorite(int productId) async {
    _favoriteIds.remove(productId);
    _favorites.removeWhere((p) => p.id == productId);
    notifyListeners();
    await _saveLocalCache();

    try {
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty) {
        await WishlistService.removeFromWishlist(productId);
      }
    } catch (_) {}
  }

  /// Xóa danh sách khi đăng xuất
  Future<void> clearOnLogout() async {
    _favoriteIds.clear();
    _favorites.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyFavorites);
  }
}
