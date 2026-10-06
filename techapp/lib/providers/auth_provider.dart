import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _adminMode = true;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _user?.isAdmin == true;
  bool get isStaff => _user?.isStaff == true;
  bool get isManager => isAdmin || isStaff;
  bool get adminMode => _adminMode && isManager;

  void setAdminMode(bool enabled) {
    _adminMode = enabled;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty) {
        _user = await AuthService.getCachedUser();
        // Background verify with backend
        try {
          _user = await AuthService.getMe();
        } catch (_) {
          // Token might be expired or backend unreachable
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await AuthService.login(email, password);
      _user = authResponse.user;
      if (_user?.isAdmin == true || _user?.isStaff == true) {
        _adminMode = true;
      }
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

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await AuthService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (authResponse.token.isNotEmpty) {
        _user = authResponse.user;
      }
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

  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await AuthService.verifyEmail(
        email: email,
        otp: otp,
      );
      _user = authResponse.user;
      if (_user?.isAdmin == true || _user?.isStaff == true) {
        _adminMode = true;
      }
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

  Future<bool> resendOtp({
    required String email,
    required String type,
  }) async {
    try {
      await AuthService.resendOtp(email: email, type: type);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> forgotPasswordOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.forgotPasswordOtp(email);
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

  Future<bool> resetPasswordOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.resetPasswordOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await GoogleAuthService.signInWithGoogle();
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authResponse = await AuthService.loginWithGoogle(idToken);
      _user = authResponse.user;
      if (_user?.isAdmin == true || _user?.isStaff == true) {
        _adminMode = true;
      }
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

  Future<void> logout() async {
    await AuthService.logout();
    await GoogleAuthService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      if (isAuthenticated) {
        _user = await AuthService.getMe();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
    String? currentPassword,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await AuthService.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _user = updated;
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
}
