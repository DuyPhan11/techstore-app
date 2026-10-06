class CouponValidationModel {
  final bool valid;
  final String? message;
  final String? couponCode;
  final String? discountType;
  final double? discountValue;
  final double discountAmount;
  final double finalAmount;

  CouponValidationModel({
    required this.valid,
    this.message,
    this.couponCode,
    this.discountType,
    this.discountValue,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory CouponValidationModel.fromJson(Map<String, dynamic> json) {
    return CouponValidationModel(
      valid: json['valid'] ?? false,
      message: json['message'],
      couponCode: json['couponCode'],
      discountType: json['discountType'],
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CouponModel {
  final int id;
  final String code;
  final String discountType; // 'PERCENTAGE' or 'FIXED_AMOUNT'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isExpired;
  final bool isFullyUsed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    required this.usageLimit,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isExpired,
    required this.isFullyUsed,
    this.createdAt,
    this.updatedAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CouponModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      usageLimit: json['usageLimit'] as int? ?? 0,
      usedCount: json['usedCount'] as int? ?? 0,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      isActive: json['isActive'] as bool? ?? true,
      isExpired: json['isExpired'] as bool? ?? false,
      isFullyUsed: json['isFullyUsed'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  bool get isAvailable {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        usedCount < usageLimit;
  }

  double get remainingPercent {
    if (usageLimit <= 0) return 0.0;
    final remaining = usageLimit - usedCount;
    return (remaining / usageLimit).clamp(0.0, 1.0);
  }
}

class AdminCouponStatsModel {
  final int totalCoupons;
  final int activeCoupons;
  final int expiredCoupons;
  final int totalUsed;

  AdminCouponStatsModel({
    required this.totalCoupons,
    required this.activeCoupons,
    required this.expiredCoupons,
    required this.totalUsed,
  });

  factory AdminCouponStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminCouponStatsModel(
      totalCoupons: (json['totalCoupons'] as num?)?.toInt() ?? 0,
      activeCoupons: (json['activeCoupons'] as num?)?.toInt() ?? 0,
      expiredCoupons: (json['expiredCoupons'] as num?)?.toInt() ?? 0,
      totalUsed: (json['totalUsed'] as num?)?.toInt() ?? 0,
    );
  }
}
