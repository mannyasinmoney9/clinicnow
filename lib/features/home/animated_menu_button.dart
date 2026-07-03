import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class AnimatedMenuButton extends StatefulWidget {
  const AnimatedMenuButton({super.key, required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotateAnim;
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 250.ms);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _ctrl.forward();
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlay = OverlayEntry(
      builder: (_) => _MenuOverlay(
        offset: offset,
        itemSize: renderBox.size,
        onSelected: (v) {
          _close();
          widget.onSelected(v);
        },
        onClose: _close,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    _ctrl.reverse();
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _rotateAnim,
        builder: (_, child) {
          return Transform.rotate(
            angle: _rotateAnim.value * 3.14159,
            child: child,
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.offset,
    required this.itemSize,
    required this.onSelected,
    required this.onClose,
  });

  final Offset offset;
  final Size itemSize;
  final ValueChanged<String> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.translucent,
          child: const SizedBox.expand(),
        ),
        Positioned(
          right: 16,
          top: offset.dy + itemSize.height + 4,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuHeader(context: context),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile & Settings',
                    subtitle: 'Account, theme, language',
                    onTap: () => onSelected('profile'),
                    delay: 0,
                  ),
                  _MenuItem(
                    icon: Icons.system_update_rounded,
                    label: 'System Status',
                    subtitle: 'Health & diagnostics',
                    onTap: () => onSelected('system-status'),
                    delay: 50,
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Preferences',
                    subtitle: 'App configuration',
                    onTap: () => onSelected('settings'),
                    delay: 100,
                  ),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    subtitle: 'ClinicNow v1.0.0-alpha',
                    onTap: () => onSelected('about'),
                    delay: 150,
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    subtitle: 'Sign out of your account',
                    onTap: () => onSelected('logout'),
                    color: AppColors.emergencyRed,
                    delay: 200,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: -0.05, end: 0, duration: 250.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: context.appColors.brandGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu',
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('Quick actions',
                    style: context.text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.delay,
    this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;
  final Color? color;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _hovered
              ? (widget.color ?? Theme.of(context).colorScheme.primary).withAlpha(12)
              : null,
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: fgColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fgColor)),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 200.ms)
        .slideX(begin: 0.05, end: 0, duration: 200.ms);
  }
}
