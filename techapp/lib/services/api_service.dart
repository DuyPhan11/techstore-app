import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static const String _tokenKey = 'techstore_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _getHeaders({bool hasBody = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (hasBody) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String cleanEndpoint = endpoint;
    if (!cleanEndpoint.startsWith('/')) {
      cleanEndpoint = '/$cleanEndpoint';
    }
    final fullUrl = '${ApiConfig.baseUrl}$cleanEndpoint';
    final uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          sanitizedParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...sanitizedParams,
      });
    }

    return uri;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      // Body is not json
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic>) {
        if (jsonBody.containsKey('success')) {
          if (jsonBody['success'] == true) {
            return jsonBody['data'];
          } else {
            throw ApiException(
              jsonBody['message'] ?? 'Thao tác không thành công',
              statusCode: response.statusCode,
              errors: jsonBody['errors'],
            );
          }
        }
        return jsonBody;
      }
      return jsonBody;
    }

    // Error handling
    String errorMessage = 'Lỗi kết nối máy chủ (${response.statusCode})';
    Map<String, dynamic>? errors;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['message'] != null && jsonBody['message'].toString().isNotEmpty) {
        errorMessage = jsonBody['message'];
      }
      if (jsonBody['errors'] != null && jsonBody['errors'] is Map) {
        errors = jsonBody['errors'];
      }
    }

    if (response.statusCode == 401) {
      removeToken();
      throw ApiException(errorMessage.isNotEmpty ? errorMessage : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.', statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Bạn không có quyền thực hiện hành động này.', statusCode: 403);
    } else if (response.statusCode == 404) {
      throw ApiException(errorMessage.isNotEmpty ? errorMessage : 'Không tìm thấy tài nguyên yêu cầu.', statusCode: 404);
    }

    throw ApiException(errorMessage, statusCode: response.statusCode, errors: errors);
  }

  // GET
  static Future<dynamic> get(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(hasBody: false);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Hãy đảm bảo backend Spring Boot đang chạy.');
    } on http.ClientException {
      throw ApiException('Lỗi kết nối mạng, vui lòng kiểm tra kết nối internet.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // POST
  static Future<dynamic> post(String endpoint, {dynamic body, Map<String, dynamic>? params}) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(hasBody: true);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Hãy đảm bảo backend Spring Boot đang chạy.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // PUT
  static Future<dynamic> put(String endpoint, {dynamic body, Map<String, dynamic>? params}) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(hasBody: true);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // PATCH
  static Future<dynamic> patch(String endpoint, {dynamic body, Map<String, dynamic>? params}) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(hasBody: true);
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // DELETE
  static Future<dynamic> delete(String endpoint, {dynamic body, Map<String, dynamic>? params}) async {
    try {
      final uri = _buildUri(endpoint, params);
      final headers = await _getHeaders(hasBody: body != null);
      final response = await http.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // MULTIPART POST (Upload files/images)
  static Future<dynamic> postMultipart(
    String endpoint, {
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
