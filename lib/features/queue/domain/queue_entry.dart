import 'package:flutter/foundation.dart';

@immutable
class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.clinicId,
    required this.userId,
    required this.queueNumber,
    required this.status,
    required this.position,
    required this.patientName,
    required this.joinedAt,
  });

  final int id;
  final int clinicId;
  final int userId;
  final int queueNumber;
  final String status;
  final int position;
  final String patientName;
  final DateTime joinedAt;

  bool get isWaiting => status == 'WAITING';
  bool get isCalled => status == 'CALLED';

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: (json['id'] as num).toInt(),
        clinicId: (json['clinicId'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        queueNumber: (json['queueNumber'] as num).toInt(),
        status: json['status'] as String? ?? 'WAITING',
        position: (json['position'] as num?)?.toInt() ?? 0,
        patientName: json['patientName'] as String? ?? '',
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : DateTime.now(),
      );

  QueueEntry copyWith({int? position, String? status}) => QueueEntry(
        id: id,
        clinicId: clinicId,
        userId: userId,
        queueNumber: queueNumber,
        status: status ?? this.status,
        position: position ?? this.position,
        patientName: patientName,
        joinedAt: joinedAt,
      );
}
