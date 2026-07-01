import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/env.dart';
import '../domain/queue_entry.dart';
import '../domain/queue_snapshot.dart';

class QueueRepository {
  QueueRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // -------------------------------------------------------------------------
  // REST
  // -------------------------------------------------------------------------

  Future<QueueEntry> joinQueue(int clinicId) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/queue/join',
      data: {'clinicId': clinicId},
    );
    return QueueEntry.fromJson(resp.data!);
  }

  Future<QueueEntry> myCurrentEntry() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/queue/me');
    return QueueEntry.fromJson(resp.data!);
  }

  Future<int> aheadCount(int entryId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/api/queue/ahead',
      queryParameters: {'entryId': entryId},
    );
    return (resp.data!['aheadCount'] as num).toInt();
  }

  Future<List<QueueEntry>> clinicQueue(int clinicId) async {
    final resp = await _dio.get<List<dynamic>>('/api/queue/clinic/$clinicId');
    return (resp.data ?? [])
        .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QueueEntry> callNext(int entryId) async {
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/call');
    return QueueEntry.fromJson(resp.data!);
  }

  Future<QueueEntry> markDone(int entryId) async {
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/done');
    return QueueEntry.fromJson(resp.data!);
  }

  Future<QueueEntry> markNoShow(int entryId) async {
    final resp = await _dio.post<Map<String, dynamic>>('/api/queue/$entryId/noshow');
    return QueueEntry.fromJson(resp.data!);
  }

  // -------------------------------------------------------------------------
  // STOMP WebSocket
  // -------------------------------------------------------------------------

  StompClient? _stomp;
  final _snapshotController = StreamController<QueueSnapshot>.broadcast();
  final _userEventController = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;

  Stream<QueueSnapshot> get queueSnapshots => _snapshotController.stream;
  Stream<Map<String, dynamic>> get userEvents => _userEventController.stream;
  bool get isConnected => _connected;

  void connectStomp({
    required int clinicId,
    required int userId,
    void Function()? onConnected,
    void Function()? onDisconnected,
  }) {
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
  }
}
