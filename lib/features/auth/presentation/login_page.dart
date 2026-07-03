import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/consent_toggle_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_providers.dart';

// ---------------------------------------------------------------------------
// Combined Auth Page — Login  +  Sign Up tabs
// ---------------------------------------------------------------------------

enum AuthMode { login, signup }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialMode = AuthMode.login});
  final AuthMode initialMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _ecgCtrl;
  late final AnimationController _glowCtrl;

  // Login fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;
  bool _hasSavedCreds = false;
  String _savedEmail = '';

  // Sign-up fields
  final _regFormKey = GlobalKey<FormState>();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  bool _regObscure = true;
  String _role = 'PATIENT';
  bool _consentTerms = false;
  bool _consentData = false;
  bool _consentMarketing = false;

  // Per-tab loading/error state — prevents login errors leaking into signup tab
  String? _loginError;
  String? _signupError;
  bool _loginLoading = false;
  bool _signupLoading = false;
  int _lastSubmitTab = 0; // which tab most recently submitted

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialMode == AuthMode.signup ? 1 : 0,
    );
    _ecgCtrl = AnimationController(vsync: this, duration: 2000.ms)..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: 1800.ms)
      ..repeat(reverse: true);
    _loadSavedCredentials();
    // Clear error banners when user switches tabs
    _tabCtrl.addListener(() {
      if (mounted) setState(() { _loginError = null; _signupError = null; });
    });
  }

  Future<void> _loadSavedCredentials() async {
    final repo = ref.read(authRepositoryProvider);
    final creds = await repo.getSavedCredentials();
    if (creds != null && mounted) {
      setState(() {
        _hasSavedCreds = true;
        _savedEmail = creds.$1;
        _loginEmailCtrl.text = creds.$1;
        _loginPassCtrl.text = creds.$2;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ecgCtrl.dispose();
    _glowCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regPhoneCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _loginLoading = true; _loginError = null; _lastSubmitTab = 0; });
    ref
        .read(authProvider.notifier)
        .login(_loginEmailCtrl.text.trim(), _loginPassCtrl.text);
  }

  void _submitRegister() {
    if (!_regFormKey.currentState!.validate()) return;
    if (!_consentTerms || !_consentData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the required consents to continue.'),
        ),
      );
      return;
    }
    setState(() { _signupLoading = true; _signupError = null; _lastSubmitTab = 1; });
    ref
        .read(authProvider.notifier)
        .register(
          fullName: _regNameCtrl.text.trim(),
          email: _regEmailCtrl.text.trim(),
          password: _regPassCtrl.text,
          phone: _regPhoneCtrl.text.trim(),
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (!context.mounted) return;
      if (next is AuthAuthenticated) {
        setState(() { _loginLoading = false; _signupLoading = false; });
        _routeByRole(next);
      } else if (next is AuthRegistered) {
        setState(() { _signupLoading = false; });
        context.go(
          '/otp',
          extra: {'email': next.email, 'otpCode': next.otpCode},
        );
      } else if (next is AuthError) {
        setState(() {
          if (_lastSubmitTab == 0) {
            _loginLoading = false;
            _loginError = next.message;
          } else {
            _signupLoading = false;
            _signupError = next.message;
          }
        });
      } else if (next is AuthUnauthenticated) {
        setState(() { _loginLoading = false; _signupLoading = false; });
      }
    });

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ---- Animated header ----
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ecgCtrl, _glowCtrl]),
              builder: (_, _) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.30,
                width: double.infinity,
                child: CustomPaint(
                  painter: _AuthHeaderPainter(
                    ecgProgress: _ecgCtrl.value,
                    glowIntensity: _glowCtrl.value,
                  ),
                ),
              ),
            ),
          ),

          // ---- Tab bar ----
          Container(
            color: cs.surface,
            child: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Login'),
                Tab(text: 'Sign Up'),
              ],
              indicatorColor: AppColors.trustTeal,
              labelColor: AppColors.trustTeal,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          // ---- Forms ----
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _LoginForm(
                  formKey: _loginFormKey,
                  emailCtrl: _loginEmailCtrl,
                  passCtrl: _loginPassCtrl,
                  obscure: _loginObscure,
                  onToggleObscure: () =>
                      setState(() => _loginObscure = !_loginObscure),
                  onSubmit: _submitLogin,
                  isLoading: _loginLoading,
                  errorMsg: _loginError,
                  hasSavedCreds: _hasSavedCreds,
                  savedEmail: _savedEmail,
                  onSignUpTap: () => _tabCtrl.animateTo(1),
                ),
                _SignUpForm(
                  formKey: _regFormKey,
                  nameCtrl: _regNameCtrl,
                  emailCtrl: _regEmailCtrl,
                  passCtrl: _regPassCtrl,
                  phoneCtrl: _regPhoneCtrl,
                  obscure: _regObscure,
                  onToggleObscure: () =>
                      setState(() => _regObscure = !_regObscure),
                  role: _role,
                  onRoleChanged: (v) => setState(() => _role = v),
                  consentTerms: _consentTerms,
                  consentData: _consentData,
                  consentMarketing: _consentMarketing,
                  onConsentTerms: (v) => setState(() => _consentTerms = v),
                  onConsentData: (v) => setState(() => _consentData = v),
                  onConsentMarketing: (v) =>
                      setState(() => _consentMarketing = v),
                  onSubmit: _submitRegister,
                  isLoading: _signupLoading,
                  errorMsg: _signupError,
                  onLoginTap: () => _tabCtrl.animateTo(0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _routeByRole(AuthAuthenticated auth) {
    final role = auth.user.role;
    if (role.name == 'admin') {
      context.go('/home/admin');
    } else if (auth.user.isStaffOrAdmin) {
      context.go('/home/staff');
    } else {
      context.go('/home/patient');
    }
  }
}

// ---------------------------------------------------------------------------
// Login form tab
// ---------------------------------------------------------------------------

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.isLoading,
    required this.errorMsg,
    required this.hasSavedCreds,
    required this.savedEmail,
    required this.onSignUpTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMsg;
  final bool hasSavedCreds;
  final String savedEmail;
  final VoidCallback onSignUpTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  'Welcome back 👋',
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Sign in to your ClinicNow account',
              style: context.text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

            // Saved credentials chip
            if (hasSavedCreds) ...[
              const SizedBox(height: 16),
              _SavedCredChip(
                email: savedEmail,
              ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
            ],

            const SizedBox(height: 20),

            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
            const SizedBox(height: 14),

            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            if (errorMsg != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: errorMsg!),
            ],

            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Login',
              loading: isLoading,
              onPressed: onSubmit,
            ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: onSignUpTap,
                child: const Text("Don't have an account? Sign Up"),
              ),
            ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-up form tab
// ---------------------------------------------------------------------------

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.phoneCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.role,
    required this.onRoleChanged,
    required this.consentTerms,
    required this.consentData,
    required this.consentMarketing,
    required this.onConsentTerms,
    required this.onConsentData,
    required this.onConsentMarketing,
    required this.onSubmit,
    required this.isLoading,
    required this.errorMsg,
    required this.onLoginTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController phoneCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final bool consentTerms;
  final bool consentData;
  final bool consentMarketing;
  final ValueChanged<bool> onConsentTerms;
  final ValueChanged<bool> onConsentData;
  final ValueChanged<bool> onConsentMarketing;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  'Create account',
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Join ClinicNow — your health starts here',
              style: context.text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
            const SizedBox(height: 20),

            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 12),

            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ).animate().fadeIn(delay: 130.ms, duration: 400.ms),
            const SizedBox(height: 12),

            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
            const SizedBox(height: 12),

            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ).animate().fadeIn(delay: 190.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Role selector
            Text(
              'I am a...',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 210.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Row(
              children: [
                _RoleChip(
                  label: '🤒  Patient',
                  selected: role == 'PATIENT',
                  onTap: () => onRoleChanged('PATIENT'),
                  color: AppColors.trustTeal,
                ),
                const SizedBox(width: 10),
                _RoleChip(
                  label: '🩺  Staff',
                  selected: role == 'STAFF',
                  onTap: () => onRoleChanged('STAFF'),
                  color: AppColors.nairaGreen,
                ),
              ],
            ).animate().fadeIn(delay: 230.ms, duration: 400.ms),
            const SizedBox(height: 20),

            // NDPA Consent
            Text(
              'Data Consent (NDPA)',
              style: context.text.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 8),
            ConsentToggleTile(
              title: 'Terms & Privacy',
              subtitle: 'I agree to ClinicNow terms and privacy policy',
              value: consentTerms,
              isRequired: true,
              onChanged: onConsentTerms,
            ).animate().fadeIn(delay: 270.ms, duration: 400.ms),
            ConsentToggleTile(
              title: 'Health data processing',
              subtitle: 'Allow ClinicNow to process my health data for care',
              value: consentData,
              isRequired: true,
              onChanged: onConsentData,
            ).animate().fadeIn(delay: 290.ms, duration: 400.ms),
            ConsentToggleTile(
              title: 'Health tips & reminders',
              subtitle: 'Receive optional health notifications',
              value: consentMarketing,
              onChanged: onConsentMarketing,
            ).animate().fadeIn(delay: 310.ms, duration: 400.ms),

            if (errorMsg != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: errorMsg!),
            ],

            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create Account',
              loading: isLoading,
              onPressed: onSubmit,
            ).animate().fadeIn(delay: 340.ms, duration: 400.ms),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: onLoginTap,
                child: const Text('Already have an account? Login'),
              ),
            ).animate().fadeIn(delay: 360.ms, duration: 400.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role selection chip
// ---------------------------------------------------------------------------

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child:
            AnimatedContainer(
                  duration: 250.ms,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withAlpha(selected ? 0 : 60),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                )
                .animate(target: selected ? 1 : 0)
                .scaleXY(begin: 1.0, end: 1.03, duration: 150.ms),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved credentials chip
// ---------------------------------------------------------------------------

class _SavedCredChip extends StatelessWidget {
  const _SavedCredChip({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.nairaGreen.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.nairaGreen.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 16, color: AppColors.nairaGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Saved credentials for $email',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.nairaGreen,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.nairaGreen,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: context.text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .shake(hz: 3, offset: const Offset(4, 0), duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// Animated ECG header painter
// ---------------------------------------------------------------------------

class _AuthHeaderPainter extends CustomPainter {
  const _AuthHeaderPainter({
    required this.ecgProgress,
    required this.glowIntensity,
  });
  final double ecgProgress;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF040E0D), Color(0xFF0A2928), Color(0xFF061918)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow orbs
    for (int i = 0; i < 2; i++) {
      final x = i == 0 ? cx * 0.6 : cx * 1.4;
      final glow = Paint()
        ..color = (i == 0 ? AppColors.trustTeal : AppColors.nairaGreen)
            .withAlpha((20 + 15 * glowIntensity).toInt());
      canvas.drawCircle(Offset(x, cy), size.width * 0.3, glow);
    }

    // Medical cross in center
    final crossGlow = Paint()
      ..color = AppColors.nairaGreen.withAlpha(
        (30 + 20 * glowIntensity).toInt(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final crossFill = Paint()..color = AppColors.nairaGreen.withAlpha(180);
    const t = 12.0;
    final crossPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 56, height: t),
          const Radius.circular(4),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: t, height: 56),
          const Radius.circular(4),
        ),
      );
    canvas.drawPath(crossPath, crossGlow);
    canvas.drawPath(crossPath, crossFill);

    // ECG trace
    _drawEcg(canvas, size);

    // Fade-to-surface bottom edge
    final fadePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFFF7FBFB),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.65,
              size.width,
              size.height * 0.35,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35),
      fadePaint,
    );
  }

  void _drawEcg(Canvas canvas, Size size) {
    const pts = [
      (0.00, 0.00),
      (0.06, 0.00),
      (0.10, -0.08),
      (0.14, 0.00),
      (0.22, 0.00),
      (0.26, -0.12),
      (0.28, -0.85),
      (0.30, -1.00),
      (0.32, 0.40),
      (0.34, 0.00),
      (0.40, 0.00),
      (0.46, -0.18),
      (0.52, 0.00),
      (0.65, 0.00),
      (1.00, 0.00),
    ];

    final baseY = size.height * 0.75;
    final amp = size.height * 0.18;
    final w = size.width;

    final paint = Paint()
      ..color = AppColors.nairaGreen.withAlpha(200)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int copy = -1; copy <= 1; copy++) {
      final dx = (ecgProgress + copy) * w;
      final path = Path();
      path.moveTo(dx + pts[0].$1 * w, baseY + pts[0].$2 * amp);
      for (final (x, y) in pts.skip(1)) {
        path.lineTo(dx + x * w, baseY + y * amp);
      }
      canvas.drawPath(path, paint);
    }

    // Edge fade
    final fadePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF040E0D),
          Colors.transparent,
          Colors.transparent,
          const Color(0xFF040E0D),
        ],
        stops: const [0.0, 0.06, 0.94, 1.0],
      ).createShader(Rect.fromLTWH(0, baseY - amp * 1.5, w, amp * 3));
    canvas.drawRect(Rect.fromLTWH(0, baseY - amp * 1.5, w, amp * 3), fadePaint);
  }

  @override
  bool shouldRepaint(_AuthHeaderPainter old) =>
      old.ecgProgress != ecgProgress || old.glowIntensity != glowIntensity;
}
