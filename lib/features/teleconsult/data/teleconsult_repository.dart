import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../domain/teleconsult_model.dart';

class TeleconsultRepository {
  TeleconsultRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  /// Patient creates or re-uses a session.
  Future<TeleconsultSession> createSession() async {
    if (AppConfig.demoMode) return _demoSession();
    final resp = await _dio.post<Map<String, dynamic>>('/api/teleconsult');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return TeleconsultSession.fromJson(data);
  }

  /// Staff gets the latest active session.
  Future<TeleconsultSession> latestSession() async {
    if (AppConfig.demoMode) return _demoSession();
    final resp = await _dio.get<Map<String, dynamic>>('/api/teleconsult/latest');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return TeleconsultSession.fromJson(data);
  }

  Future<TeleconsultSession> _demoSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const TeleconsultSession(
      id: 1,
      channelName: 'demo-consult-ikorodu',
      status: 'ACTIVE',
    );
  }
}