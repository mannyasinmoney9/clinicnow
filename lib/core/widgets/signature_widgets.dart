// ClinicNow — signature widgets
// Location: lib/core/widgets/signature_widgets.dart
//
// Built on lib/core/theme/app_theme.dart (context.colors / context.text / context.appColors,
// AppRadii, AppSpacing) and flutter_animate. Fix the import below to your package name if
// you prefer a package: import.
//
//   import 'package:flutter_animate/flutter_animate.dart';
//
// Usage examples:
//   QueueTicketCard(ticket: 'A-091', peopleAhead: 3, etaMinutes: 22, progress: .62)
//   ThemeToggle(isDark: mode == ThemeMode.dark, onChanged: (d) => ref.read(themeProvider.notifier).set(d))
//   QuickActionTile(icon: Icons.calendar_month, label: 'Book', subtitle: 'Appointment', tint: QaTint.teal, onTap: ...)
//   QueueRow(name: 'Adaeze Okafor', reason: 'Follow-up: hypertension', ticket: 'A-091', status: QueueStatus.called)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

// ===========================================================================
// LivePulseDot — a small dot with an expanding, fading ring. Reused on the
// ticket hero and the staff board to signal a live realtime connection.
// ===========================================================================
class LivePulseDot extends StatelessWidget {
  const LivePulseDot({super.key, this.color = const Color(0xFF7CFFC4), this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // expanding ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 2.8, duration: 1800.ms, curve: Curves.easeOut)
              .fadeOut(duration: 1800.ms),
          // solid core
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// LivePill — "● Live" badge. Light variant for colored heroes, tinted for
// surfaces.
// ===========================================================================
class LivePill extends StatelessWidget {
  const LivePill({super.key, this.onColored = false});

  final bool onColored;

  @override
  Widget build(BuildContext context) {
    final fg = onColored ? Colors.white : context.colors.primary;
    final bg = onColored
        ? Colors.white.withValues(alpha: 0.18)
        : context.colors.primaryContainer;
    final dot = onColored ? const Color(0xFF7CFFC4) : context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LivePulseDot(color: dot, size: 7),
          const SizedBox(width: 6),
          Text('Live',
              style: context.text.labelSmall?.copyWith(
                  color: onColored ? Colors.white : context.colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ===========================================================================
// QueueTicketCard — the signature hero. Gradient surface, live pill, big
// tabular Bricolage number, people-ahead + ETA, progress bar. Reveal-animates
// on first build.
// ===========================================================================
class QueueTicketCard extends StatelessWidget {
  const QueueTicketCard({
    super.key,
    required this.ticket,
    required this.peopleAhead,
    required this.etaMinutes,
    this.progress = 0.0,
    this.label = 'Your queue ticket',
  });

  final String ticket;
  final int peopleAhead;
  final int etaMinutes;
  final double progress; // 0..1
  final String label;

  @override
  Widget build(BuildContext context) {
    final x = context.appColors;
    final numberStyle = context.text.displayLarge?.copyWith(
      color: x.onTicket,
      letterSpacing: -2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: x.brandGradient,
        borderRadius: AppRadii.rXl,
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: context.text.bodySmall
                      ?.copyWith(color: x.onTicket.withValues(alpha: 0.85))),
              const LivePill(onColored: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(ticket, style: numberStyle),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text('$peopleAhead',
                  style: context.text.titleMedium?.copyWith(color: x.onTicket)),
              const SizedBox(width: 5),
              Text('people ahead',
                  style: context.text.bodySmall
                      ?.copyWith(color: x.onTicket.withValues(alpha: 0.9))),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.schedule, size: 14, color: x.onTicket.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text('~$etaMinutes min',
                  style: context.text.bodySmall?.copyWith(color: x.onTicket)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(
          begin: 0.94,
          end: 1,
          duration: 450.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ===========================================================================
// ThemeToggle — animated sun <-> moon switch. Decoupled from state: pass the
// current value and a callback. Drive your MaterialApp themeMode from that.
// ===========================================================================
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: 56,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? cs.primary.withAlpha(80) : cs.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? cs.primary : cs.shadow).withAlpha(isDark ? 40 : 20),
              blurRadius: isDark ? 8 : 4,
              spreadRadius: isDark ? 1 : 0,
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : context.appColors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF6366F1) : context.colors.primary)
                      .withAlpha(60),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// QuickActionTile — home-grid action. Tinted icon chip + label + subtitle,
// gentle press-scale.
// ===========================================================================
enum QaTint { teal, green, amber, red }

class QuickActionTile extends StatefulWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.tint = QaTint.teal,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final QaTint tint;

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile> {
  bool _down = false;

  (Color, Color) _tints(BuildContext context) {
    final cs = context.colors;
    final x = context.appColors;
    switch (widget.tint) {
      case QaTint.teal:
        return (cs.primaryContainer, cs.onPrimaryContainer);
      case QaTint.green:
        return (cs.secondaryContainer, cs.onSecondaryContainer);
      case QaTint.amber:
        return (cs.tertiaryContainer, x.onWaiting);
      case QaTint.red:
        return (cs.errorContainer, cs.onErrorContainer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final (bg, fg) = _tints(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AppDurations.fast,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.rLg,
            border: Border.all(color: cs.outlineVariant, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, borderRadius: AppRadii.rSm),
                child: Icon(widget.icon, size: 19, color: fg),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(widget.label, style: context.text.titleSmall),
              Text(widget.subtitle, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// StatusBadge — small pill for queue/appointment states.
// ===========================================================================
enum QueueStatus { waiting, called, seen, noShow }

class StatusBadge extends StatelessWidget {
  const StatusBadge.label(this.text, {super.key, required this.kind});

  factory StatusBadge.status(QueueStatus s, {Key? key, int? waitMins}) {
    switch (s) {
      case QueueStatus.waiting:
        return StatusBadge.label(waitMins != null ? '${waitMins}m' : 'Waiting',
            key: key, kind: _BadgeKind.amber);
      case QueueStatus.called:
        return StatusBadge.label('Called', key: key, kind: _BadgeKind.teal);
      case QueueStatus.seen:
        return StatusBadge.label('Seen', key: key, kind: _BadgeKind.green);
      case QueueStatus.noShow:
        return StatusBadge.label('No-show', key: key, kind: _BadgeKind.red);
    }
  }

  final String text;
  final _BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final x = context.appColors;
    final (bg, fg) = switch (kind) {
      _BadgeKind.amber => (cs.tertiaryContainer, x.onWaiting),
      _BadgeKind.teal => (cs.primaryContainer, cs.onPrimaryContainer),
      _BadgeKind.green => (cs.secondaryContainer, cs.onSecondaryContainer),
      _BadgeKind.red => (cs.errorContainer, cs.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

enum _BadgeKind { amber, teal, green, red }

// ===========================================================================
// _Avatar — initials circle from a name.
// ===========================================================================
class _Avatar extends StatelessWidget {
  const _Avatar(this.name);
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
      child: Text(_initials,
          style: context.text.labelLarge?.copyWith(color: context.colors.onPrimaryContainer)),
    );
  }
}

// ===========================================================================
// QueueRow — one entry on the staff board. Avatar, name, reason, ticket,
// status. `live` highlights the currently-called patient.
// ===========================================================================
class QueueRow extends StatelessWidget {
  const QueueRow({
    super.key,
    required this.name,
    required this.reason,
    required this.ticket,
    required this.status,
    this.waitMins,
    this.live = false,
    this.onTap,
  });

  final String name;
  final String reason;
  final String ticket;
  final QueueStatus status;
  final int? waitMins;
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ticketStyle = context.text.titleMedium?.copyWith(
      fontFamily: context.text.titleLarge?.fontFamily, // Bricolage
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: cs.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(
              color: live ? cs.primary : cs.outlineVariant,
              width: live ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              _Avatar(name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                    Text(reason, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ticket, style: ticketStyle),
                  const SizedBox(height: 3),
                  StatusBadge.status(status, waitMins: waitMins),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
