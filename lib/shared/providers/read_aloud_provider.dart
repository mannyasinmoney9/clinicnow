import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global "read aloud enabled" preference, surfaced in Settings and honored
/// by [ReadAloudButton]-bearing screens.
final readAloudEnabledProvider =
    StateNotifierProvider<ReadAloudNotifier, bool>((ref) => ReadAloudNotifier());

class ReadAloudNotifier extends StateNotifier<bool> {
  ReadAloudNotifier() : super(true) {
    _load();
  }

  static const _key = 'read_aloud_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}