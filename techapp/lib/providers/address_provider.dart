import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';
import '../services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> fetchAddresses() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _addresses = [];
      _selectedAddress = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final list = await AddressService.getAddresses();
      _addresses = list;
      if (_selectedAddress != null) {
        final match = list.where((a) => a.id == _selectedAddress!.id).firstOrNull;
        _selectedAddress = match ?? defaultAddress;
      } else {
        _selectedAddress = defaultAddress;
      }
    } catch (_) {
      // Backend error or offline
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AddressModel> createAddress(Map<String, dynamic> data) async {
    final newAddress = await AddressService.createAddress(data);
    await fetchAddresses();
    return newAddress;
  }

  Future<AddressModel> updateAddress(int id, Map<String, dynamic> data) async {
    final updated = await AddressService.updateAddress(id, data);
    await fetchAddresses();
    return updated;
  }

  Future<void> deleteAddress(int id) async {
    await AddressService.deleteAddress(id);
    if (_selectedAddress?.id == id) {
      _selectedAddress = null;
    }
    await fetchAddresses();
  }

  Future<void> setDefaultAddress(int id) async {
    await AddressService.setDefaultAddress(id);
    await fetchAddresses();
  }

  void clearOnLogout() {
    _addresses = [];
    _selectedAddress = null;
    _isLoading = false;
    notifyListeners();
  }
}
