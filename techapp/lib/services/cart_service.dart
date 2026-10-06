import '../config/api_config.dart';
import '../models/cart_model.dart';
import 'api_service.dart';

class CartService {
  static Future<CartModel> getCart() async {
    final data = await ApiService.get(ApiConfig.cart);
    return CartModel.fromJson(data);
  }

  static Future<CartModel> addToCart(int productId, int quantity) async {
    final data = await ApiService.post(
      ApiConfig.cartItems,
      body: {
        'productId': productId,
        'quantity': quantity,
      },
    );
    return CartModel.fromJson(data);
  }

  static Future<CartModel> updateQuantity(int productId, int quantity) async {
    final data = await ApiService.put(
      '${ApiConfig.cartItems}/$productId',
      body: {
        'quantity': quantity,
      },
    );
    return CartModel.fromJson(data);
  }

  static Future<CartModel> removeItem(int productId) async {
    final data = await ApiService.delete('${ApiConfig.cartItems}/$productId');
    return CartModel.fromJson(data);
  }

  static Future<void> clearCart() async {
    await ApiService.delete(ApiConfig.cart);
  }
}
