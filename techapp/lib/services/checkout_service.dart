import '../config/api_config.dart';
import '../models/branch_model.dart';
import '../models/coupon_model.dart';
import '../models/order_model.dart';
import 'api_service.dart';

class CheckoutService {
  static Future<List<BranchModel>> getBranches() async {
    final data = await ApiService.get(ApiConfig.branches);
    if (data is List) {
      return data.map((e) => BranchModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<CouponValidationModel> validateCoupon(String couponCode, double orderAmount) async {
    final data = await ApiService.post(
      ApiConfig.validateCoupon,
      body: {
        'couponCode': couponCode.trim(),
        'orderAmount': orderAmount,
      },
    );
    return CouponValidationModel.fromJson(data);
  }

  static Future<OrderModel> checkout({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    int? branchId,
    String? couponCode,
    required String paymentMethod,
    String? notes,
    int? directProductId,
    int? directQuantity,
    List<int>? selectedCartItemIds,
    double? shippingFee,
    double? vatRate,
    bool mockPaymentSuccess = true,
  }) async {
    final body = {
      'recipientName': recipientName.trim(),
      'recipientPhone': recipientPhone.trim(),
      'shippingAddress': shippingAddress.trim(),
      'branchId': ?branchId,
      if (couponCode != null && couponCode.trim().isNotEmpty) 'couponCode': couponCode.trim(),
      'paymentMethod': paymentMethod,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'directProductId': ?directProductId,
      'directQuantity': ?directQuantity,
      if (selectedCartItemIds != null && selectedCartItemIds.isNotEmpty)
        'selectedCartItemIds': selectedCartItemIds,
      'shippingFee': ?shippingFee,
      'vatRate': ?vatRate,
      'mockPaymentSuccess': mockPaymentSuccess,
    };

    final data = await ApiService.post(ApiConfig.checkout, body: body);
    return OrderModel.fromJson(data);
  }
}
