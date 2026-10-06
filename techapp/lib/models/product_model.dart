import 'brand_model.dart';
import 'category_model.dart';

class ProductImageModel {
  final int id;
  final String imageUrl;
  final bool isPrimary;
  final int displayOrder;

  ProductImageModel({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    required this.displayOrder,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}

class BranchStockModel {
  final int branchId;
  final String branchName;
  final String? branchAddress;
  final int quantity;

  BranchStockModel({
    required this.branchId,
    required this.branchName,
    this.branchAddress,
    required this.quantity,
  });

  factory BranchStockModel.fromJson(Map<String, dynamic> json) {
    return BranchStockModel(
      branchId: json['branchId'] is num ? (json['branchId'] as num).toInt() : (int.tryParse('${json['branchId']}') ?? 0),
      branchName: json['branchName']?.toString() ?? '',
      branchAddress: json['branchAddress']?.toString(),
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : (int.tryParse('${json['quantity']}') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'quantity': quantity,
    };
  }
}

class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final double price;
  final double? costPrice;
  final String? description;
  final String? specifications;
  final String status;
  final CategoryModel? category;
  final BrandModel? brand;
  final String? primaryImageUrl;
  final List<ProductImageModel> images;
  final int totalStock;
  final int warrantyMonths;
  final List<BranchStockModel> branchInventories;
  final String? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    required this.price,
    this.costPrice,
    this.description,
    this.specifications,
    required this.status,
    this.category,
    this.brand,
    this.primaryImageUrl,
    this.images = const [],
    required this.totalStock,
    this.warrantyMonths = 12,
    this.branchInventories = const [],
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<ProductImageModel> imgs = [];
    if (json['images'] != null && json['images'] is List) {
      imgs = (json['images'] as List)
          .map((i) => ProductImageModel.fromJson(i))
          .toList();
    }

    String? primaryImg = json['primaryImageUrl'];
    if (primaryImg == null && imgs.isNotEmpty) {
      final primary = imgs.firstWhere((i) => i.isPrimary, orElse: () => imgs.first);
      primaryImg = primary.imageUrl;
    }

    List<BranchStockModel> branches = [];
    if (json['branchInventories'] != null && json['branchInventories'] is List) {
      branches = (json['branchInventories'] as List)
          .map((b) => BranchStockModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sku: json['sku'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      description: json['description'],
      specifications: json['specifications'],
      status: json['status'] ?? 'ACTIVE',
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      brand: json['brand'] != null ? BrandModel.fromJson(json['brand']) : null,
      primaryImageUrl: primaryImg,
      images: imgs,
      totalStock: json['totalStock'] ?? 0,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 12,
      branchInventories: branches,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'sku': sku,
      'price': price,
      'costPrice': costPrice,
      'description': description,
      'specifications': specifications,
      'status': status,
      'category': category != null
          ? {'id': category!.id, 'name': category!.name, 'slug': category!.slug}
          : null,
      'brand': brand != null
          ? {'id': brand!.id, 'name': brand!.name, 'slug': brand!.slug}
          : null,
      'primaryImageUrl': primaryImageUrl,
      'totalStock': totalStock,
      'branchInventories': branchInventories.map((b) => b.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  bool get isInStock => totalStock > 0;
}

class PageResult<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResult({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final list = (json['content'] as List<dynamic>?)
            ?.map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PageResult<T>(
      content: list,
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}
