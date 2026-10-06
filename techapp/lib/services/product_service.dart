import '../config/api_config.dart';
import '../models/branch_model.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  static Future<PageResult<ProductModel>> getProducts({
    int page = 0,
    int size = 12,
    String? keyword,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortDir,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
      params['search'] = keyword.trim();
    }
    if (categoryId != null) params['categoryId'] = categoryId;
    if (brandId != null) params['brandId'] = brandId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortDir != null) params['sortDir'] = sortDir;

    final data = await ApiService.get(ApiConfig.products, params: params);
    return PageResult<ProductModel>.fromJson(
      data,
      (item) => ProductModel.fromJson(item),
    );
  }

  static Future<List<ProductModel>> getRecommendations({
    List<int>? viewedIds,
    int limit = 6,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
    };
    if (viewedIds != null && viewedIds.isNotEmpty) {
      params['viewedIds'] = viewedIds.join(',');
    }

    final data = await ApiService.get('${ApiConfig.products}/recommendations', params: params);
    if (data is List) {
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<ProductModel> getProductById(int id) async {
    final data = await ApiService.get('${ApiConfig.products}/$id');
    return ProductModel.fromJson(data);
  }

  static Future<ProductModel> getProductBySlug(String slug) async {
    final data = await ApiService.get('${ApiConfig.products}/slug/$slug');
    return ProductModel.fromJson(data);
  }

  static Future<List<CategoryModel>> getCategories() async {
    final data = await ApiService.get(ApiConfig.categories, params: {'status': 'ACTIVE'});
    if (data is List) {
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<BrandModel>> getBrands() async {
    final data = await ApiService.get(ApiConfig.brands, params: {'status': 'ACTIVE'});
    if (data is List) {
      return data.map((e) => BrandModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<BranchModel>> getBranches() async {
    final data = await ApiService.get(ApiConfig.branches);
    if (data is List) {
      return data.map((e) => BranchModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<ProductModel>> getRelatedProducts({
    required int productId,
    int? categoryId,
    int? brandId,
    int limit = 6,
  }) async {
    try {
      final pageResult = await getProducts(
        page: 0,
        size: limit + 1,
        categoryId: categoryId,
        brandId: categoryId == null ? brandId : null,
      );
      return pageResult.content.where((p) => p.id != productId).take(limit).toList();
    } catch (_) {
      return [];
    }
  }
}
