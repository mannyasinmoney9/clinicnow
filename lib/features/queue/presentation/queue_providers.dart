import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/queue_repository.dart';
import '../domain/queue_entry.dart';
import '../domain/queue_snapshot.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final repo = QueueRepository(dio: ref.watch(dioProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Patient: my current queue entry (REST, polled on demand)
// ---------------------------------------------------------------------------

sealed class MyEntryState {
  const MyEntryState();
}

final class MyEntryLoading extends MyEntryState {
  const MyEntryLoading();
}

final class MyEntryData extends MyEntryState {
  const MyEntryData(this.entry);
  final QueueEntry entry;
}

final class MyEntryNone extends MyEntryState {
  const MyEntryNone();
}

final class MyEntryError extends MyEntryState {
  const MyEntryError(this.message);
  final String message;
}

class MyEntryNotifier extends StateNotifier<MyEntryState> {
  MyEntryNotifier(this._repo) : super(const MyEntryNone());

  final QueueRepository _repo;

  Future<void> join(int clinicId) async {
    state = const MyEntryLoading();
    try {
      final entry = await _repo.joinQueue(clinicId);
      state = MyEntryData(entry);
    } on Exception catch (e) {
      state = MyEntryError(e.toString());
    }
  }

  Future<void> refresh() async {
    try {
      final entry = await _repo.myCurrentEntry();
      state = MyEntryData(entry);
    } on Exception catch (_) {
      state = const MyEntryNone();
    }
  }

  void updateFromSnapshot(QueueSnapshot snapshot, int userId) {
    final current = state;
    if (current is! MyEntryData) return;
    final match = snapshot.entries
        .where((e) => e.userId == userId)
        .firstOrNull;
    if (match != null) {
      state = MyEntryData(match);
    }
  }

  void clear() => state = const MyEntryNone();
}

final myEntryProvider = StateNotifierProvider<MyEntryNotifier, MyEntryState>((ref) {
  return MyEntryNotifier(ref.watch(queueRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Live STOMP snapshot → StreamProvider (staff board + patient view)
// ---------------------------------------------------------------------------

final queueSnapshotProvider =
    StreamProvider.family<QueueSnapshot, int>((ref, clinicId) {
  final repo = ref.watch(queueRepositoryProvider);
  final auth = ref.watch(authProvider);
  final userId = auth is AuthAuthenticated ? auth.user.userId : 0;

  final controller = StreamController<QueueSnapshot>();

  // Fallback REST polling (takes over if WebSocket drops)
  Timer? pollTimer;

  Future<void> restFetch() async {
    try {
      final entries = await repo.clinicQueue(clinicId);
      if (!controller.isClosed) {
        controller.add(QueueSnapshot(
          clinicId: clinicId,
          entries: entries,
          totalWaiting: entries.length,
          broadcastedAt: DateTime.now(),
        ));
      }
    } on Exception catch (_) {}
  }

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => restFetch());
  }

  void stopPolling() {
    pollTimer?.cancel();
    pollTimer = null;
  }

  // Listen to STOMP stream and forward to our controller
  final sub = repo.queueSnapshots
      .where((s) => s.clinicId == clinicId)
      .listen((snapshot) {
    if (!controller.isClosed) {
      controller.add(snapshot);
      stopPolling(); // STOMP is working — no need to poll
    }
  });

  repo.connectStomp(
    clinicId: clinicId,
    userId: userId,
    onConnected: () {
      stopPolling();
      ref.read(stompConnectedProvider.notifier).state = true;
    },
    onDisconnected: () {
      startPolling(); // WebSocket dropped — fall back to REST
      ref.read(stompConnectedProvider.notifier).state = false;
    },
  );

  // Initial REST fetch so the board is populated immediately
  restFetch();
  // Also start polling initially; STOMP connection cancels it once connected
  startPolling();

  ref.onDispose(() {
    sub.cancel();
    stopPolling();
    controller.close();
    repo.disconnectStomp();
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// STOMP connection status (for the "Live" indicator on the staff board)
// ---------------------------------------------------------------------------

final stompConnectedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// User notification events (per-patient "you're next")
// ---------------------------------------------------------------------------

final userEventProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(queueRepositoryProvider).userEvents;
});
