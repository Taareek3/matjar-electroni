class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final String? vendorId;
  final String? restaurantName;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    this.vendorId,
    this.restaurantName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? '',
      vendorId: json['vendorId']?.toString(),
      restaurantName: json['restaurantName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'vendorId': vendorId,
      'restaurantName': restaurantName,
    };
  }

  static const List<String> vendorRoles = [
    'VENDOR',
    'KITCHEN_STAFF',
  ];

  bool get isVendorRole => vendorRoles.contains(role);
}
