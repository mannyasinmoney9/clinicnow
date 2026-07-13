import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_queue_engine.dart';
import '../../../core/env.dart';
import '../domain/queue_entry.dart';
import '../domain/queue_snapshot.dart';

class QueueRepository {
  QueueRepository({required Dio dio}) : _dio = dio {
    if (AppConfig.demoMode) _demo.start();
  }

  final Dio _dio;
  final DemoQueueEngine _demo = DemoQueueEngine();
  int? _myEntryId;

  // -------------------------------------------------------------------------
  // REST
  // -------------------------------------------------------------------------

  Future<QueueEntry> joinQueue(int clinicId, {int? userId, String? patientName}) async {
    if (AppConfig.demoMode) {
      final entry = _demo.join(
        clinicId: clinicId,
        userId: userId ?? 0,
        patientName: (patientName == null || patientName.isEmpty) ? 'You' : patientName,
      );
      _myEntryId = entry.id;
      return entry;
    }
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/queue/join',
      data: {'clinicId': clinicId},
    );
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    final entry = QueueEntry.fromJson(data);
    _myEntryId = entry.id;
    return entry;
  }

  Future<QueueEntry> myCurrentEntry() async {
    if (AppConfig.demoMode) {
      final id = _myEntryId;
      final entry = id == null ? null : _demo.myEntryById(id);
      if (entry == null) throw StateError('No active queue entry');
      return entry;
    }
    final resp = await _dio.get<Map<String, dynamic>>('/api/queue/me');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return QueueEntry.fromJson(data);
  }

  Future<int> aheadCount(int entryId) async {
    if (AppConfig.demoMode) return _demo.aheadCount(entryId);
    final resp = await _dio.get<Map<String, dynamic>>(
      '/api/queue/ahead',
      queryParameters: {'entryId': entryId},
    );
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return (data['aheadCount'] as num).toInt();
  }

  Future<List<QueueEntry>> clinicQueue(int clinicId) async {
    if (AppConfig.demoMode) return _demo.clinicQueue(clinicId);
    final resp = await _dio.get<List<dynamic>>('/api/queue/clinic/$clinicId');
    return (resp.data ?? [])
        .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QueueEntry> callNext(int entryId) async {
    if (AppConfig.demoMode) return _demo.callNext(entryId);
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/call');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return QueueEntry.fromJson(data);
  }

  Future<QueueEntry> markDone(int entryId) async {
    if (AppConfig.demoMode) return _demo.markDone(entryId);
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/done');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return QueueEntry.fromJson(data);
  }

  Future<QueueEntry> markNoShow(int entryId) async {
    if (AppConfig.demoMode) return _demo.markNoShow(entryId);
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/noshow');
    final data = resp.data;
    if (data == null) throw Exception('Empty response from server');
    return QueueEntry.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // STOMP WebSocket
  // -------------------------------------------------------------------------

  StompClient? _stomp;
  final _snapshotController = StreamController<QueueSnapshot>.broadcast();
  final _userEventController = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  Stream<QueueSnapshot> get queueSnapshots =>
      AppConfig.demoMode ? _demo.snapshots : _snapshotController.stream;
  Stream<Map<String, dynamic>> get userEvents =>
      AppConfig.demoMode ? _demo.userEvents : _userEventController.stream;
  bool get isConnected => AppConfig.demoMode ? true : _connected;

  void connectStomp({
    required int clinicId,
    required int userId,
    void Function()? onConnected,
    void Function()? onDisconnected,
  }) {
    if (AppConfig.demoMode) {
      // No real socket — the local ticking engine is always "live".
      _connected = true;
      onConnected?.call();
      return;
    }
    _stomp?.deactivate();
    final wsUrl =
        '${apiBaseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}/ws';

    _stomp = StompClient(
      config: StompConfig(
        url: wsUrl,
        heartbeatOutgoing: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 5),
        reconnectDelay: const Duration(seconds: 4),
        onConnect: (frame) {
          _connected = true;
          onConnected?.call();

          // Subscribe to the full clinic queue snapshot
          _stomp?.subscribe(
            destination: '/topic/clinics/$clinicId/queue',
            callback: (frame) {
              if (frame.body == null) return;
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              if (!_snapshotController.isClosed) {
                _snapshotController.add(QueueSnapshot.fromJson(json));
              }
            },
          );

          // Subscribe to per-user "you're next" events
          _stomp?.subscribe(
            destination: '/topic/users/$userId',
            callback: (frame) {
              if (frame.body == null) return;
              final json = jsonDecode(frame.body!) as Map<String, dynamic>;
              if (!_userEventController.isClosed) {
                _userEventController.add(json);
              }
            },
          );
        },
        onDisconnect: (_) {
          _connected = false;
          onDisconnected?.call();
        },
        onWebSocketError: (_) {
          _connected = false;
          onDisconnected?.call();
        },
        onStompError: (_) {
          _connected = false;
        },
      ),
    );
    _stomp!.activate();
  }

  void disconnectStomp() {
    _stomp?.deactivate();
    _stomp = null;
    _connected = false;
  }

  void dispose() {
    disconnectStomp();
    _snapshotController.close();
    _userEventController.close();
    // Note: the demo engine is intentionally NOT disposed here — it must
    // outlive individual screens so the queue keeps ticking across
    // navigation. It's a process-lifetime singleton (see queueRepositoryProvider).
  }
}
