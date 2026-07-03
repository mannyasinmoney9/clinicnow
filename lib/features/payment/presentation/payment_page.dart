import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/primary_button.dart';

enum _PayStage { choosing, processing, success }

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    this.amountNaira = 2000,
    this.label = 'Dr. Bello · video consult',
    this.onSuccessRoute,
  });

  final int amountNaira;
  final String label;
  final String? onSuccessRoute;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  _PayStage _stage = _PayStage.choosing;
  int _method = 0; // 0 = card, 1 = bank/USSD
  late final String _reference;

  @override
  void initState() {
    super.initState();
    _reference = 'CLN-${Random().nextInt(900000) + 100000}';
  }

  Future<void> _pay() async {
    setState(() => _stage = _PayStage.processing);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _stage = _PayStage.success);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never let the Android back button dump the user out mid-payment.
      canPop: _stage != _PayStage.processing,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: _stage == _PayStage.choosing
            ? AppBar(leading: const AppBackButton(), title: const Text('Teleconsult fee'))
            : null,
        body: switch (_stage) {
        _PayStage.choosing => _ChoosingView(
            amountNaira: widget.amountNaira,
            label: widget.label,
            method: _method,
            onMethodChanged: (m) => setState(() => _method = m),
            onPay: _pay,
          ),
        _PayStage.processing => const _ProcessingView(),
        _PayStage.success => _SuccessView(
            amountNaira: widget.amountNaira,
            reference: _reference,
            label: widget.label,
            onContinue: () {
              if (widget.onSuccessRoute != null) {
                context.go(widget.onSuccessRoute!);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home/patient');
              }
            },
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ChoosingView extends StatelessWidget {
  const _ChoosingView({
    required this.amountNaira,
    required this.label,
    required this.method,
    required this.onMethodChanged,
    required this.onPay,
  });

  final int amountNaira;
  final String label;
  final int method;
  final ValueChanged<int> onMethodChanged;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final naira = NumberFormat.decimalPattern('en_NG').format(amountNaira);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: context.appColors.brandGradient,
              borderRadius: AppRadii.rXl,
            ),
            child: Column(
              children: [
                Text('Amount to pay',
                    style: context.text.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('₦$naira',
                    style: context.text.displayLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.94, end: 1, duration: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          _MethodTile(
            icon: Icons.credit_card_rounded,
            title: 'Card',
            subtitle: 'Visa, Verve, Mastercard',
            selected: method == 0,
            onTap: () => onMethodChanged(0),
          ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
          const SizedBox(height: 10),
          _MethodTile(
            icon: Icons.account_balance_rounded,
            title: 'Bank transfer / USSD',
            subtitle: 'Pay with your bank app',
            selected: method == 1,
            onTap: () => onMethodChanged(1),
          ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
          const Spacer(),
          PrimaryButton(label: 'Pay ₦$naira', onPressed: onPay)
              .animate()
              .fadeIn(delay: 300.ms, duration: 350.ms),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 13, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Verified on our server, not the client',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.base,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryContainer : context.colors.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outlineVariant,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (selected ? context.colors.primary : AppColors.trustTeal).withAlpha(30),
                borderRadius: AppRadii.rSm,
              ),
              child: Icon(icon, size: 20, color: AppColors.trustTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? context.colors.primary : context.colors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 4, color: context.colors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Processing payment…', style: context.text.titleMedium)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 700.ms)
              .then()
              .fadeOut(duration: 700.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.amountNaira,
    required this.reference,
    required this.label,
    required this.onContinue,
  });

  final int amountNaira;
  final String reference;
  final String label;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final naira = NumberFormat.decimalPattern('en_NG').format(amountNaira);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.appColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 54, color: context.appColors.success),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.xl),
            Text('Payment successful ✅',
                    style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
                .animate()
                .fadeIn(delay: 150.ms, duration: 350.ms),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: AppRadii.rLg,
              ),
              child: Column(
                children: [
                  _ReceiptRow(label: 'Amount', value: '₦$naira'),
                  _ReceiptRow(label: 'For', value: label),
                  _ReceiptRow(label: 'Reference', value: reference),
                  _ReceiptRow(
                      label: 'Date', value: DateFormat('d MMM y · h:mm a').format(DateTime.now())),
                  _ReceiptRow(label: 'Status', value: 'Verified ✓', valueColor: AppColors.nairaGreen),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 350.ms),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Continue', onPressed: onContinue)
                .animate()
                .fadeIn(delay: 350.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.text.bodySmall),
          Flexible(
            child: Text(
              value,
              style: context.text.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: valueColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}