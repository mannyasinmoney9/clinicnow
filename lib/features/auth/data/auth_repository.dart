import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import '../../../core/env.dart';

class AuthRepository {
  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_json';

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(response.data!);
    await _persist(user);
    return user;
  }

  Future<UserModel> register({
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
    final user = UserModel.fromJson(response.data!);
    await _persist(user);
    return user;
  }

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
    ]);
  }

  Future<void> _persist(UserModel user) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: user.token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }
}
