import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/assistant_repository.dart';
import '../domain/chat_message.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(dio: ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Chat state
// ---------------------------------------------------------------------------

class AssistantNotifier extends StateNotifier<List<ChatMessage>> {
  AssistantNotifier(this._repo) : super([_welcome]);

  static final _welcome = ChatMessage(
    role: MessageRole.ada,
    text: 'Hello! I\'m Nurse Ada 👋\n\nI can help you understand symptoms, prepare for your clinic visit, or guide you through ClinicNow. How can I help you today?\n\n(Tip: I speak Pidgin too — feel free to write in Pidgin!)',
  );

  final AssistantRepository _repo;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  Future<void> send(String message, {String locale = 'en'}) async {
    if (message.trim().isEmpty) return;

    // Add user message
    state = [...state, ChatMessage(role: MessageRole.user, text: message.trim())];

    // Add typing indicator
    final typingMsg = ChatMessage(role: MessageRole.ada, text: '', isLoading: true);
    state = [...state, typingMsg];

    try {
      final history = state
          .where((m) => !m.isLoading && m != _welcome)
          .toList();
      final result = await _repo.chat(
        message: message.trim(),
        history: history,
        locale: locale,
      );

      _isOffline = result.offline;

      // Replace typing indicator with real reply
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          role: MessageRole.ada,
          text: result.reply,
          offline: result.offline,
        ),
      ];
    } catch (_) {
      _isOffline = true;
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          role: MessageRole.ada,
          text: 'No network connection. Please check your connection and try again.\n\nFor emergencies, call 112.',
          offline: true,
        ),
      ];
    }
  }

  void clear() => state = [_welcome];
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, List<ChatMessage>>((ref) {
  return AssistantNotifier(ref.watch(assistantRepositoryProvider));
});

final isOfflineProvider = Provider<bool>((ref) {
  ref.watch(assistantProvider); // rebuild when messages change
  return ref.read(assistantProvider.notifier).isOffline;
});