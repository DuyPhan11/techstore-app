class ReviewModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double? unitPrice;
  final int? orderId;
  final String? orderCode;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String comment;
  final String? createdAt;
  final bool isOwner;
  final String? adminReply;
  final String? adminReplyAt;

  ReviewModel({
    required this.id,
    this.productId = 0,
    this.productName = '',
    this.productImage,
    this.unitPrice,
    this.orderId,
    this.orderCode,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.isOwner = false,
    this.adminReply,
    this.adminReplyAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      orderId: (json['orderId'] as num?)?.toInt(),
      orderCode: json['orderCode']?.toString(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userName: json['userName']?.toString() ?? 'Khách hàng',
      userAvatar: json['userAvatar']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      isOwner: json['isOwner'] == true,
      adminReply: json['adminReply']?.toString(),
      adminReplyAt: json['adminReplyAt']?.toString(),
    );
  }
}

class AdminReviewStatsModel {
  final double averageRating;
  final int totalReviews;
  final int count5Star;
  final int count4Star;
  final int count3Star;
  final int count2Star;
  final int count1Star;

  AdminReviewStatsModel({
    required this.averageRating,
    required this.totalReviews,
    required this.count5Star,
    required this.count4Star,
    required this.count3Star,
    required this.count2Star,
    required this.count1Star,
  });

  factory AdminReviewStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewStatsModel(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      count5Star: (json['count5Star'] as num?)?.toInt() ?? 0,
      count4Star: (json['count4Star'] as num?)?.toInt() ?? 0,
      count3Star: (json['count3Star'] as num?)?.toInt() ?? 0,
      count2Star: (json['count2Star'] as num?)?.toInt() ?? 0,
      count1Star: (json['count1Star'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingReviewItemModel {
  final int orderId;
  final String orderCode;
  final String? orderDate;
  final int productId;
  final String productName;
  final String? productSku;
  final String? productImage;
  final double unitPrice;
  final int quantity;

  PendingReviewItemModel({
    required this.orderId,
    required this.orderCode,
    this.orderDate,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

  factory PendingReviewItemModel.fromJson(Map<String, dynamic> json) {
    return PendingReviewItemModel(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode']?.toString() ?? '',
      orderDate: json['orderDate']?.toString(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      productSku: json['productSku']?.toString(),
      productImage: json['productImage']?.toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class ProductReviewSummaryModel {
  final double averageRating;
  final int totalReviews;
  final List<ReviewModel> reviews;

  ProductReviewSummaryModel({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  factory ProductReviewSummaryModel.fromJson(dynamic json) {
    if (json == null) {
      return ProductReviewSummaryModel(averageRating: 0.0, totalReviews: 0, reviews: []);
    }

    if (json is List) {
      final list = json.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      final double avg = list.isEmpty
          ? 0.0
          : (list.map((r) => r.rating).reduce((a, b) => a + b) / list.length);
      return ProductReviewSummaryModel(
        averageRating: avg,
        totalReviews: list.length,
        reviews: list,
      );
    }

    if (json is! Map<String, dynamic>) {
      return ProductReviewSummaryModel(averageRating: 0.0, totalReviews: 0, reviews: []);
    }

    List<ReviewModel> list = [];
    int totalElements = 0;

    // Check if json['reviews'] is a Spring Page map (content: [...], totalElements: ...)
    if (json['reviews'] != null) {
      if (json['reviews'] is Map<String, dynamic>) {
        final pageMap = json['reviews'] as Map<String, dynamic>;
        totalElements = (pageMap['totalElements'] as num?)?.toInt() ?? 0;
        if (pageMap['content'] is List) {
          list = (pageMap['content'] as List)
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (json['reviews'] is List) {
        list = (json['reviews'] as List)
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
        totalElements = list.length;
      }
    } else if (json['content'] != null && json['content'] is List) {
      list = (json['content'] as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
      totalElements = (json['totalElements'] as num?)?.toInt() ?? list.length;
    }

    final double avg = (json['averageRating'] as num?)?.toDouble() ??
        (list.isNotEmpty ? (list.map((r) => r.rating).reduce((a, b) => a + b) / list.length) : 0.0);

    final int total = (json['totalReviews'] as num?)?.toInt() ??
        (totalElements > 0 ? totalElements : list.length);

    return ProductReviewSummaryModel(
      averageRating: avg,
      totalReviews: total,
      reviews: list,
    );
  }
}
