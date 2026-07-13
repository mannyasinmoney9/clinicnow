import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.loading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.colors.onPrimary,
        ),
      );
    } else if (widget.icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(widget.label),
        ],
      );
    } else {
      child = Text(widget.label);
    }

    final button = ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown:
            widget.loading || widget.onPressed == null ? null : (_) => _ctrl.forward(),
        onTapUp: widget.loading || widget.onPressed == null
            ? null
            : (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: FilledButton(
          onPressed: widget.loading ? null : widget.onPressed,
          child: child,
        ),
      ),
    );

    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}