import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum NotifType { youreNext, called, queueUpdate, appointment, system }

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    DateTime? timestamp,
    this.read = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime timestamp;
  bool read;

  Color get iconColor {
    return switch (type) {
      NotifType.youreNext => AppColors.nairaGreen,
      NotifType.called    => AppColors.trustTeal,
      NotifType.queueUpdate => AppColors.waitAmber,
      NotifType.appointment => AppColors.trustTeal,
      NotifType.system    => const Color(0xFF6B7280),
    };
  }

  IconData get icon {
    return switch (type) {
      NotifType.youreNext  => Icons.notification_important_rounded,
      NotifType.called     => Icons.medical_services_rounded,
      NotifType.queueUpdate => Icons.people_rounded,
      NotifType.appointment => Icons.calendar_today_rounded,
      NotifType.system     => Icons.info_outline_rounded,
    };
  }
}