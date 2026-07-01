import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../domain/queue_entry.dart';
import '../domain/queue_snapshot.dart';
import 'queue_providers.dart';

// Default clinic ID — in production this comes from staff's assigned clinic.
// For the demo the seed data creates clinic ID 1.
const _demoClinicId = 1;

class StaffBoardPage extends ConsumerWidget {
  const StaffBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(queueSnapshotProvider(_demoClinicId));
    final isLive = ref.watch(stompConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Board'),
        actions: [
          _LiveIndicator(connected: isLive),
          const SizedBox(width: 12),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(queueSnapshotProvider(_demoClinicId)),
        ),
        data: (snapshot) => _BoardBody(snapshot: snapshot),
      ),
    );
  }
}

// ── Live indicator ─────────────────────────────────────────────────────────

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LivePulseDot(live: connected),
        const SizedBox(width: 4),
        Text(
          connected ? 'Live' : 'Polling',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: connected ? Colors.green.shade600 : Colors.orange.shade600,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LivePulseDot extends StatelessWidget {
  const _LivePulseDot({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? Colors.green.shade600 : Colors.orange.shade600;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ).animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.5, 1.5),
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.5, 1.5),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ── Board body ─────────────────────────────────────────────────────────────

class _BoardBody extends ConsumerWidget {
  const _BoardBody({required this.snapshot});
  final QueueSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = snapshot.entries.where((e) => e.isWaiting).toList();
    final called = snapshot.entries.where((e) => e.isCalled).toList();

    return Column(
      children: [
        _SummaryBar(totalWaiting: snapshot.totalWaiting),
        Expanded(
          child: (waiting.isEmpty && called.isEmpty)
              ? const EmptyState(
                  title: 'Queue is empty',
                  subtitle: 'No patients waiting right now',
                  icon: Icons.people_outline,
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (called.isNotEmpty) ...[
                      _SectionHeader('Now Being Seen'),
                      ...called.map((e) => _EntryCard(entry: e, isCalled: true)),
                    ],
                    if (waiting.isNotEmpty) ...[
                      _SectionHeader('Waiting'),
                      ...waiting.map((e) => _EntryCard(entry: e, isCalled: false)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Summary bar ────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totalWaiting});
  final int totalWaiting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.people, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            '$totalWaiting waiting',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            'Updated just now',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer.withAlpha(160),
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

// ── Entry card ─────────────────────────────────────────────────────────────

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry, required this.isCalled});
  final QueueEntry entry;
  final bool isCalled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final repo = ref.read(queueRepositoryProvider);

    final cardColor = isCalled
        ? Colors.green.shade50
        : cs.surfaceContainerHighest;
    final borderColor = isCalled ? Colors.green.shade400 : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isCalled ? Colors.green.shade600 : cs.primary,
          child: Text(
            '#${entry.queueNumber}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(entry.patientName, style: tt.titleSmall),
        subtitle: Text(
          'Waiting ${_waitMinutes(entry.joinedAt)} min',
          style: tt.bodySmall,
        ),
        trailing: isCalled
            ? _ActionChip(
                label: 'Mark Done',
                color: Colors.green.shade700,
                onTap: () async {
                  try {
                    await repo.markDone(entry.id);
                  } catch (_) {}
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionChip(
                    label: 'Call',
                    color: cs.primary,
                    onTap: () async {
                      try {
                        await repo.callNext(entry.id);
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionChip(
                    label: 'Skip',
                    color: Colors.orange.shade700,
                    onTap: () async {
                      try {
                        await repo.markNoShow(entry.id);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  int _waitMinutes(DateTime joinedAt) =>
      DateTime.now().difference(joinedAt).inMinutes;
}

// ── Action chip ────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
