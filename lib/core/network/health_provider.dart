import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'api_client.dart';

enum BackendStatus { checking, ok, unreachable }

class HealthNotifier extends StateNotifier<BackendStatus> {
  HealthNotifier(this._dio) : super(BackendStatus.checking) {
    check();
  }

  final Dio _dio;

  Future<void> check() async {
    if (AppConfig.demoMode) {
      // Demo mode never calls a backend — there's nothing to be unreachable.
      state = BackendStatus.ok;
      return;
    }
    state = BackendStatus.checking;
    try {
      final resp = await _dio.get<dynamic>(
        '/api/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      state = (resp.statusCode ?? 0) < 400
          ? BackendStatus.ok
          : BackendStatus.unreachable;
    } catch (_) {
      state = BackendStatus.unreachable;
    }
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, BackendStatus>((ref) {
  return HealthNotifier(ref.watch(dioProvider));
});