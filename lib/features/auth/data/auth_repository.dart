import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import '../../../core/env.dart';

// Simple record for register result (user + optional OTP code)
final class RegisterResult {
  const RegisterResult(this.user, this.otpCode);
  final UserModel user;
  final String? otpCode;
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

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_json';
  static const _savedEmailKey = 'saved_email';
  static const _savedPassKey = 'saved_credential_password';

  // ---- Auth ----------------------------------------------------------------

  Future<UserModel> login(String email, String password) async {
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/verify-otp',
      data: {'email': email, 'code': code},
    );
    final user = UserModel.fromJson(response.data!);
    await _persist(user);
    return user;
  }

  Future<String?> resendOtp(String email) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/resend-otp',
      data: {'email': email},
    );
    return response.data?['otpCode'] as String?;
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

  Future<void> _persist(UserModel user) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: user.token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }
}