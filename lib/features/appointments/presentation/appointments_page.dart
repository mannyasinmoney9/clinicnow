import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/success_overlay.dart';
import '../domain/appointment_models.dart';
import 'appointments_providers.dart';

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Your schedule'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Appointments')),
                ButtonSegment(value: 1, label: Text('Reminders')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: 250.ms,
              child: _tab == 0
                  ? _AppointmentsList(key: const ValueKey('appts'), items: appointments)
                  : _RemindersList(key: const ValueKey('rems'), items: reminders),
            ),
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showBookSheet(context, ref),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Book appointment'),
            ).animate().scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 350.ms,
                curve: Curves.easeOutBack)
          : null,
    );
  }

  void _showBookSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookAppointmentSheet(
        onBooked: (type, title, date) {
          ref.read(appointmentsProvider.notifier).book(
                type: type,
                title: title,
                scheduledAt: date,
              );
          SuccessOverlay.show(
            context,
            message: 'Appointment booked ✅',
            subtitle: DateFormat('EEE d MMM · h:mm a').format(date),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AppointmentsList extends StatelessWidget {
  const _AppointmentsList({super.key, required this.items});
  final List<AppointmentItem> items;

  @override
  Widget build(BuildContext context) {
    final active = items.where((a) => a.status != 'CANCELLED').toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (active.isEmpty) {
      return const EmptyState(
        title: 'No appointments yet',
        subtitle: 'Book one and we\'ll remind you before it\'s due',
        icon: Icons.calendar_today_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: active.length,
      itemBuilder: (context, i) => _AppointmentRow(item: active[i], index: i),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.item, required this.index});
  final AppointmentItem item;
  final int index;

  (IconData, Color) get _iconFor => switch (item.type) {
        'ANTENATAL' => (Icons.pregnant_woman_rounded, AppColors.nairaGreen),
        'IMMUNISATION' => (Icons.vaccines_rounded, AppColors.trustTeal),
        _ => (Icons.medical_services_rounded, const Color(0xFF7C3AED)),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor;
    final isPast = item.status == 'COMPLETED';
    final daysAway = item.scheduledAt.difference(DateTime.now()).inDays;
    final soon = !isPast && daysAway <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: context.colors.outlineVariant, width: 0.5),
      ),
      child: Opacity(
        opacity: isPast ? 0.6 : 1,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: AppRadii.rSm),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: context.text.titleSmall),
                  Text(
                    DateFormat('EEE d MMM · h:mm a').format(item.scheduledAt),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isPast ? AppColors.nairaGreen : (soon ? AppColors.waitAmber : color))
                    .withAlpha(25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPast ? 'Done' : (soon ? 'Soon' : '${daysAway}d'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isPast ? AppColors.nairaGreen : (soon ? AppColors.waitAmber : color),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

// ---------------------------------------------------------------------------

class _RemindersList extends ConsumerWidget {
  const _RemindersList({super.key, required this.items});
  final List<ReminderItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (sorted.isEmpty) {
      return const EmptyState(
        title: 'No reminders',
        subtitle: 'Immunisation and antenatal reminders will show here',
        icon: Icons.notifications_none_rounded,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final r = sorted[i];
        final overdue = !r.given && r.dueDate.isBefore(DateTime.now());
        final daysAway = r.dueDate.difference(DateTime.now()).inDays;
        final (icon, color) = switch (r.kind) {
          'ANTENATAL' => (Icons.pregnant_woman_rounded, AppColors.nairaGreen),
          'MEDICINE' => (Icons.medication_rounded, const Color(0xFF7C3AED)),
          _ => (Icons.vaccines_rounded, AppColors.trustTeal),
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadii.rMd,
            border: Border.all(
              color: r.given
                  ? context.colors.outlineVariant
                  : (overdue ? AppColors.emergencyRed.withAlpha(80) : context.colors.outlineVariant),
              width: overdue && !r.given ? 1.2 : 0.5,
            ),
          ),
          child: Opacity(
            opacity: r.given ? 0.6 : 1,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (r.given ? AppColors.nairaGreen : color).withAlpha(25),
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Icon(r.given ? Icons.check_rounded : icon,
                      color: r.given ? AppColors.nairaGreen : color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: context.text.titleSmall),
                      Text(
                        r.given
                            ? 'Given · ${DateFormat('d MMM').format(r.dueDate)}'
                            : (overdue ? 'Overdue' : 'Due in ${daysAway}d'),
                        style: context.text.bodySmall?.copyWith(
                          color: overdue && !r.given ? AppColors.emergencyRed : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!r.given)
                  TextButton(
                    onPressed: () {
                      ref.read(remindersProvider.notifier).markGiven(r.id);
                      SuccessOverlay.show(context, message: 'Marked as given ✅');
                    },
                    child: const Text('Mark given'),
                  ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Book appointment sheet
// ---------------------------------------------------------------------------

class _BookAppointmentSheet extends StatefulWidget {
  const _BookAppointmentSheet({required this.onBooked});
  final void Function(String type, String title, DateTime date) onBooked;

  @override
  State<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<_BookAppointmentSheet> {
  String _type = 'GENERAL';
  int _daysAhead = 2;
  final _titleCtrl = TextEditingController(text: 'General check-up');

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Book appointment', style: context.text.titleLarge),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _TypeChip(
                  label: 'General',
                  selected: _type == 'GENERAL',
                  onTap: () => setState(() {
                    _type = 'GENERAL';
                    _titleCtrl.text = 'General check-up';
                  }),
                ),
                _TypeChip(
                  label: 'Antenatal',
                  selected: _type == 'ANTENATAL',
                  onTap: () => setState(() {
                    _type = 'ANTENATAL';
                    _titleCtrl.text = 'Antenatal clinic visit';
                  }),
                ),
                _TypeChip(
                  label: 'Immunisation',
                  selected: _type == 'IMMUNISATION',
                  onTap: () => setState(() {
                    _type = 'IMMUNISATION';
                    _titleCtrl.text = 'Child immunisation';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 16),
            Text('When', style: context.text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 7].map((d) {
                return _TypeChip(
                  label: d == 1 ? 'Tomorrow' : '$d days',
                  selected: _daysAhead == d,
                  onTap: () => setState(() => _daysAhead = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Confirm booking',
              onPressed: () {
                Navigator.of(context).pop();
                widget.onBooked(
                  _type,
                  _titleCtrl.text.trim().isEmpty ? 'Clinic visit' : _titleCtrl.text.trim(),
                  DateTime.now().add(Duration(days: _daysAhead, hours: 1)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}