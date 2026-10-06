import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'techstore_user';

  static Future<AuthResponseModel> login(String email, String password) async {
    final cleanUser = email.trim();
    final data = await ApiService.post(ApiConfig.authLogin, body: {
      'username': cleanUser,
      'email': cleanUser,
      'password': password,
    });

    final authResponse = AuthResponseModel.fromJson(data);
    await ApiService.saveToken(authResponse.token);
    await saveUser(authResponse.user);
    return authResponse;
  }

  static Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final data = await ApiService.post(ApiConfig.authGoogle, body: {
      'idToken': idToken,
    });

    final authResponse = AuthResponseModel.fromJson(data);
    await ApiService.saveToken(authResponse.token);
    await saveUser(authResponse.user);
    return authResponse;
  }

  static Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final body = {
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    final data = await ApiService.post(ApiConfig.authRegister, body: body);
    final authResponse = AuthResponseModel.fromJson(data);
    if (authResponse.token.isNotEmpty) {
      await ApiService.saveToken(authResponse.token);
      await saveUser(authResponse.user);
    }
    return authResponse;
  }

  static Future<AuthResponseModel> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final data = await ApiService.post(ApiConfig.authVerifyEmail, body: {
      'email': email.trim(),
      'otp': otp.trim(),
    });
    final authResponse = AuthResponseModel.fromJson(data);
    if (authResponse.token.isNotEmpty) {
      await ApiService.saveToken(authResponse.token);
      await saveUser(authResponse.user);
    }
    return authResponse;
  }

  static Future<void> resendOtp({
    required String email,
    required String type,
  }) async {
    await ApiService.post(ApiConfig.authResendOtp, body: {
      'email': email.trim(),
      'type': type,
    });
  }

  static Future<void> forgotPasswordOtp(String email) async {
    await ApiService.post(ApiConfig.authForgotPasswordOtp, body: {
      'email': email.trim(),
    });
  }

  static Future<void> resetPasswordOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ApiService.post(ApiConfig.authResetPasswordOtp, body: {
      'email': email.trim(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  static Future<UserModel> getMe() async {
    final data = await ApiService.get(ApiConfig.authMe);
    final user = UserModel.fromJson(data);
    await saveUser(user);
    return user;
  }

  static Future<UserModel> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
      if (currentPassword != null && currentPassword.isNotEmpty) 'currentPassword': currentPassword,
      if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
    };

    final data = await ApiService.put(ApiConfig.authProfile, body: body);
    final updatedUser = UserModel.fromJson(data);
    await saveUser(updatedUser);
    return updatedUser;
  }

  static Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final data = await ApiService.postMultipart(
      ApiConfig.uploadsImage,
      fileField: 'file',
      fileBytes: bytes,
      fileName: fileName,
    );
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    throw ApiException('Không nhận được URL ảnh phản hồi từ server');
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await ApiService.removeToken();
  }
}
