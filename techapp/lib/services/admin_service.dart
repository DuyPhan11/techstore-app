import '../config/api_config.dart';
import '../models/admin_dashboard_model.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AdminService {
  /// Lấy số liệu thống kê tổng quan (Dashboard)
  static Future<DashboardSummaryModel> getDashboardSummary({
    int? days,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> params = {};
    if (startDate != null && endDate != null) {
      params['startDate'] = startDate;
      params['endDate'] = endDate;
    } else if (days != null) {
      params['days'] = days;
    } else {
      params['days'] = 30;
    }

    final data = await ApiService.get(
      ApiConfig.adminDashboard,
      params: params,
    );
    return DashboardSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lấy danh sách toàn bộ đơn hàng trong hệ thống (kèm lọc trạng thái)
  static Future<List<OrderModel>> getAdminOrders({String? status, int page = 0, int size = 30}) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }

    final data = await ApiService.get(ApiConfig.adminOrders, params: params);

    List<dynamic> list = [];
    if (data is Map && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    }

    return list.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Cập nhật trạng thái đơn hàng (CONFIRMED, PROCESSING, SHIPPING, COMPLETED, CANCELLED)
  static Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    final data = await ApiService.put(
      '${ApiConfig.adminOrders}/$orderId/status',
      body: {'status': status},
    );
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Xử lý duyệt hoặc từ chối yêu cầu đổi trả
  static Future<OrderModel> processReturnDecision(int orderId, {
    required bool approve,
    String? rejectReason,
    bool refundDirectly = false,
    String? note,
  }) async {
    final data = await ApiService.post(
      '${ApiConfig.adminOrders}/$orderId/return-decision',
      body: {
        'approve': approve,
        'rejectReason': rejectReason,
        'refundDirectly': refundDirectly,
        'note': note,
      },
    );
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Xác nhận hoàn tiền cho đơn hàng
  static Future<OrderModel> processRefund(int orderId, {String? note}) async {
    final data = await ApiService.post(
      '${ApiConfig.adminOrders}/$orderId/refund',
      params: note != null && note.isNotEmpty ? {'note': note} : null,
    );
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lấy thông tin chi tiết một đơn hàng dành cho Admin
  static Future<OrderModel> getAdminOrderDetail(int orderId) async {
    final data = await ApiService.get('${ApiConfig.adminOrders}/$orderId');
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lấy danh sách người dùng trong hệ thống
  static Future<List<UserModel>> getAdminUsers({int page = 0, int size = 30, String? search}) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final data = await ApiService.get(ApiConfig.adminUsers, params: params);

    List<dynamic> list = [];
    if (data is Map && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    }

    return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Cập nhật trạng thái tài khoản (ACTIVE, LOCKED, INACTIVE)
  static Future<UserModel> updateUserStatus(int userId, String status) async {
    final data = await ApiService.patch(
      '${ApiConfig.adminUsers}/$userId/status',
      body: {'status': status},
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật vai trò người dùng (ADMIN, STAFF, CUSTOMER)
  static Future<UserModel> updateUserRoles(int userId, List<String> roles) async {
    final data = await ApiService.put(
      '${ApiConfig.adminUsers}/$userId/roles',
      body: {'roles': roles},
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lấy danh sách sản phẩm phục vụ quản lý (bao gồm cả ACTIVE và INACTIVE)
  static Future<PageResult<ProductModel>> getManagementProducts({
    int page = 0,
    int size = 20,
    String? keyword,
    String? status, // 'ACTIVE', 'INACTIVE', or null for all
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'size': size,
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }

    final data = await ApiService.get('${ApiConfig.products}/management', params: params);
    return PageResult<ProductModel>.fromJson(
      data,
      (item) => ProductModel.fromJson(item),
    );
  }

  /// Ẩn sản phẩm khỏi hệ thống (soft delete)
  static Future<void> hideProduct(int productId) async {
    await ApiService.delete('${ApiConfig.products}/$productId');
  }

  /// Cập nhật trạng thái hiển thị của sản phẩm (ACTIVE / INACTIVE hoặc toggle nếu status = null)
  static Future<ProductModel> updateProductStatus(int productId, {String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    final data = await ApiService.patch(
      '${ApiConfig.products}/$productId/status',
      params: params,
    );
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// Thêm sản phẩm mới vào hệ thống
  static Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    final data = await ApiService.post(ApiConfig.products, body: productData);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// Lấy thông tin chi tiết sản phẩm cho trang quản trị Admin (kèm giá vốn, phân bổ tồn kho các chi nhánh)
  static Future<ProductModel> getProductForManagement(int productId) async {
    final data = await ApiService.get('${ApiConfig.products}/$productId/management');
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật thông tin sản phẩm từ Admin
  static Future<ProductModel> updateProduct(int productId, Map<String, dynamic> productData) async {
    final data = await ApiService.put('${ApiConfig.products}/$productId', body: productData);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// Điều chỉnh tồn kho sản phẩm tại một chi nhánh cụ thể (SET, ADD, SUBTRACT)
  static Future<dynamic> adjustBranchStock({
    required int productId,
    required int branchId,
    required String adjustmentType,
    required int quantity,
    String? reason,
  }) async {
    final body = {
      'productId': productId,
      'branchId': branchId,
      'adjustmentType': adjustmentType,
      'quantity': quantity,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    return await ApiService.post('${ApiConfig.adminInventory}/adjust', body: body);
  }

  // ==================== QUẢN LÝ DANH MỤC (CATEGORIES) ====================

  /// Lấy toàn bộ danh mục (nếu status = null sẽ lấy cả ACTIVE và INACTIVE)
  static Future<List<CategoryModel>> getCategories({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }
    final data = await ApiService.get(ApiConfig.categories, params: params);
    if (data is List) {
      return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Thêm mới danh mục
  static Future<CategoryModel> createCategory(Map<String, dynamic> categoryData) async {
    final data = await ApiService.post(ApiConfig.categories, body: categoryData);
    return CategoryModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật danh mục
  static Future<CategoryModel> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final data = await ApiService.put('${ApiConfig.categories}/$id', body: categoryData);
    return CategoryModel.fromJson(data as Map<String, dynamic>);
  }

  /// Ẩn / Xóa danh mục
  static Future<void> deleteCategory(int id) async {
    await ApiService.delete('${ApiConfig.categories}/$id');
  }

  // ==================== QUẢN LÝ THƯƠNG HIỆU (BRANDS) ====================

  /// Lấy toàn bộ thương hiệu (nếu status = null sẽ lấy cả ACTIVE và INACTIVE)
  static Future<List<BrandModel>> getBrands({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null && status.isNotEmpty && status != 'ALL') {
      params['status'] = status;
    }
    final data = await ApiService.get(ApiConfig.brands, params: params);
    if (data is List) {
      return data.map((e) => BrandModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Thêm mới thương hiệu
  static Future<BrandModel> createBrand(Map<String, dynamic> brandData) async {
    final data = await ApiService.post(ApiConfig.brands, body: brandData);
    return BrandModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật thương hiệu
  static Future<BrandModel> updateBrand(int id, Map<String, dynamic> brandData) async {
    final data = await ApiService.put('${ApiConfig.brands}/$id', body: brandData);
    return BrandModel.fromJson(data as Map<String, dynamic>);
  }

  /// Ẩn / Xóa thương hiệu
  static Future<void> deleteBrand(int id) async {
    await ApiService.delete('${ApiConfig.brands}/$id');
  }

  // ==================== TẢI TẬP TIN / HÌNH ẢNH ====================

  /// Tải ảnh sản phẩm từ thiết bị lên máy chủ
  static Future<String> uploadImageBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final data = await ApiService.postMultipart(
      '/uploads/image',
      fileField: 'file',
      fileBytes: bytes,
      fileName: fileName,
    );
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    throw ApiException('Không nhận được URL ảnh phản hồi từ server');
  }
}
