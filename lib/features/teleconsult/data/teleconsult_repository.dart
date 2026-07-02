import 'package:dio/dio.dart';

import '../domain/teleconsult_model.dart';

class TeleconsultRepository {
  TeleconsultRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  /// Patient creates or re-uses a session.
  Future<TeleconsultSession> createSession() async {
    final resp = await _dio.post<Map<String, dynamic>>('/api/teleconsult');
    return TeleconsultSession.fromJson(resp.data!);
  }

  /// Staff gets the latest active session.
  Future<TeleconsultSession> latestSession() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/teleconsult/latest');
    return TeleconsultSession.fromJson(resp.data!);
  }
}