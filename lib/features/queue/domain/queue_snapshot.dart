import 'queue_entry.dart';

class QueueSnapshot {
  const QueueSnapshot({
    required this.clinicId,
    required this.entries,
    required this.totalWaiting,
    required this.broadcastedAt,
  });

  final int clinicId;
  final List<QueueEntry> entries;
  final int totalWaiting;
  final DateTime broadcastedAt;

  factory QueueSnapshot.fromJson(Map<String, dynamic> json) => QueueSnapshot(
        clinicId: (json['clinicId'] as num).toInt(),
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => QueueEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalWaiting: (json['totalWaiting'] as num?)?.toInt() ?? 0,
        broadcastedAt: json['broadcastedAt'] != null
            ? DateTime.parse(json['broadcastedAt'] as String)
            : DateTime.now(),
      );
}
