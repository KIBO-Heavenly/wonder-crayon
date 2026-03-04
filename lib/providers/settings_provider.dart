//settings_provider.dart
// ============================================================================
// Settings Provider
//
// FIX:
//  _loadSettings() is async but was called from the constructor with no
//  loading guard. This meant the very first frame always rendered with the
//  default values (isDarkMode: false, isSwipeEnabled: true) before prefs
//  were read, causing a brief light-mode flash for users who had dark mode
//  enabled. A _loaded flag is now exposed via isLoaded so that any widget
//  depending on these settings can defer rendering until prefs are ready.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {

  bool _isDarkMode = false;
  bool _isSwipeEnabled = true;

  // FIX: loading guard
  bool _loaded = false;
  bool get isLoaded => _loaded;

  bool get isDarkMode => _isDarkMode;
  bool get isSwipeEnabled => _isSwipeEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isSwipeEnabled = prefs.getBool('isSwipeEnabled') ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleSwipe() async {
    _isSwipeEnabled = !_isSwipeEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSwipeEnabled', _isSwipeEnabled);
    notifyListeners();
  }

  Color get primaryGradientStart => _isDarkMode
      ? const Color(0xFF0D0221)
      : const Color(0xFF667eea);

  Color get primaryGradientEnd => _isDarkMode
      ? const Color(0xFF1A0533)
      : const Color(0xFF764ba2);

  Color get accentColor => const Color(0xFF00D9FF);

  Color get secondaryGradientStart => const Color(0xFF6B73FF);
  Color get secondaryGradientEnd => const Color(0xFF000DFF);

  Color get textColor => Colors.white;
  Color get backgroundColor =>
      _isDarkMode ? const Color(0xFF0D0221) : const Color(0xFFF8F9FE);
  Color get cardColor =>
      _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
  Color get textOnCardColor =>
      _isDarkMode ? Colors.white : const Color(0xFF2D3436);
  Color get particleColor =>
      _isDarkMode ? Colors.white24 : Colors.white70;
  Color get indicatorColor =>
      _isDarkMode ? const Color(0xFF00D9FF) : const Color(0xFF667eea);

  Color get buttonColor => const Color(0xFF667eea);
  Color get successColor => const Color(0xFF00B894);
  Color get errorColor => const Color(0xFFE17055);
  Color get surfaceColor =>
      _isDarkMode ? const Color(0xFF16213E) : Colors.white;
}