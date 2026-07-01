import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  static const _key = 'theme_dark';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getBool(_key) ?? false) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode == ThemeMode.dark);
  }

  Future<void> toggle() => set(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}
