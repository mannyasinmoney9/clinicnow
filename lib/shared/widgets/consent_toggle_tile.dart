import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// NDPA-compliant consent toggle. Required toggles cannot be switched off.
/// Never pre-check any toggle — NDPA GAID Article 19.
class ConsentToggleTile extends StatelessWidget {
  const ConsentToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isRequired = false,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    // Required toggles can be turned ON freely but cannot be turned OFF once accepted.
    final canToggle = !(isRequired && value);
    return InkWell(
      onTap: canToggle ? () => onChanged(!value) : null,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: value,
              onChanged: canToggle ? onChanged : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: context.text.titleSmall),
                      ),
                      if (isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: context.text.labelSmall?.copyWith(
                                color: context.colors.onPrimaryContainer),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
