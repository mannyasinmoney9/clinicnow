import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/pcm_delegate.dart';
import '../core/theme/app_theme.dart';
import '../shared/providers/locale_provider.dart';
import '../shared/providers/theme_provider.dart';
import 'router.dart';

class ClinicNowApp extends ConsumerWidget {
  const ClinicNowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ClinicNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('pcm')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        PcmMaterialLocalizationsDelegate(),
        PcmCupertinoLocalizationsDelegate(),
        PcmWidgetsLocalizationsDelegate(),
      ],
      routerConfig: router,
    );
  }
}

void configureApp() {}
