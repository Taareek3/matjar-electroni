class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.addressLine,
    required this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String addressLine;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      country: json['country'] as String? ?? 'السعودية',
      city: json['city'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'country': country,
      'city': city,
      'addressLine': addressLine,
      'role': role,
    };
  }
}
