import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'user_model.dart';

const _kTokenKey = 'delivery_token';
const _kUserKey = 'delivery_user';

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthState {
  final String? token;
  final UserModel? user;
  final bool isLoading;
  final bool restoring;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.restoring = false,
    this.error,
  });

  bool get isLoggedIn => token != null && user != null;

  AuthState copyWith({
    String? token,
    UserModel? user,
    bool? isLoading,
    bool? restoring,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      restoring: restoring ?? this.restoring,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState(restoring: true)) {
    _restoreSession();
  }

  final ApiClient _api;

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kTokenKey);
      final userJson = prefs.getString(_kUserKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        if (user.isDeliveryRole) {
          _api.setToken(token);
          state = AuthState(token: token, user: user);
          debugPrint('[Auth] استُعيدت الجلسة لعامل التوصيل: ${user.email}');
          return;
        }
        debugPrint('[Auth] جلسة محفوظة بدور غير عامل توصيل: ${user.role}');
      }
    } catch (error, stackTrace) {
      debugPrint('[Auth] فشل استعادة الجلسة: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
    }
    await _clearPersisted();
    state = const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      final data = response['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final userData = data?['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        debugPrint('[Auth] استجابة غير متوقعة من /auth/login: $response');
        state = state.copyWith(
          isLoading: false,
          error: 'استجابة غير متوقعة من الخادم',
        );
        return;
      }

      final user = UserModel.fromJson(userData);

      if (!user.isDeliveryRole) {
        debugPrint('[Auth] رفض الدخول — الدور ${user.role} ليس عامل توصيل');
        state = state.copyWith(
          isLoading: false,
          error: 'البريد غير مسجّل كعامل توصيل',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, token);
      await prefs.setString(_kUserKey, jsonEncode(user.toJson()));

      _api.setToken(token);
      state = AuthState(token: token, user: user);
      debugPrint('[Auth] نجح تسجيل الدخول: ${user.email} (${user.role})');
    } on ApiException catch (e) {
      debugPrint('[Auth] فشل تسجيل الدخول → HTTP ${e.statusCode}: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (error, stackTrace) {
      debugPrint('[Auth] استثناء تسجيل الدخول: ${error.runtimeType}: $error');
      debugPrint('$stackTrace');
      state = state.copyWith(isLoading: false, error: 'تعذر الاتصال بالخادم');
    }
  }

  Future<void> logout() async {
    _api.clearToken();
    await _clearPersisted();
    state = const AuthState();
  }

  Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
      await prefs.remove(_kUserKey);
    } catch (error) {
      debugPrint('[Auth] فشل مسح الجلسة المحفوظة: $error');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiProvider));
});
