import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/teleconsult_repository.dart';
import '../domain/teleconsult_model.dart';

final teleconsultRepositoryProvider = Provider<TeleconsultRepository>((ref) {
  return TeleconsultRepository(dio: ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Call state
// ---------------------------------------------------------------------------

sealed class CallState {
  const CallState();
}

final class CallIdle extends CallState {
  const CallIdle();
}

final class CallConnecting extends CallState {
  const CallConnecting(this.channelName);
  final String channelName;
}

final class CallActive extends CallState {
  const CallActive({required this.channelName, required this.remoteUid});
  final String channelName;
  final int remoteUid;
}

final class CallEnded extends CallState {
  const CallEnded();
}

final class CallFallback extends CallState {
  const CallFallback({required this.channelName, required this.reason});
  final String channelName;
  final String reason;
}

final class CallError extends CallState {
  const CallError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TeleconsultNotifier extends StateNotifier<CallState> {
  TeleconsultNotifier(this._repo) : super(const CallIdle());

  final TeleconsultRepository _repo;
  TeleconsultSession? session;

  Future<void> createAndConnect({bool asStaff = false}) async {
    try {
      session = asStaff ? await _repo.latestSession() : await _repo.createSession();
      state = CallConnecting(session!.channelName);
    } catch (e) {
      state = CallFallback(
        channelName: 'demo-consult-1',
        reason: 'Could not reach server — demo mode',
      );
    }
  }

  void onAgoraConnected(int remoteUid) {
    final ch = session?.channelName ?? 'demo-consult-1';
    state = CallActive(channelName: ch, remoteUid: remoteUid);
  }

  void onRemoteLeft() {
    if (state is CallActive) {
      final ch = (state as CallActive).channelName;
      state = CallActive(channelName: ch, remoteUid: 0);
    }
  }

  void enterFallback(String reason) {
    state = CallFallback(
      channelName: session?.channelName ?? 'demo-consult-1',
      reason: reason,
    );
  }

  void end() => state = const CallEnded();
  void reset() => state = const CallIdle();
}

final teleconsultProvider =
    StateNotifierProvider.autoDispose<TeleconsultNotifier, CallState>((ref) {
  return TeleconsultNotifier(ref.watch(teleconsultRepositoryProvider));
});