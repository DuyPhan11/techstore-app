class CartItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productSlug;
  final String? productSku;
  final String? primaryImageUrl;
  final double unitPrice;
  int quantity;
  final double subtotal;
  final int availableStock;
  final bool inStock;
  final bool isActive;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.productSku,
    this.primaryImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.availableStock,
    required this.inStock,
    required this.isActive,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      productSlug: json['productSlug'],
      productSku: json['productSku'],
      primaryImageUrl: json['primaryImageUrl'],
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      availableStock: json['availableStock'] ?? 0,
      inStock: json['inStock'] ?? true,
      isActive: json['isActive'] ?? true,
    );
  }
}

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final int totalItems;
  final int itemCount;
  final double totalPrice;

  CartModel({
    required this.id,
    this.items = const [],
    required this.totalItems,
    required this.itemCount,
    required this.totalPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CartModel(
      id: json['id'] ?? 0,
      items: list,
      totalItems: json['totalItems'] ?? 0,
      itemCount: json['itemCount'] ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory CartModel.empty() {
    return CartModel(id: 0, items: [], totalItems: 0, itemCount: 0, totalPrice: 0.0);
  }
}
