class AddressModel {
  final int id;
  final String recipientName;
  final String phone;
  final String streetAddress;
  final String? ward;
  final String? district;
  final String city;
  final String fullAddress;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.streetAddress,
    this.ward,
    this.district,
    required this.city,
    required this.fullAddress,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      recipientName: json['recipientName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String? ?? '',
      fullAddress: json['fullAddress'] as String? ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipientName': recipientName,
      'phone': phone,
      'streetAddress': streetAddress,
      if (ward != null && ward!.isNotEmpty) 'ward': ward,
      if (district != null && district!.isNotEmpty) 'district': district,
      'city': city,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    int? id,
    String? recipientName,
    String? phone,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    String? fullAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      streetAddress: streetAddress ?? this.streetAddress,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
