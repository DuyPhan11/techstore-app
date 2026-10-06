class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final int warrantyMonths;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.warrantyMonths = 12,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String? img = json['productImage'] ?? json['productThumbnail'] ?? json['productImageUrl'];

    double sub = 0.0;
    if (json['subtotal'] != null) {
      sub = (json['subtotal'] as num).toDouble();
    } else if (json['subtotalAmount'] != null) {
      sub = (json['subtotalAmount'] as num).toDouble();
    } else if (json['totalPrice'] != null) {
      sub = (json['totalPrice'] as num).toDouble();
    } else {
      final p = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final q = (json['quantity'] as num?)?.toInt() ?? 1;
      sub = p * q;
    }

    return OrderItemModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse('${json['id']}') ?? 0),
      productId: json['productId'] is num ? (json['productId'] as num).toInt() : (int.tryParse('${json['productId']}') ?? 0),
      productName: json['productName']?.toString() ?? '',
      productSku: json['productSku']?.toString(),
      productImageUrl: img?.toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: sub,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 12,
    );
  }
}

class OrderModel {
  final int id;
  final String orderCode;
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final int? branchId;
  final String? branchName;
  final double totalItemsAmount;
  final double discountAmount;
  final double shippingFee;
  final double taxAmount;
  final double vatRate;
  final double finalAmount;
  final String status;
  final String paymentMethod;
  final String? paymentStatus;
  final String? transactionCode;
  final String? couponCode;
  final String? notes;
  final String? returnReason;
  final String? returnNote;
  final String? returnImages;
  final String? bankInfo;
  final String? returnRejectReason;
  final String? returnRequestedAt;
  final String? refundedAt;
  final String? completedAt;
  final List<OrderItemModel> items;
  final String? createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.recipientName,
    required this.recipientPhone,
    required this.shippingAddress,
    this.branchId,
    this.branchName,
    required this.totalItemsAmount,
    required this.discountAmount,
    this.shippingFee = 0.0,
    this.taxAmount = 0.0,
    this.vatRate = 0.08,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus,
    this.transactionCode,
    this.couponCode,
    this.notes,
    this.returnReason,
    this.returnNote,
    this.returnImages,
    this.bankInfo,
    this.returnRejectReason,
    this.returnRequestedAt,
    this.refundedAt,
    this.completedAt,
    this.items = const [],
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return OrderModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse('${json['id']}') ?? 0),
      orderCode: json['orderCode']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      recipientPhone: json['recipientPhone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      branchId: json['branchId'] is num ? (json['branchId'] as num).toInt() : int.tryParse('${json['branchId']}'),
      branchName: json['branchName']?.toString(),
      totalItemsAmount: (json['totalItemsAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0.08,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paymentStatus: json['paymentStatus']?.toString(),
      transactionCode: json['transactionCode']?.toString(),
      couponCode: json['couponCode']?.toString(),
      notes: json['notes']?.toString(),
      returnReason: json['returnReason']?.toString(),
      returnNote: json['returnNote']?.toString(),
      returnImages: json['returnImages']?.toString(),
      bankInfo: json['bankInfo']?.toString(),
      returnRejectReason: json['returnRejectReason']?.toString(),
      returnRequestedAt: json['returnRequestedAt']?.toString(),
      refundedAt: json['refundedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      items: list,
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PAYMENT_PENDING':
        return 'Chờ thanh toán';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'SHIPPING':
        return 'Đang giao hàng';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'RETURN_REQUESTED':
        return 'Chờ duyệt đổi trả';
      case 'RETURN_APPROVED':
        return 'Đã duyệt đổi trả';
      case 'RETURN_REJECTED':
        return 'Từ chối đổi trả';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'COD':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'ONLINE_MOCK':
        return 'Thanh toán trực tuyến (Sandbox)';
      default:
        return paymentMethod;
    }
  }

  bool get canCancel => status == 'PENDING' || status == 'PAYMENT_PENDING';
  bool get isCompleted => status == 'COMPLETED';
  bool get canExportInvoice => status == 'COMPLETED';

  bool get canRequestReturn {
    if (status != 'COMPLETED') return false;
    if (returnReason != null && returnReason!.isNotEmpty) return false;
    final timeStr = completedAt ?? createdAt;
    if (timeStr == null || timeStr.isEmpty) return true;
    try {
      final date = DateTime.parse(timeStr);
      return DateTime.now().difference(date).inDays <= 7;
    } catch (_) {
      return true;
    }
  }

  bool get isReturnExpired {
    if (status != 'COMPLETED') return false;
    if (isReturnFlow) return false;
    final timeStr = completedAt ?? createdAt;
    if (timeStr == null || timeStr.isEmpty) return false;
    try {
      final date = DateTime.parse(timeStr);
      return DateTime.now().difference(date).inDays > 7;
    } catch (_) {
      return false;
    }
  }

  int get remainingReturnDays {
    final timeStr = completedAt ?? createdAt;
    if (timeStr == null || timeStr.isEmpty) return 7;
    try {
      final date = DateTime.parse(timeStr);
      final diff = 7 - DateTime.now().difference(date).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 7;
    }
  }

  bool get isReturnRequested => status == 'RETURN_REQUESTED';
  bool get isReturnApproved => status == 'RETURN_APPROVED';
  bool get isReturnRejected => status == 'RETURN_REJECTED';
  bool get isRefunded => status == 'REFUNDED';
  bool get isReturnFlow => isReturnRequested || isReturnApproved || isReturnRejected || isRefunded;
}
