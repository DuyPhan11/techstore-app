class BestSellingProductModel {
  final int productId;
  final String productName;
  final String? productSku;
  final String? productImage;
  final int quantitySold;
  final double totalRevenue;

  BestSellingProductModel({
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImage,
    required this.quantitySold,
    required this.totalRevenue,
  });

  factory BestSellingProductModel.fromJson(Map<String, dynamic> json) {
    return BestSellingProductModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      productSku: json['productSku']?.toString(),
      productImage: json['productImage']?.toString(),
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryRevenueModel {
  final int categoryId;
  final String categoryName;
  final double revenue;
  double percentage;

  CategoryRevenueModel({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.percentage,
  });

  factory CategoryRevenueModel.fromJson(Map<String, dynamic> json) {
    return CategoryRevenueModel(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RevenueTimePointModel {
  final String date;
  final double revenue;
  final int orderCount;

  RevenueTimePointModel({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueTimePointModel.fromJson(Map<String, dynamic> json) {
    return RevenueTimePointModel(
      date: json['date']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardSummaryModel {
  final int totalOrders;
  final double totalRevenue;
  final int completedOrders;
  final int cancelledOrders;
  final int newCustomers;
  final int totalCustomers;
  final String? startDate;
  final String? endDate;
  final List<RevenueTimePointModel> revenueOverTime;
  final List<CategoryRevenueModel> revenueByCategory;
  final List<BestSellingProductModel> bestSellingProducts;

  DashboardSummaryModel({
    required this.totalOrders,
    required this.totalRevenue,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.newCustomers,
    required this.totalCustomers,
    this.startDate,
    this.endDate,
    this.revenueOverTime = const [],
    required this.revenueByCategory,
    required this.bestSellingProducts,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    List<CategoryRevenueModel> cats = [];
    if (json['revenueByCategory'] != null && json['revenueByCategory'] is List) {
      cats = (json['revenueByCategory'] as List)
          .map((e) => CategoryRevenueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Auto-calculate percentage if 0.0
    double totalCatRev = cats.fold(0.0, (sum, c) => sum + c.revenue);
    if (totalCatRev > 0) {
      for (var c in cats) {
        if (c.percentage <= 0) {
          c.percentage = (c.revenue / totalCatRev) * 100;
        }
      }
    }

    List<RevenueTimePointModel> timeline = [];
    if (json['revenueOverTime'] != null && json['revenueOverTime'] is List) {
      timeline = (json['revenueOverTime'] as List)
          .map((e) => RevenueTimePointModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<BestSellingProductModel> best = [];
    if (json['bestSellingProducts'] != null && json['bestSellingProducts'] is List) {
      best = (json['bestSellingProducts'] as List)
          .map((e) => BestSellingProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DashboardSummaryModel(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      newCustomers: (json['newCustomers'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      revenueOverTime: timeline,
      revenueByCategory: cats,
      bestSellingProducts: best,
    );
  }
}
