import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/local_storage.dart';
import '../models/app_user.dart';

class AuthState {
  const AuthState({this.user, this.token});

  final AppUser? user;
  final String? token;

  bool get isLoggedIn => user != null && token != null;

  static const AuthState empty = AuthState();
}

String _messageFromDio(DioException error) {
  final dynamic data = error.response?.data;
  if (data is Map<String, dynamic> && data['message'] is String) {
    return data['message'] as String;
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return 'تعذر الاتصال بالخادم — تأكد من تشغيل السيرفر';
  }
  return 'حدث خطأ، حاول مرة أخرى';
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final String? token = await LocalStorage.getToken();
    final String? userJson = await LocalStorage.getUser();

    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        final AppUser user = AppUser.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        return AuthState(user: user, token: token);
      } catch (_) {
        await LocalStorage.clear();
      }
    }
    return AuthState.empty;
  }

  Future<void> _persist({required String token, required AppUser user}) async {
    await LocalStorage.saveToken(token);
    await LocalStorage.saveUser(jsonEncode(user.toJson()));
    state = AsyncData<AuthState>(AuthState(user: user, token: token));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final Dio dio = ref.read(apiClientProvider).dio;
    try {
      final Response<Map<String, dynamic>> response = await dio
          .post<Map<String, dynamic>>(
            '/auth/login',
            data: <String, dynamic>{'email': email, 'password': password},
          );

      final dynamic data = response.data?['data'];
      if (data is! Map<String, dynamic> || data['token'] is! String) {
        throw Exception('استجابة غير متوقعة من الخادم');
      }

      await _persist(
        token: data['token'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String city,
    required String addressLine,
    String country = 'السعودية',
  }) async {
    final Dio dio = ref.read(apiClientProvider).dio;
    try {
      final Response<Map<String, dynamic>> response = await dio
          .post<Map<String, dynamic>>(
            '/auth/register',
            data: <String, dynamic>{
              'firstName': firstName,
              'lastName': lastName,
              'name': '$firstName $lastName',
              'email': email,
              'phone': phone,
              'password': password,
              'country': country,
              'city': city,
              'addressLine': addressLine,
            },
          );

      final dynamic data = response.data?['data'];
      if (data is! Map<String, dynamic> || data['token'] is! String) {
        throw Exception('استجابة غير متوقعة من الخادم');
      }

      await _persist(
        token: data['token'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String city,
    required String addressLine,
  }) async {
    final AppUser? current = state.valueOrNull?.user;
    if (current == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final Dio dio = ref.read(apiClientProvider).dio;
    try {
      final Response<Map<String, dynamic>> response = await dio
          .put<Map<String, dynamic>>(
            '/auth/me',
            data: <String, dynamic>{
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'country': 'السعودية',
              'city': city,
              'addressLine': addressLine,
            },
          );

      final dynamic data = response.data?['data'];
      if (data is! Map<String, dynamic> || data['user'] is! Map<String, dynamic>) {
        throw Exception('استجابة غير متوقعة من الخادم');
      }

      final AppUser user = AppUser.fromJson(
        data['user'] as Map<String, dynamic>,
      );
      await LocalStorage.saveUser(jsonEncode(user.toJson()));
      state = AsyncData<AuthState>(
        AuthState(user: user, token: state.valueOrNull?.token),
      );
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  Future<void> logout() async {
    await LocalStorage.clear();
    state = const AsyncData<AuthState>(AuthState.empty);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
