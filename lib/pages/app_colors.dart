// Add this class once — in a shared file e.g. lib/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Call these with context ──────────────
  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color tp(BuildContext context) =>
      Theme.of(context).colorScheme.onBackground;

  static Color ts(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9898B0)
          : const Color(0xFF5A5A7A);

  static Color tm(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF5A5A7A)
          : const Color(0xFF9898B0);

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A42)
          : const Color(0xFFE0E0F0);

  // ── These never change ───────────────────
  static const accent  = Color(0xFF3D7BFF);
  static const green   = Color(0xFF2DD4A0);
  static const red     = Color(0xFFFF5A5A);
  static const amber   = Color(0xFFFFB347);
  static const purple  = Color(0xFFB47FFF);
}