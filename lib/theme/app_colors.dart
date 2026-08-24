import 'package:flutter/material.dart';

/// Single source of truth for the app's palette. Previously these values
/// were declared locally inside `main.dart`'s `_buildTheme()` and then
/// re-typed as raw hex literals in every screen — centralizing them here
/// means a rebrand is a one-file change instead of a project-wide grep.
class AppColors {
  AppColors._();

  // Navy + teal to match the "Prove It" logo. These are a visual estimate
  // from the logo image, not sampled hex values from a brand guideline —
  // swap them for exact values if/when those are available.
  static const navy = Color(0xFF153D5C);
  static const midNavy = Color(0xFF1F5478);
  static const lightNavy = Color(0xFF2E86AB);
  static const accent = Color(0xFF17B8C4);
  static const background = Color(0xFFFFFFFF);
  static const subBackground = Color(0xFFF4F6F9);
  static const mainText = Color(0xFF153D5C);
  static const otherText = Color(0xFF7F8C8D);
  static const border = Color(0xFFDCE3EA);
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
}
