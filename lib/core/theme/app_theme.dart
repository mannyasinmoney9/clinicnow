// ClinicNow — design system / theme
// Location: lib/core/theme/app_theme.dart
//
// Fonts: Bricolage Grotesque (display / headlines / big numbers) + Manrope (body / UI).
// Both are free Google Fonts and pulled via the `google_fonts` package (already in pubspec).
//
// OFFLINE-FIRST NOTE: google_fonts downloads on first run and caches. For a guaranteed
// offline app (your 2G/3G users), download the .ttf files into assets/fonts/ and declare
// them in pubspec.yaml, then call GoogleFonts.config.allowRuntimeFetching = false in main().
// pubspec example:
//   fonts:
//     - family: Bricolage Grotesque
//       fonts: [{asset: assets/fonts/BricolageGrotesque-Bold.ttf, weight: 700}, ...]
//     - family: Manrope
//       fonts: [{asset: assets/fonts/Manrope-Regular.ttf, weight: 400}, ...]
//
// If your google_fonts version lacks bricolageGrotesque, run `flutter pub upgrade
// google_fonts`, or swap the display helper to GoogleFonts.spaceGrotesk / GoogleFonts.sora.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Brand colors (raw values — the source of truth lives in the ColorSchemes below)
// ---------------------------------------------------------------------------
abstract final class AppColors {
  // Brand
  static const trustTeal = Color(0xFF0BA5A4); // primary
  static const nairaGreen = Color(0xFF10B981); // confirmation / secondary
  static const waitAmber = Color(0xFFF59E0B); // queue-waiting states
  static const emergencyRed = Color(0xFFDC2626); // emergency + errors

  // Neutrals (light)
  static const offWhite = Color(0xFFF7FBFB); // app background (warm, not sterile)
  static const ink = Color(0xFF0F2A28); // primary text
  static const inkMuted = Color(0xFF5B7472); // secondary text

  // Neutrals (dark)
  static const deepCanvas = Color(0xFF0A1413);
  static const deepSurface = Color(0xFF0C1716);
  static const inkOnDark = Color(0xFFE2EEEC);
  static const mutedOnDark = Color(0xFF9DB3B0);
}

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

// ---------------------------------------------------------------------------
// Theme extension: brand extras the standard ColorScheme can't hold
// (gradient, semantic status colors, the ticket surface).
// Read via context.appColors.
// ---------------------------------------------------------------------------
@immutable
class AppColorsX extends ThemeExtension<AppColorsX> {
  const AppColorsX({
    required this.brandGradient,
    required this.waiting,
    required this.onWaiting,
    required this.success,
    required this.onSuccess,
    required this.emergency,
    required this.onEmergency,
    required this.ticketSurface,
    required this.onTicket,
  });

  final Gradient brandGradient;
  final Color waiting;
  final Color onWaiting;
  final Color success;
  final Color onSuccess;
  final Color emergency;
  final Color onEmergency;
  final Color ticketSurface;
  final Color onTicket;

  static const _gradient = LinearGradient(
    colors: [AppColors.trustTeal, AppColors.nairaGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const light = AppColorsX(
    brandGradient: _gradient,
    waiting: AppColors.waitAmber,
    onWaiting: Color(0xFF5A3D03),
    success: AppColors.nairaGreen,
    onSuccess: Colors.white,
    emergency: AppColors.emergencyRed,
    onEmergency: Colors.white,
    ticketSurface: AppColors.trustTeal,
    onTicket: Colors.white,
  );

  static const dark = AppColorsX(
    brandGradient: _gradient,
    waiting: Color(0xFFFBBF24),
    onWaiting: Color(0xFF3A2A00),
    success: Color(0xFF34D399),
    onSuccess: Color(0xFF00391F),
    emergency: Color(0xFFF87171),
    onEmergency: Color(0xFF450A0A),
    ticketSurface: Color(0xFF0E8E8C),
    onTicket: Colors.white,
  );

  @override
  AppColorsX copyWith({
    Gradient? brandGradient,
    Color? waiting,
    Color? onWaiting,
    Color? success,
    Color? onSuccess,
    Color? emergency,
    Color? onEmergency,
    Color? ticketSurface,
    Color? onTicket,
  }) {
    return AppColorsX(
      brandGradient: brandGradient ?? this.brandGradient,
      waiting: waiting ?? this.waiting,
      onWaiting: onWaiting ?? this.onWaiting,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      emergency: emergency ?? this.emergency,
      onEmergency: onEmergency ?? this.onEmergency,
      ticketSurface: ticketSurface ?? this.ticketSurface,
      onTicket: onTicket ?? this.onTicket,
    );
  }

  @override
  AppColorsX lerp(AppColorsX? other, double t) {
    if (other == null) return this;
    return AppColorsX(
      brandGradient: Gradient.lerp(brandGradient, other.brandGradient, t)!,
      waiting: Color.lerp(waiting, other.waiting, t)!,
      onWaiting: Color.lerp(onWaiting, other.onWaiting, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      emergency: Color.lerp(emergency, other.emergency, t)!,
      onEmergency: Color.lerp(onEmergency, other.onEmergency, t)!,
      ticketSurface: Color.lerp(ticketSurface, other.ticketSurface, t)!,
      onTicket: Color.lerp(onTicket, other.onTicket, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// Color schemes
// ---------------------------------------------------------------------------
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.trustTeal,
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFCFF1EF),
  onPrimaryContainer: Color(0xFF04403E),
  secondary: AppColors.nairaGreen,
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFD1F5E6),
  onSecondaryContainer: Color(0xFF064A36),
  tertiary: AppColors.waitAmber,
  onTertiary: Color(0xFF3A2602),
  tertiaryContainer: Color(0xFFFCEBCB),
  onTertiaryContainer: Color(0xFF5A3D03),
  error: AppColors.emergencyRed,
  onError: Colors.white,
  errorContainer: Color(0xFFFBE0E0),
  onErrorContainer: Color(0xFF5A1212),
  surface: Colors.white,
  onSurface: AppColors.ink,
  onSurfaceVariant: AppColors.inkMuted,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF7FBFB),
  surfaceContainer: Color(0xFFF1F7F6),
  surfaceContainerHigh: Color(0xFFEAF2F1),
  surfaceContainerHighest: Color(0xFFE3EEED),
  outline: Color(0xFFC2D4D2),
  outlineVariant: Color(0xFFDCE8E7),
  inverseSurface: AppColors.ink,
  onInverseSurface: Color(0xFFEAF2F1),
  inversePrimary: Color(0xFF5DD7D4),
  shadow: Colors.black,
  scrim: Colors.black,
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF2DD4D1),
  onPrimary: Color(0xFF003733),
  primaryContainer: Color(0xFF0A6B68),
  onPrimaryContainer: Color(0xFFB6F2EF),
  secondary: Color(0xFF34D399),
  onSecondary: Color(0xFF00391F),
  secondaryContainer: Color(0xFF0B7B57),
  onSecondaryContainer: Color(0xFFC9F7E4),
  tertiary: Color(0xFFFBBF24),
  onTertiary: Color(0xFF3A2A00),
  tertiaryContainer: Color(0xFF7A5400),
  onTertiaryContainer: Color(0xFFFCE9C0),
  error: Color(0xFFF87171),
  onError: Color(0xFF450A0A),
  errorContainer: Color(0xFF7F1D1D),
  onErrorContainer: Color(0xFFFCD9D9),
  surface: AppColors.deepSurface,
  onSurface: AppColors.inkOnDark,
  onSurfaceVariant: AppColors.mutedOnDark,
  surfaceContainerLowest: Color(0xFF070F0E),
  surfaceContainerLow: Color(0xFF0E1A19),
  surfaceContainer: Color(0xFF12201E),
  surfaceContainerHigh: Color(0xFF182725),
  surfaceContainerHighest: Color(0xFF1E2F2D),
  outline: Color(0xFF3A4A48),
  outlineVariant: Color(0xFF243331),
  inverseSurface: AppColors.inkOnDark,
  onInverseSurface: AppColors.ink,
  inversePrimary: AppColors.trustTeal,
  shadow: Colors.black,
  scrim: Colors.black,
);

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
abstract final class AppType {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _display(double size, FontWeight w, Color c,
          {double ls = -0.3, double h = 1.1}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: size, fontWeight: w, letterSpacing: ls, height: h, color: c);

  static TextStyle _body(double size, FontWeight w, Color c,
          {double ls = 0, double h = 1.45}) =>
      GoogleFonts.manrope(
          fontSize: size, fontWeight: w, letterSpacing: ls, height: h, color: c);

  /// Big tabular ticket / vitals / queue numbers. Use directly: AppType.numeric(context).
  static TextStyle numeric(BuildContext context, {double size = 44}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.0,
        fontFeatures: _tabular,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextTheme textTheme(ColorScheme cs) {
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    return TextTheme(
      displayLarge: _display(44, FontWeight.w800, ink, ls: -1.5, h: 1.04),
      displayMedium: _display(36, FontWeight.w800, ink, ls: -1, h: 1.06),
      displaySmall: _display(30, FontWeight.w700, ink, ls: -0.6, h: 1.1),
      headlineLarge: _display(28, FontWeight.w700, ink, ls: -0.5),
      headlineMedium: _display(24, FontWeight.w700, ink, ls: -0.4),
      headlineSmall: _display(20, FontWeight.w700, ink, ls: -0.2),
      titleLarge: _display(18, FontWeight.w700, ink, ls: -0.2),
      titleMedium: _body(16, FontWeight.w600, ink, ls: -0.1),
      titleSmall: _body(14, FontWeight.w600, ink),
      bodyLarge: _body(16, FontWeight.w500, ink, h: 1.5),
      bodyMedium: _body(14, FontWeight.w500, muted, h: 1.45),
      bodySmall: _body(12.5, FontWeight.w500, muted, h: 1.4),
      labelLarge: _body(14, FontWeight.w700, ink, ls: 0.1),
      labelMedium: _body(12, FontWeight.w600, ink),
      labelSmall: _body(11, FontWeight.w600, muted, ls: 0.2),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme assembly
// ---------------------------------------------------------------------------
abstract final class AppTheme {
  static ThemeData light() => _build(_lightScheme, AppColorsX.light, AppColors.offWhite);
  static ThemeData dark() => _build(_darkScheme, AppColorsX.dark, AppColors.deepCanvas);

  static ThemeData _build(ColorScheme cs, AppColorsX x, Color scaffold) {
    final tt = AppType.textTheme(cs);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: tt,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: [x],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: tt.titleLarge,
        systemOverlayStyle: cs.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rLg,
          side: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: tt.labelLarge,
          minimumSize: const Size(64, 56), // 56dp tap target
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
          elevation: 0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: tt.labelLarge,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: tt.labelLarge,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: cs.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: tt.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainer,
        hintStyle: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        border: const OutlineInputBorder(
            borderRadius: AppRadii.rMd, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.rMd, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(color: cs.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(color: cs.error, width: 2)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainer,
        selectedColor: cs.primaryContainer,
        labelStyle: tt.labelMedium,
        side: BorderSide(color: cs.outlineVariant, width: 0.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rSm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        height: 68,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(tt.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
            )),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: tt.labelMedium,
        unselectedLabelTextStyle: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        titleTextStyle: tt.headlineSmall,
        contentTextStyle: tt.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
        showDragHandle: true,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          textStyle: tt.labelMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 0.5,
        space: 0.5,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: tt.titleMedium,
        subtitleTextStyle: tt.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHigh,
        circularTrackColor: cs.surfaceContainerHigh,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience accessors — context.colors / context.text / context.appColors
// ---------------------------------------------------------------------------
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColorsX get appColors => Theme.of(this).extension<AppColorsX>()!;
}
