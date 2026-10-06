class BranchModel {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? status;

  BranchModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.status,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      status: json['status'],
    );
  }
}
