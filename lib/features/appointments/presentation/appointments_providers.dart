import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_seed.dart';
import '../domain/appointment_models.dart';

class AppointmentsNotifier extends StateNotifier<List<AppointmentItem>> {
  AppointmentsNotifier() : super(_seeded());

  static List<AppointmentItem> _seeded() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < DemoSeed.appointments.length; i++)
        AppointmentItem(
          id: i + 1,
          type: DemoSeed.appointments[i].type,
          title: DemoSeed.appointments[i].title,
          scheduledAt: now.add(Duration(days: DemoSeed.appointments[i].inDays)),
          status: DemoSeed.appointments[i].status,
        ),
    ];
  }

  void book({required String type, required String title, required DateTime scheduledAt}) {
    final nextId = state.isEmpty ? 1 : state.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    state = [
      ...state,
      AppointmentItem(id: nextId, type: type, title: title, scheduledAt: scheduledAt, status: 'UPCOMING'),
    ];
  }

  void cancel(int id) {
    state = [
      for (final a in state)
        if (a.id == id) (a..status = 'CANCELLED') else a,
    ];
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<AppointmentItem>>((ref) {
  return AppointmentsNotifier();
});

class RemindersNotifier extends StateNotifier<List<ReminderItem>> {
  RemindersNotifier() : super(_seeded());

  static List<ReminderItem> _seeded() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < DemoSeed.reminders.length; i++)
        ReminderItem(
          id: i + 1,
          kind: DemoSeed.reminders[i].kind,
          title: DemoSeed.reminders[i].title,
          dueDate: now.add(Duration(days: DemoSeed.reminders[i].dueInDays)),
          given: DemoSeed.reminders[i].given,
        ),
    ];
  }

  void markGiven(int id) {
    state = [
      for (final r in state)
        if (r.id == id) (r..given = true) else r,
    ];
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<ReminderItem>>((ref) {
  return RemindersNotifier();
});