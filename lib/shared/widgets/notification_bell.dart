import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/notification_provider.dart';

// ---------------------------------------------------------------------------
// Bell icon with animated badge — drop into any AppBar actions list
// ---------------------------------------------------------------------------

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleCtrl;
  int _prevUnread = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _wiggleCtrl = AnimationController(vsync: this, duration: 500.ms);
  }

  @override
  void dispose() {
    _removeOverlay();
    _wiggleCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _removeOverlay();
      ref.read(notificationProvider.notifier).markAllRead();
      return;
    }
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _NotificationOverlay(
        topOffset: position.dy + renderBox.size.height + 4,
        onClose: () {
          _removeOverlay();
          ref.read(notificationProvider.notifier).markAllRead();
          setState(() {});
        },
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider);

    // Wiggle bell when a new notification arrives
    if (unread > _prevUnread) {
      _prevUnread = unread;
      _wiggleCtrl.forward(from: 0);
    } else {
      _prevUnread = unread;
    }

    final isOpen = _overlayEntry != null;

    return GestureDetector(
      onTap: _togglePanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _wiggleCtrl,
            builder: (_, child) {
              final angle = (_wiggleCtrl.value < 0.5
                      ? _wiggleCtrl.value
                      : 1 - _wiggleCtrl.value) *
                  0.3;
              return Transform.rotate(angle: angle, child: child);
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen
                    ? AppColors.trustTeal.withAlpha(25)
                    : Colors.transparent,
              ),
              child: Icon(
                isOpen
                    ? Icons.notifications_rounded
                    : Icons.notifications_outlined,
                color: isOpen ? AppColors.trustTeal : null,
                size: 22,
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(
                      begin: 1.0,
                      end: 1.2,
                      duration: 600.ms,
                      curve: Curves.easeInOut)
                  .then()
                  .scaleXY(begin: 1.2, end: 1.0, duration: 600.ms),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The slide-down panel overlay
// ---------------------------------------------------------------------------

class _NotificationOverlay extends ConsumerStatefulWidget {
  const _NotificationOverlay({
    required this.topOffset,
    required this.onClose,
  });

  final double topOffset;
  final VoidCallback onClose;

  @override
  ConsumerState<_NotificationOverlay> createState() =>
      _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: 320.ms);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _slideCtrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Invisible barrier — tap outside to close
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(color: Colors.transparent),
          ),
        ),

        // The panel itself
        Positioned(
          top: widget.topOffset,
          left: 12,
          right: 12,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                shadowColor: AppColors.trustTeal.withAlpha(40),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth - 24,
                    maxHeight: 480,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cs.surface,
                    border: Border.all(
                      color: AppColors.trustTeal.withAlpha(30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PanelHeader(
                        count: notifications.length,
                        onClearAll: () {
                          ref
                              .read(notificationProvider.notifier)
                              .clearAll();
                        },
                        onClose: _dismiss,
                      ),
                      if (notifications.isEmpty)
                        _EmptyNotifications()
                      else
                        Flexible(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            separatorBuilder: (_, i) => Divider(
                              height: 1,
                              color: cs.outlineVariant.withAlpha(80),
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (_, i) => _NotifTile(
                              notif: notifications[i],
                              onDismiss: () => ref
                                  .read(notificationProvider.notifier)
                                  .dismiss(notifications[i].id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Panel header
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.count,
    required this.onClearAll,
    required this.onClose,
  });
  final int count;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.trustTeal.withAlpha(12),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded,
              size: 18, color: AppColors.trustTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 0 ? 'Notifications' : 'Notifications ($count)',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onClose,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single notification tile (swipe-to-dismiss)
// ---------------------------------------------------------------------------

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onDismiss});
  final AppNotification notif;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUnread = !notif.read;
    final timeStr = _formatTime(notif.timestamp);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.emergencyRed.withAlpha(20),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.emergencyRed, size: 20),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        color: isUnread ? AppColors.trustTeal.withAlpha(8) : Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: notif.iconColor.withAlpha(20),
            ),
            child: Icon(notif.icon, color: notif.iconColor, size: 20),
          ),
          title: Text(
            notif.title,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                notif.body,
                style: context.text.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withAlpha(140),
                ),
              ),
            ],
          ),
          trailing: isUnread
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.trustTeal,
                  ),
                )
              : null,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, end: 0, duration: 250.ms);
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(t);
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: context.text.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Queue updates and alerts will appear here',
            style: context.text.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withAlpha(140),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}