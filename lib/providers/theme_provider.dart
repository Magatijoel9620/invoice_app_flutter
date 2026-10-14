import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'invoice_easy_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _initialized = false;

  ThemeMode get mode => _mode;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedMode = preferences.getString(_storageKey);

      _mode = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      _mode = ThemeMode.system;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (_) {
      // The theme changes for this session even if saving fails.
    }
  }
}
