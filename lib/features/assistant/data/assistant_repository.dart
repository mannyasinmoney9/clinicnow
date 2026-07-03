import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/offline_ada_engine.dart';
import '../domain/chat_message.dart';

class AssistantRepository {
  AssistantRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<({String reply, bool offline})> chat({
    required String message,
    required List<ChatMessage> history,
    required String locale,
  }) async {
    if (AppConfig.demoMode) {
      // No network attempted in demo mode — Ada always answers instantly.
      await Future.delayed(const Duration(milliseconds: 500));
      return (reply: OfflineAdaEngine.reply(message, locale: locale), offline: true);
    }

    final historyPayload = history
        .where((m) => !m.isLoading)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'content': m.text,
            })
        .toList();

    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/assistant/chat',
      data: {
        'message': message,
        'history': historyPayload,
        'locale': locale,
      },
    );
    final data = resp.data!;
    return (
      reply: data['reply'] as String? ?? 'Sorry, something went wrong.',
      offline: data['offline'] as bool? ?? false,
    );
  }
}