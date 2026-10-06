import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class OrderService {
  static Future<PageResult<OrderModel>> getMyOrders({int page = 0, int size = 20}) async {
    final data = await ApiService.get(
      ApiConfig.ordersMy,
      params: {'page': page, 'size': size},
    );

    if (data is List) {
      final list = data
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return PageResult<OrderModel>(
        content: list,
        pageNumber: 0,
        pageSize: list.length,
        totalElements: list.length,
        totalPages: 1,
        last: true,
      );
    }

    if (data is Map<String, dynamic>) {
      final rawList = data['content'] as List<dynamic>? ?? [];
      final list = rawList
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<OrderModel>(
        content: list,
        pageNumber: data['number'] ?? data['pageNumber'] ?? 0,
        pageSize: data['size'] ?? data['pageSize'] ?? size,
        totalElements: data['totalElements'] ?? list.length,
        totalPages: data['totalPages'] ?? 1,
        last: data['last'] ?? true,
      );
    }

    return PageResult<OrderModel>(
      content: [],
      pageNumber: 0,
      pageSize: size,
      totalElements: 0,
      totalPages: 0,
      last: true,
    );
  }

  static Future<OrderModel> getOrderDetail(int orderId) async {
    final data = await ApiService.get('/orders/$orderId');
    return OrderModel.fromJson(data);
  }

  static Future<OrderModel> cancelOrder(int orderId, String reason) async {
    final data = await ApiService.post(
      '/orders/$orderId/cancel',
      body: {'reason': reason.trim()},
    );
    return OrderModel.fromJson(data);
  }

  static Future<OrderModel> requestReturn(int orderId, {
    required String reason,
    String? note,
    String? returnImages,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) async {
    final data = await ApiService.post(
      '/orders/$orderId/return-request',
      body: {
        'reason': reason,
        'note': note,
        'returnImages': returnImages,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankAccountName': bankAccountName,
      },
    );
    return OrderModel.fromJson(data);
  }

  static Future<OrderModel> processReturnDecision(int orderId, {
    required bool approve,
    String? rejectReason,
    bool refundDirectly = false,
    String? note,
  }) async {
    final data = await ApiService.post(
      '/admin/orders/$orderId/return-decision',
      body: {
        'approve': approve,
        'rejectReason': rejectReason,
        'refundDirectly': refundDirectly,
        'note': note,
      },
    );
    return OrderModel.fromJson(data);
  }

  static Future<OrderModel> processRefund(int orderId, {String? note}) async {
    final data = await ApiService.post(
      '/admin/orders/$orderId/refund',
      params: note != null && note.isNotEmpty ? {'note': note} : null,
    );
    return OrderModel.fromJson(data);
  }
}
