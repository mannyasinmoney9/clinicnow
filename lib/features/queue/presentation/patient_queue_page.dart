import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/health_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/queue_entry.dart';
import '../domain/queue_snapshot.dart';
import 'queue_providers.dart';

class PatientQueuePage extends ConsumerStatefulWidget {
  const PatientQueuePage({super.key, required this.clinicId, required this.clinicName});

  final int clinicId;
  final String clinicName;

  @override
  ConsumerState<PatientQueuePage> createState() => _PatientQueuePageState();
}

class _PatientQueuePageState extends ConsumerState<PatientQueuePage>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl;
  late final AnimationController _tokenCtrl;
  bool _tokenShown = false;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _tokenCtrl = AnimationController(vsync: this, duration: 600.ms);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    await ref.read(myEntryProvider.notifier).join(widget.clinicId);
    if (!mounted) return;
    final state = ref.read(myEntryProvider);
    if (state is MyEntryData && !_tokenShown) {
      _tokenShown = true;
      _tokenCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final myEntry = ref.watch(myEntryProvider);
    final snapshotAsync = ref.watch(queueSnapshotProvider(widget.clinicId));
    final auth = ref.watch(authProvider);
    final userId = auth is AuthAuthenticated ? auth.user.userId : 0;

    // Sync entry position from live snapshot
    ref.listen(queueSnapshotProvider(widget.clinicId), (_, next) {
      next.whenData((snapshot) {
        ref.read(myEntryProvider.notifier).updateFromSnapshot(snapshot, userId);
      });
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(widget.clinicName, style: tt.titleMedium),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.trustTeal,
              onRefresh: () async {
                ref.invalidate(queueSnapshotProvider(widget.clinicId));
                await ref.read(healthProvider.notifier).check();
              },
              child: switch (myEntry) {
                MyEntryNone() => _JoinView(onJoin: _join),
                MyEntryLoading() =>
                  const Center(child: CircularProgressIndicator()),
                MyEntryError(message: final msg) => ErrorState(
                    message: msg,
                    onRetry: _join,
                  ),
                MyEntryData(entry: final entry) => _InQueueView(
                    entry: entry,
                    tokenCtrl: _tokenCtrl,
                    orbitCtrl: _orbitCtrl,
                    snapshot: snapshotAsync.value,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Join view ─────────────────────────────────────────────────────────────

class _JoinView extends StatelessWidget {
  const _JoinView({required this.onJoin});
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_rounded, size: 96, color: cs.primary),
          const SizedBox(height: 24),
          Text('Ready to join the queue?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('We go hold your place. No need to wait for long.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          PrimaryButton(label: 'Join Queue', onPressed: onJoin),
        ],
      ),
    );
  }
}

// ── In-queue view ─────────────────────────────────────────────────────────

class _InQueueView extends StatelessWidget {
  const _InQueueView({
    required this.entry,
    required this.tokenCtrl,
    required this.orbitCtrl,
    this.snapshot,
  });

  final QueueEntry entry;
  final AnimationController tokenCtrl;
  final AnimationController orbitCtrl;
  final QueueSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final aheadCount = max(0, entry.position - 1);
    final isCalled = entry.isCalled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Token reveal — springs in when first issued
          ScaleTransition(
            scale: CurvedAnimation(parent: tokenCtrl, curve: Curves.elasticOut),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCalled ? Colors.green.shade600 : cs.primary,
                boxShadow: [
                  BoxShadow(
                    color: (isCalled ? Colors.green : cs.primary).withAlpha(80),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ticket', style: tt.labelSmall?.copyWith(color: Colors.white70)),
                  Text(
                    '#${entry.queueNumber}',
                    style: tt.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          if (isCalled) ...[
            Text('You\'re next — abeg come! 🏃',
                style: tt.titleLarge?.copyWith(
                    color: Colors.green.shade700, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)
                .animate().shake(duration: 600.ms),
          ] else ...[
            // Orbital loader + "ahead" count
            SizedBox(
              width: 120,
              height: 120,
              child: _OrbitalLoader(controller: orbitCtrl, count: aheadCount),
            ),
            const SizedBox(height: 16),
            Text(
              aheadCount == 0 ? 'You\'re first! Ready soon.' : '$aheadCount people ahead of you',
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Clinic stats from snapshot
          if (snapshot != null)
            _StatsRow(totalWaiting: snapshot!.totalWaiting),
        ],
      ),
    );
  }
}

// ── Orbital queue loader ───────────────────────────────────────────────────

class _OrbitalLoader extends StatelessWidget {
  const _OrbitalLoader({required this.controller, required this.count});
  final AnimationController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => CustomPaint(
        painter: _OrbitalPainter(
          progress: controller.value,
          dotCount: count.clamp(1, 8),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OrbitalPainter extends CustomPainter {
  _OrbitalPainter({
    required this.progress,
    required this.dotCount,
    required this.color,
  });

  final double progress;
  final int dotCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final paint = Paint()..color = color;

    for (var i = 0; i < dotCount; i++) {
      final angle = (2 * pi * i / dotCount) + (2 * pi * progress);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final dotR = 5.0 + 3.0 * sin(2 * pi * progress + i);
      canvas.drawCircle(Offset(x, y), dotR, paint);
    }
    // Center dot
    canvas.drawCircle(center, 10, paint..color = color.withAlpha(180));
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) =>
      old.progress != progress || old.dotCount != dotCount;
}

// ── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totalWaiting});
  final int totalWaiting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 20),
          const SizedBox(width: 8),
          Text('$totalWaiting waiting today',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
