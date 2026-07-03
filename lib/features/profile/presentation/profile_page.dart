import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/signature_widgets.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/read_aloud_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/coming_soon_sheet.dart';
import '../../auth/presentation/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final readAloud = ref.watch(readAloudEnabledProvider);

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: context.appColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(user?.fullName ?? '?'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ).animate().scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
                const SizedBox(height: 12),
                Text(user?.fullName ?? 'Guest', style: context.text.titleLarge),
                Text(
                  '${user?.role.name.toUpperCase() ?? ''} · ${user?.email ?? ''}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 28),
          Text('Preferences', style: context.text.titleSmall),
          const SizedBox(height: 8),
          _SettingRow(
            icon: Icons.language_rounded,
            title: 'Language',
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'pcm', label: Text('PCM')),
              ],
              selected: {locale.languageCode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(localeProvider.notifier).setLocale(Locale(s.first)),
            ),
          ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
          _SettingRow(
            icon: Icons.dark_mode_rounded,
            title: 'Dark mode',
            subtitle: 'Smooth animated switch',
            highlighted: true,
            trailing: ThemeToggle(
              isDark: themeMode == ThemeMode.dark,
              onChanged: (dark) => ref
                  .read(themeModeProvider.notifier)
                  .set(dark ? ThemeMode.dark : ThemeMode.light),
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 300.ms),
          _SettingRow(
            icon: Icons.volume_up_rounded,
            title: 'Read aloud',
            subtitle: 'For every screen',
            trailing: Switch(
              value: readAloud,
              onChanged: (v) => ref.read(readAloudEnabledProvider.notifier).set(v),
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
          const SizedBox(height: 20),
          Text('Data & privacy', style: context.text.titleSmall),
          const SizedBox(height: 8),
          _SettingRow(
            icon: Icons.download_rounded,
            title: 'Export my data',
            subtitle: 'JSON + PDF',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => ComingSoonSheet.show(
              context,
              title: 'Data export',
              subtitle: 'Your JSON + PDF export will be emailed to you once the backend is connected.',
              icon: Icons.download_rounded,
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
          _SettingRow(
            icon: Icons.delete_outline_rounded,
            title: 'Delete account',
            titleColor: AppColors.emergencyRed,
            iconColor: AppColors.emergencyRed,
            onTap: () => _confirmDelete(context, ref),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emergencyRed,
              side: const BorderSide(color: AppColors.emergencyRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ).animate().fadeIn(delay: 360.ms, duration: 300.ms),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This removes your ClinicNow account and all local data from this device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authProvider.notifier).deleteAccount();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlighted = false,
    this.titleColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: highlighted ? context.colors.primaryContainer : context.colors.surface,
        borderRadius: AppRadii.rMd,
        border: highlighted ? null : Border.all(color: context.colors.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: iconColor ?? (highlighted ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: context.text.titleSmall?.copyWith(color: titleColor)),
                    if (subtitle != null)
                      Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}