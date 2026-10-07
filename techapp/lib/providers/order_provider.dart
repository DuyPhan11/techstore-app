import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderItemModel> get purchasedProducts {
    final Map<int, OrderItemModel> uniqueProducts = {};
    for (final order in _orders) {
      if (order.status != 'CANCELLED') {
        for (final item in order.items) {
          if (item.productId > 0 && !uniqueProducts.containsKey(item.productId)) {
            uniqueProducts[item.productId] = item;
          }
        }
      }
    }
    return uniqueProducts.values.toList();
  }

  Future<void> fetchOrders({bool silent = false}) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final res = await OrderService.getMyOrders(page: 0, size: 50);
      _orders = res.content;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final updatedOrder = await OrderService.cancelOrder(orderId, reason);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
      } else {
        await fetchOrders(silent: true);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearOrders() {
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  List<OrderModel> filterOrders(int tabIndex) {
    if (tabIndex == 0) return _orders;
    if (tabIndex == 1) {
      return _orders.where((o) => o.status == 'PENDING' || o.status == 'PAYMENT_PENDING').toList();
    }
    if (tabIndex == 2) {
      return _orders.where((o) => o.status == 'CONFIRMED').toList();
    }
    if (tabIndex == 3) {
      return _orders.where((o) => o.status == 'SHIPPING').toList();
    }
    if (tabIndex == 4) {
      return _orders.where((o) => o.status == 'COMPLETED').toList();
    }
    if (tabIndex == 5) {
      return _orders.where((o) => o.isReturnFlow).toList();
    }
    if (tabIndex == 6) {
      return _orders.where((o) => o.status == 'CANCELLED').toList();
    }
    return _orders;
  }
}
