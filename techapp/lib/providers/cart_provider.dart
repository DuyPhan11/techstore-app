import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartModel _cart = CartModel.empty();
  bool _isLoading = false;
  String? _errorMessage;

  CartModel get cart => _cart;
  int get totalItems => _cart.totalItems;
  double get totalPrice => _cart.totalPrice;
  List<CartItemModel> get items => _cart.items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCart() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _cart = CartModel.empty();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cart = await CartService.getCart();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int productId, {int quantity = 1}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _cart = await CartService.addToCart(productId, quantity);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    try {
      if (quantity <= 0) {
        return await removeItem(productId);
      }
      _cart = await CartService.updateQuantity(productId, quantity);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int productId) async {
    try {
      _cart = await CartService.removeItem(productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> clearCart() async {
    try {
      await CartService.clearCart();
      _cart = CartModel.empty();
      notifyListeners();
    } catch (_) {}
  }
}
