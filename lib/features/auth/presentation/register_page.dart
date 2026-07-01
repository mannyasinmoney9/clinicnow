import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/consent_toggle_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  String _role = 'PATIENT';

  // NDPA consent — never pre-checked
  bool _consentTerms = false;
  bool _consentData = false;
  bool _consentMarketing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentTerms || !_consentData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the required consents to continue.'),
        ),
      );
      return;
    }
    ref.read(authProvider.notifier).register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim(),
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (!context.mounted) return;
      if (next is AuthAuthenticated) {
        context.go(
            next.user.isStaffOrAdmin ? '/home/staff' : '/home/patient');
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError ? authState.message : null;

    return Scaffold(
      appBar: AppBar(title: Text(s.signUp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.fullName,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: '${s.phone} (optional)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Role selector
                    Text(s.patientOrStaff,
                        style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'PATIENT',
                          label: Text(s.iAmPatient),
                          icon: const Icon(Icons.person_rounded),
                        ),
                        ButtonSegment(
                          value: 'STAFF',
                          label: Text(s.iAmStaff),
                          icon: const Icon(Icons.medical_services_outlined),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (v) =>
                          setState(() => _role = v.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // NDPA consent section
              Text('Data consent (NDPA)',
                  style: context.text.titleSmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              ConsentToggleTile(
                title: s.ndpaTerms,
                subtitle: s.ndpaTermsSub,
                value: _consentTerms,
                isRequired: true,
                onChanged: (v) => setState(() => _consentTerms = v),
              ),
              ConsentToggleTile(
                title: s.ndpaData,
                subtitle: s.ndpaDataSub,
                value: _consentData,
                isRequired: true,
                onChanged: (v) => setState(() => _consentData = v),
              ),
              ConsentToggleTile(
                title: s.ndpaMarketing,
                value: _consentMarketing,
                onChanged: (v) => setState(() => _consentMarketing = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (errorMsg != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.errorContainer,
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Text(errorMsg,
                      style: context.text.bodySmall?.copyWith(
                          color: context.colors.onErrorContainer)),
                ).animate().fadeIn(duration: 300.ms),
              PrimaryButton(
                label: s.signUp,
                loading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(s.alreadyHaveAccount),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ).animate().fadeIn(duration: 350.ms),
        ),
      ),
    );
  }
}
