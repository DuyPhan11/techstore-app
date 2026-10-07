import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String renderProductionUrl = 'https://techstore-backend-aa7t.onrender.com/api/v1';
  static const String _defaultAndroidEmulatorUrl = 'http://10.0.2.2:8080/api/v1';
  static const String _defaultLocalhostUrl = 'http://localhost:8080/api/v1';
  static const String _prefKeyBaseUrl = 'techstore_api_base_url';

  static String? _cachedBaseUrl;

  /// Returns the current Base URL configured
  static String get baseUrl {
    if (_cachedBaseUrl != null && _cachedBaseUrl!.isNotEmpty) {
      return _cachedBaseUrl!;
    }
    return defaultBaseUrl;
  }

  /// Chuyển thành true nếu muốn trỏ về Backend máy tính (Localhost / Android 10.0.2.2),
  /// Chuyển thành false nếu muốn trỏ về Backend Render trên đám mây.
  static const bool useLocalBackend = false;

  /// Tự động chọn URL mặc định dựa trên cấu hình và thiết bị
  static String get defaultBaseUrl {
    if (useLocalBackend) {
      if (kIsWeb) return _defaultLocalhostUrl;
      try {
        if (Platform.isAndroid) return _defaultAndroidEmulatorUrl;
      } catch (_) {}
      return _defaultLocalhostUrl;
    }
    return renderProductionUrl;
  }

  /// Initialize and load custom base URL from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(_prefKeyBaseUrl) ?? defaultBaseUrl;
  }

  /// Save new custom base URL
  static Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _cachedBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, cleanUrl);
  }

  /// Reset to default base URL
  static Future<void> resetToDefault() async {
    _cachedBaseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyBaseUrl);
  }

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authGoogle = '/auth/google';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';
  static const String authVerifyEmail = '/auth/verify-email';
  static const String authResendOtp = '/auth/resend-otp';
  static const String authForgotPasswordOtp = '/auth/forgot-password-otp';
  static const String authResetPasswordOtp = '/auth/reset-password-otp';
  static const String uploadsImage = '/uploads/image';
  
  static const String products = '/products';
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String branches = '/branches';
  
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  
  static const String checkout = '/checkout';
  static const String validateCoupon = '/checkout/validate-coupon';
  
  static const String ordersMy = '/orders/my';
  static const String wishlist = '/wishlist';
  static const String notifications = '/notifications';
  static const String addresses = '/addresses';
  static const String health = '/health';
  static const String coupons = '/coupons';
  static const String banners = '/banners';
  static const String aiChat = '/ai/chat';

  // Admin Endpoints
  static const String adminDashboard = '/admin/dashboard/summary';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminInventory = '/admin/inventory';
  static const String adminReviews = '/admin/reviews';
  static const String adminCoupons = '/admin/coupons';
  static const String adminCouponStats = '/admin/coupons/stats';
  static const String adminBanners = '/admin/banners';
}
