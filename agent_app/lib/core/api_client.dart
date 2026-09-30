import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return 'https://sharp-mails-draw.loca.lt/api';
  }

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path, () {
      return http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    });
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, () {
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) {
    return _send('PATCH', path, () {
      return http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send();
      return _handle(method, path, response);
    } on ApiException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[ApiClient] $method $baseUrl$path');
      debugPrint('  نوع الخطأ: ${error.runtimeType}');
      debugPrint('  التفاصيل: $error');
      debugPrint('  $stackTrace');
      throw ApiException(
        'تعذر الاتصال بالخادم — تأكد من تشغيل الخادم واتصال الشبكة',
        0,
      );
    }
  }

  Map<String, dynamic> _handle(String method, String path, http.Response response) {
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;

    if (data == null) {
      debugPrint(
        '[ApiClient] $method $path → HTTP ${response.statusCode} (استجابة غير JSON): '
        '${response.body}',
      );
      throw ApiException(
        'استجابة غير صالحة من الخادم (${response.statusCode})',
        response.statusCode,
      );
    }

    if (!ok || data['status'] == 'error') {
      final message = data['message']?.toString() ?? 'حدث خطأ (${response.statusCode})';
      debugPrint('[ApiClient] $method $path → HTTP ${response.statusCode}: $message');
      throw ApiException(message, response.statusCode);
    }

    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
