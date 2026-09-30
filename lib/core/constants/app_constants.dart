class AppConstants {
  AppConstants._();

  static const String appName = 'مطعمي';

  static const String _envApiBaseUrl = String.fromEnvironment('API_URL');

  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return 'https://sharp-mails-draw.loca.lt/api';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const Duration apiTimeout = Duration(seconds: 10);

  static const double deliveryFee = 2.99;
  static const String branchName = 'الفرع الرئيسي';
  static const String branchAddress = 'شارع التحرير - وسط المدينة';
  static const int deliveryEstimateMinutes = 40;
  static const int pickupEstimateMinutes = 15;
  static const String restaurantPhone = '0912345678';
  static const String supportPhone = '1999';
}
