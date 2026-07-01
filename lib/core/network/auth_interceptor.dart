import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches the stored JWT as a Bearer token on every outgoing request.
/// On a 401 response the stored credentials are cleared so the next
/// GoRouter redirect (driven by authProvider) sends the user to /login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await Future.wait([
        _storage.delete(key: 'jwt_token'),
        _storage.delete(key: 'user_json'),
      ]);
    }
    handler.next(err);
  }
}
