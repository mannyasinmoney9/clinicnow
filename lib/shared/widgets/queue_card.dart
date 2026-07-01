import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/signature_widgets.dart';

export '../../core/widgets/signature_widgets.dart'
    show QueueStatus, QueueTicketCard, LivePill, LivePulseDot;

/// Animated wrapper around [QueueRow] for use in list screens.
/// The [index] staggers the entrance animation.
class QueueCard extends StatelessWidget {
  const QueueCard({
    super.key,
    required this.name,
    required this.reason,
    required this.ticket,
    required this.status,
    this.waitMins,
    this.live = false,
    this.onTap,
    this.index = 0,
  });

  final String name;
  final String reason;
  final String ticket;
  final QueueStatus status;
  final int? waitMins;
  final bool live;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return QueueRow(
      name: name,
      reason: reason,
      ticket: ticket,
      status: status,
      waitMins: waitMins,
      live: live,
      onTap: onTap,
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: 0.06,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}
