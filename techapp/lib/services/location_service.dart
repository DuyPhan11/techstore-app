import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PlaceResult {
  final String displayName;
  final String streetAddress;
  final String ward;
  final String district;
  final String city;
  final double lat;
  final double lon;

  PlaceResult({
    required this.displayName,
    required this.streetAddress,
    required this.ward,
    required this.district,
    required this.city,
    required this.lat,
    required this.lon,
  });
}

class LocationService {
  /// Request GPS permission and return current Position
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị GPS đang tắt. Vui lòng bật GPS trên thiết bị.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí đã bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Reverse geocode GPS coordinates to real address details
  static Future<PlaceResult> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&accept-language=vi',
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'TechStoreApp/1.0 (contact: keduytech@gmail.com)',
    });

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      final houseNumber = address['house_number'] as String? ?? '';
      final road = address['road'] as String? ?? address['street'] as String? ?? '';
      final street = [houseNumber, road].where((s) => s.isNotEmpty).join(' ');

      final ward = address['suburb'] as String? ??
          address['quarter'] as String? ??
          address['neighbourhood'] as String? ??
          address['village'] as String? ??
          '';

      final district = address['city_district'] as String? ??
          address['district'] as String? ??
          address['county'] as String? ??
          '';

      final city = address['city'] as String? ??
          address['province'] as String? ??
          address['state'] as String? ??
          '';

      return PlaceResult(
        displayName: data['display_name'] as String? ?? '',
        streetAddress: street.isNotEmpty ? street : (data['name'] as String? ?? ''),
        ward: ward,
        district: district,
        city: city,
        lat: lat,
        lon: lon,
      );
    } else {
      throw Exception('Không thể giải mã địa chỉ từ tọa độ GPS.');
    }
  }

  /// Search real physical places in Vietnam
  static Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    final encoded = Uri.encodeComponent(query.trim());
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encoded&countrycodes=vn&format=json&addressdetails=1&limit=8&accept-language=vi',
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'TechStoreApp/1.0 (contact: keduytech@gmail.com)',
    });

    if (response.statusCode == 200) {
      final list = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) {
        final address = item['address'] as Map<String, dynamic>? ?? {};

        final houseNumber = address['house_number'] as String? ?? '';
        final road = address['road'] as String? ?? address['street'] as String? ?? '';
        final street = [houseNumber, road].where((s) => s.isNotEmpty).join(' ');

        final ward = address['suburb'] as String? ??
            address['quarter'] as String? ??
            address['neighbourhood'] as String? ??
            address['village'] as String? ??
            '';

        final district = address['city_district'] as String? ??
            address['district'] as String? ??
            address['county'] as String? ??
            '';

        final city = address['city'] as String? ??
            address['province'] as String? ??
            address['state'] as String? ??
            '';

        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

        return PlaceResult(
          displayName: item['display_name'] as String? ?? '',
          streetAddress: street.isNotEmpty ? street : (item['name'] as String? ?? ''),
          ward: ward,
          district: district,
          city: city,
          lat: lat,
          lon: lon,
        );
      }).toList();
    }
    return [];
  }
}
