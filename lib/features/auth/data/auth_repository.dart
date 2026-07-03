import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import '../../../core/env.dart';
import '../../../core/config/app_config.dart';
import '../../../core/demo/local_account_store.dart';

// Simple record for register result (user + optional OTP code)
final class RegisterResult {
  const RegisterResult(this.user, this.otpCode);
  final UserModel user;
  final String? otpCode;
}

/// Clean, user-facing auth failure (no "Exception: " prefix leaking into UI).
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final LocalAccountStore _accountStore = LocalAccountStore();

  // email(lowercase) -> pending OTP code, demo mode only (in-memory).
  final Map<String, String> _pendingOtps = {};

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_json';
  static const _savedEmailKey = 'saved_email';
  static const _savedPassKey = 'saved_credential_password';

  // ---- Auth ----------------------------------------------------------------

  Future<UserModel> login(String email, String password) async {
    if (AppConfig.demoMode) {
      await _accountStore.ensureSeeded();
      final account = await _accountStore.verify(email, password);
      if (account == null) {
        throw AuthFailure('Incorrect email or password.');
      }
      final user = _userFromAccount(account);
      await _persist(user);
      return user;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(response.data!);
    await _persist(user);
    return user;
  }

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'PATIENT',
  }) async {
    if (AppConfig.demoMode) {
      await _accountStore.ensureSeeded();
      final LocalAccount account;
      try {
        account = await _accountStore.create(
          fullName: fullName,
          email: email,
          password: password,
          role: role,
          phone: phone,
        );
      } on StateError catch (e) {
        throw AuthFailure(e.message);
      }
      final code = _genOtp();
      _pendingOtps[email.trim().toLowerCase()] = code;
      // Don't persist yet — wait for OTP verification
      return RegisterResult(_userFromAccount(account), code);
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
      },
    );
    final data = response.data!;
    final user = UserModel.fromJson(data);
    // Don't persist yet — wait for OTP verification
    return RegisterResult(user, data['otpCode'] as String?);
  }

  Future<UserModel> verifyOtp(String email, String code) async {
    if (AppConfig.demoMode) {
      final key = email.trim().toLowerCase();
      final expected = _pendingOtps[key];
      if (expected == null || expected != code) {
        throw AuthFailure('Incorrect code. Please try again.');
      }
      final account = await _accountStore.findByEmail(email);
      if (account == null) throw AuthFailure('Account not found.');
      _pendingOtps.remove(key);
      final user = _userFromAccount(account);
      await _persist(user);
      return user;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/verify-otp',
      data: {'email': email, 'code': code},
    );
    final user = UserModel.fromJson(response.data!);
    await _persist(user);
    return user;
  }

  Future<String?> resendOtp(String email) async {
    if (AppConfig.demoMode) {
      final code = _genOtp();
      _pendingOtps[email.trim().toLowerCase()] = code;
      return code;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/resend-otp',
      data: {'email': email},
    );
    return response.data?['otpCode'] as String?;
  }

  UserModel _userFromAccount(LocalAccount a) => UserModel.fromJson({
        'userId': a.userId,
        'fullName': a.fullName,
        'email': a.email,
        'role': a.role,
        'token': 'demo-${a.userId}-${DateTime.now().millisecondsSinceEpoch}',
      });

  String _genOtp() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // ---- Saved credentials (auto-fill) ---------------------------------------

  Future<void> saveCredentials(String email, String password) async {
    await Future.wait([
      _storage.write(key: _savedEmailKey, value: email),
      _storage.write(key: _savedPassKey, value: password),
    ]);
  }

  Future<(String, String)?> getSavedCredentials() async {
    final email = await _storage.read(key: _savedEmailKey);
    final pass = await _storage.read(key: _savedPassKey);
    if (email == null || pass == null) return null;
    return (email, pass);
  }

  // ---- Persistence ---------------------------------------------------------

  Future<UserModel?> getSavedUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
      // Note: we intentionally keep saved_email and saved_credential_password
      // so the login page can pre-fill them even after logout.
    ]);
  }

  /// Permanently removes the current account (demo mode: local device only)
  /// and clears the session.
  Future<void> deleteAccount(String email) async {
    if (AppConfig.demoMode) {
      await _accountStore.delete(email);
    }
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _savedEmailKey),
      _storage.delete(key: _savedPassKey),
    ]);
  }

  Future<void> _persist(UserModel user) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: user.token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }
}