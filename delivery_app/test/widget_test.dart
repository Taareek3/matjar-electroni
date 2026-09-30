import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_app/core/user_model.dart';

void main() {
  test('UserModel.fromJson parses delivery role', () {
    final user = UserModel.fromJson({
      'id': '1',
      'name': 'عامل',
      'email': 'delivery@test.com',
      'phone': '0501234567',
      'role': 'AGENT',
    });

    expect(user.name, 'عامل');
    expect(user.role, 'AGENT');
    expect(user.isDeliveryRole, isTrue);
  });

  test('UserModel rejects non-delivery role', () {
    final user = UserModel.fromJson({
      'id': '2',
      'name': 'عميل',
      'email': 'c@test.com',
      'role': 'CUSTOMER',
    });

    expect(user.isDeliveryRole, isFalse);
  });
}
