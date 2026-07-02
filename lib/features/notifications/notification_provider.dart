import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../queue/presentation/queue_providers.dart';
import 'domain/app_notification.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier(this._ref) : super([]) {
    _listen();
  }

  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _sub;

  void _listen() {
    final repo = _ref.read(queueRepositoryProvider);
    _sub = repo.userEvents.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = (event['type'] as String? ?? '').toUpperCase();

    final notif = switch (type) {
      'YOU_ARE_NEXT' || 'YOURE_NEXT' => AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'You\'re next!',
          body: 'Abeg come — the doctor is ready for you now.',
          type: NotifType.youreNext,
        ),
      'CALLED' => AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Doctor is calling',
          body: event['message'] as String? ?? 'Please proceed to the consultation room.',
          type: NotifType.called,
        ),
      'QUEUE_UPDATE' => AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Queue updated',
          body: event['message'] as String? ?? 'Your position in the queue has changed.',
          type: NotifType.queueUpdate,
        ),
      _ => AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: event['title'] as String? ?? 'ClinicNow',
          body: event['message'] as String? ?? '',
          type: NotifType.system,
        ),
    };

    state = [notif, ...state];
  }

  /// Add a local notification (e.g., queue token issued, appointment booked).
  void add(AppNotification notif) {
    state = [notif, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          (n..read = true)
        else
          n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) (n..read = true)];
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() => state = [];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier(ref);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.read).length;
});