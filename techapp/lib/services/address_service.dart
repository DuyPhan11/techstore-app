import '../config/api_config.dart';
import '../models/address_model.dart';
import 'api_service.dart';

class AddressService {
  /// Lấy danh sách địa chỉ của người dùng
  static Future<List<AddressModel>> getAddresses() async {
    final res = await ApiService.get(ApiConfig.addresses);
    if (res is List) {
      return res.map((item) => AddressModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy địa chỉ mặc định
  static Future<AddressModel?> getDefaultAddress() async {
    final res = await ApiService.get('${ApiConfig.addresses}/default');
    if (res is Map<String, dynamic>) {
      return AddressModel.fromJson(res);
    }
    return null;
  }

  /// Thêm địa chỉ mới
  static Future<AddressModel> createAddress(Map<String, dynamic> addressData) async {
    final res = await ApiService.post(ApiConfig.addresses, body: addressData);
    return AddressModel.fromJson(res as Map<String, dynamic>);
  }

  /// Cập nhật địa chỉ
  static Future<AddressModel> updateAddress(int id, Map<String, dynamic> addressData) async {
    final res = await ApiService.put('${ApiConfig.addresses}/$id', body: addressData);
    return AddressModel.fromJson(res as Map<String, dynamic>);
  }

  /// Xóa địa chỉ
  static Future<void> deleteAddress(int id) async {
    await ApiService.delete('${ApiConfig.addresses}/$id');
  }

  /// Đặt làm địa chỉ mặc định
  static Future<AddressModel> setDefaultAddress(int id) async {
    final res = await ApiService.patch('${ApiConfig.addresses}/$id/default', body: {});
    return AddressModel.fromJson(res as Map<String, dynamic>);
  }
}
