import 'dart:async';

import '../../features/queue/domain/queue_entry.dart';
import '../../features/queue/domain/queue_snapshot.dart';
import 'demo_seed.dart';

/// Drives the queue board without a backend: seeded patients already
/// waiting, a timer that advances the queue every ~24s so the board never
/// looks dead, and instant local reactions to staff "Call next" / patient
/// "Join queue" actions. One instance lives for the app session.
class DemoQueueEngine {
  DemoQueueEngine() {
    _entries = [
      for (var i = 0; i < DemoSeed.patients.length; i++)
        QueueEntry(
          id: i + 1,
          clinicId: DemoSeed.clinicId,
          userId: DemoSeed.patients[i].userId,
          queueNumber: DemoSeed.firstTicketNumber + i,
          status: 'WAITING',
          position: i + 1,
          patientName: DemoSeed.patients[i].fullName,
          joinedAt: DateTime.now().subtract(
            Duration(minutes: (DemoSeed.patients.length - i) * 4),
          ),
        ),
    ];
    _nextId = _entries.length + 1;
    _nextTicket = DemoSeed.firstTicketNumber + _entries.length;
  }

  late List<QueueEntry> _entries;
  late int _nextId;
  late int _nextTicket;
  Timer? _ticker;

  final _snapshotController = StreamController<QueueSnapshot>.broadcast();
  final _userEventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<QueueSnapshot> get snapshots => _snapshotController.stream;
  Stream<Map<String, dynamic>> get userEvents => _userEventController.stream;

  void start() {
    _broadcast();
    _ticker ??= Timer.periodic(const Duration(seconds: 24), (_) => _tick());
  }

  void _tick() {
    final calledIdx = _entries.indexWhere((e) => e.status == 'CALLED');
    if (calledIdx != -1) {
      _entries[calledIdx] = _entries[calledIdx].copyWith(status: 'SEEN');
    }
    _callNextWaitingIfNoneCalled();
    _recomputePositions();
    _broadcast();
  }

  void _callNextWaitingIfNoneCalled() {
    if (_entries.any((e) => e.status == 'CALLED')) return;
    final idx = _entries.indexWhere((e) => e.status == 'WAITING');
    if (idx == -1) return;
    _entries[idx] = _entries[idx].copyWith(status: 'CALLED');
    _fireUserEvent(_entries[idx], 'YOU_ARE_NEXT');
  }

  QueueEntry join({required int userId, required String patientName}) {
    final entry = QueueEntry(
      id: _nextId++,
      clinicId: DemoSeed.clinicId,
      userId: userId,
      queueNumber: _nextTicket++,
      status: 'WAITING',
      position: _entries.where((e) => e.status == 'WAITING').length + 1,
      patientName: patientName,
      joinedAt: DateTime.now(),
    );
    _entries.add(entry);
    _recomputePositions();
    _broadcast();
    return entry;
  }

  QueueEntry? myEntry(int userId) {
    for (var i = _entries.length - 1; i >= 0; i--) {
      final e = _entries[i];
      if (e.userId == userId && e.status != 'SEEN' && e.status != 'NO_SHOW') {
        return e;
      }
    }
    return null;
  }

  List<QueueEntry> clinicQueue() => List.unmodifiable(
        _entries.where((e) => e.status == 'WAITING' || e.status == 'CALLED'),
      );

  int aheadCount(int entryId) {
    final target = _findById(entryId);
    if (target == null || target.status != 'WAITING') return 0;
    return _entries
        .where((e) => e.status == 'WAITING' && e.position < target.position)
        .length;
  }

  QueueEntry callNext(int entryId) {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx == -1) throw StateError('Queue entry not found');
    _entries[idx] = _entries[idx].copyWith(status: 'CALLED');
    _recomputePositions();
    _fireUserEvent(_entries[idx], 'YOU_ARE_NEXT');
    _broadcast();
    return _entries[idx];
  }

  QueueEntry markDone(int entryId) => _setStatus(entryId, 'SEEN');
  QueueEntry markNoShow(int entryId) => _setStatus(entryId, 'NO_SHOW');

  QueueEntry _setStatus(int entryId, String status) {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx == -1) throw StateError('Queue entry not found');
    _entries[idx] = _entries[idx].copyWith(status: status);
    _recomputePositions();
    _broadcast();
    return _entries[idx];
  }

  QueueEntry? _findById(int id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _recomputePositions() {
    var pos = 1;
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].status == 'WAITING') {
        _entries[i] = _entries[i].copyWith(position: pos);
        pos++;
      } else if (_entries[i].status == 'CALLED') {
        _entries[i] = _entries[i].copyWith(position: 0);
      }
    }
  }

  void _fireUserEvent(QueueEntry entry, String type) {
    if (_userEventController.isClosed) return;
    _userEventController.add({
      'type': type,
      'userId': entry.userId,
      'message': 'Abeg come — the doctor is ready for you now.',
    });
  }

  void _broadcast() {
    if (_snapshotController.isClosed) return;
    final visible =
        _entries.where((e) => e.status == 'WAITING' || e.status == 'CALLED').toList();
    _snapshotController.add(
      QueueSnapshot(
        clinicId: DemoSeed.clinicId,
        entries: visible,
        totalWaiting: _entries.where((e) => e.status == 'WAITING').length,
        broadcastedAt: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _ticker?.cancel();
    _snapshotController.close();
    _userEventController.close();
  }
}