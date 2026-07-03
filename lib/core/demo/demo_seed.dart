/// Local Nigerian seed data used everywhere in demo mode — no backend needed.
class DemoPatientSeed {
  const DemoPatientSeed(this.userId, this.fullName, this.reason);
  final int userId;
  final String fullName;
  final String reason;
}

class DemoReminderSeed {
  const DemoReminderSeed(this.kind, this.title, this.dueInDays, {this.given = false});
  final String kind; // IMMUNISATION | ANTENATAL | MEDICINE
  final String title;
  final int dueInDays; // negative = overdue
  final bool given;
}

class DemoAppointmentSeed {
  const DemoAppointmentSeed(this.type, this.title, this.inDays, this.status);
  final String type; // GENERAL | ANTENATAL | IMMUNISATION
  final String title;
  final int inDays;
  final String status; // UPCOMING | COMPLETED | CANCELLED
}

abstract final class DemoSeed {
  static const clinicId = 1;
  static const clinicName = 'Ikorodu General Outpatient';
  static const clinicAddress = 'Ayangburen Road, Ikorodu, Lagos';

  /// Waiting-room patients already ahead of you when you check in.
  /// Ticket numbers 91–98; 99–102 are reserved for new joiners during the demo.
  static const patients = [
    DemoPatientSeed(201, 'Adaeze Okafor', 'Fever & headache'),
    DemoPatientSeed(202, 'Chidi Nwosu', 'Follow-up: hypertension'),
    DemoPatientSeed(203, 'Fatima Bello', 'Antenatal check-up'),
    DemoPatientSeed(204, 'Emeka Eze', 'Malaria symptoms'),
    DemoPatientSeed(205, 'Blessing Achebe', 'Child immunisation'),
    DemoPatientSeed(206, 'Musa Ibrahim', 'Cough & cold'),
    DemoPatientSeed(207, 'Ngozi Chukwu', 'Wound dressing'),
    DemoPatientSeed(208, 'Sadiq Yusuf', 'Diabetes review'),
  ];

  static const firstTicketNumber = 91;
  static const lastReservedTicketNumber = 102;

  static const reminders = [
    DemoReminderSeed('IMMUNISATION', 'BCG + OPV0 (at birth)', -12),
    DemoReminderSeed('IMMUNISATION', 'Pentavalent 1 + OPV1 (6 weeks)', 3),
    DemoReminderSeed('IMMUNISATION', 'Pentavalent 2 + OPV2 (10 weeks)', 31),
    DemoReminderSeed('IMMUNISATION', 'Measles + Yellow Fever (9 months)', 90),
    DemoReminderSeed('ANTENATAL', 'ANC contact 1 — before 12 weeks', -5, given: true),
    DemoReminderSeed('ANTENATAL', 'ANC contact 2 — 20 weeks', 2),
    DemoReminderSeed('ANTENATAL', 'ANC contact 3 — 26 weeks', 44),
    DemoReminderSeed('MEDICINE', 'Antimalarial course — refill', 1),
  ];

  static const appointments = [
    DemoAppointmentSeed('GENERAL', 'General check-up — Dr. Adebayo', 2, 'UPCOMING'),
    DemoAppointmentSeed('ANTENATAL', 'Antenatal clinic — Midwife Grace', 6, 'UPCOMING'),
    DemoAppointmentSeed('IMMUNISATION', 'Baby immunisation — NPHCDA', 10, 'UPCOMING'),
    DemoAppointmentSeed('GENERAL', 'Malaria follow-up', -14, 'COMPLETED'),
  ];
}