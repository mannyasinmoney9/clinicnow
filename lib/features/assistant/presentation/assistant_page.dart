import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../domain/chat_message.dart';
import 'assistant_providers.dart';

// Quick-reply chips shown below the input
const _quickReplies = [
  'I have a headache',
  'I have fever and chills',
  'My chest hurts',
  'I feel short of breath',
  'I need antenatal info',
  'How do I join the queue?',
  'Is malaria serious?',
];

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showChips = true;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() => _showChips = false);
    ref.read(assistantProvider.notifier).send(msg);
    Future.delayed(100.ms, _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(assistantProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final cs = Theme.of(context).colorScheme;

    // Scroll to bottom whenever messages update
    ref.listen(assistantProvider, (_, _) {
      Future.delayed(80.ms, _scrollToBottom);
    });

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.trustTeal,
              child: const Text('A',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nurse Ada',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  isOffline ? 'Offline mode' : 'Online • AI-powered',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOffline ? Colors.orange : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: () {
              ref.read(assistantProvider.notifier).clear();
              setState(() => _showChips = true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline)
            _OfflineBanner()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.5, end: 0, duration: 300.ms),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                return _MessageBubble(
                  key: ValueKey('${msg.createdAt.millisecondsSinceEpoch}_$i'),
                  message: msg,
                );
              },
            ),
          ),
          if (_showChips && messages.length <= 1) _QuickRepliesRow(onTap: _send),
          _InputBar(ctrl: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return _TypingBubble();

    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;

    final bubbleColor = isUser
        ? AppColors.trustTeal
        : _triageColor(message.triageLevel, cs, context);
    final textColor = isUser ? Colors.white : cs.onSurface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 14.5, height: 1.45),
              ),
              if (message.triageLevel == TriageLevel.red) ...[
                const SizedBox(height: 8),
                _EmergencyButton(),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(
          begin: isUser ? 0.15 : -0.15,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Color _triageColor(TriageLevel level, ColorScheme cs, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case TriageLevel.red:
        return isDark ? const Color(0xFF3E1A1A) : const Color(0xFFFFEBEE);
      case TriageLevel.yellow:
        return isDark ? const Color(0xFF3E3210) : const Color(0xFFFFF8E1);
      case TriageLevel.green:
        return isDark ? const Color(0xFF1A3E1E) : const Color(0xFFE8F5E9);
      case TriageLevel.none:
        return cs.surface;
    }
  }
}

// ---------------------------------------------------------------------------
// Typing indicator — 3 animated dots
// ---------------------------------------------------------------------------

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1200.ms)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final bounce = math.sin(
                        (_ctrl.value * 2 * math.pi) - (i * math.pi / 3))
                    .clamp(-1.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, -4 * bounce),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.trustTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Emergency call button (shown on red triage replies)
// ---------------------------------------------------------------------------

class _EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:112');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.emergencyRed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('🚑  Call 112 (Emergency)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withAlpha(60));
  }
}

// ---------------------------------------------------------------------------
// Offline banner
// ---------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: const [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text('Offline mode — rule-based triage only',
              style:
                  TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-reply chips
// ---------------------------------------------------------------------------

class _QuickRepliesRow extends StatelessWidget {
  const _QuickRepliesRow({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ActionChip(
            label: Text(_quickReplies[i],
                style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(_quickReplies[i]),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({required this.ctrl, required this.onSend});
  final TextEditingController ctrl;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a symptom or question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: onSend,
              backgroundColor: AppColors.trustTeal,
              elevation: 0,
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}