class AppointmentItem {
  AppointmentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.scheduledAt,
    required this.status,
  });

  final int id;
  final String type; // GENERAL | ANTENATAL | IMMUNISATION
  final String title;
  final DateTime scheduledAt;
  String status; // UPCOMING | COMPLETED | CANCELLED
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.dueDate,
    this.given = false,
  });

  final int id;
  final String kind; // IMMUNISATION | ANTENATAL | MEDICINE
  final String title;
  final DateTime dueDate;
  bool given;
}