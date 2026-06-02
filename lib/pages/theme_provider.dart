// lib/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true; // default dark

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}