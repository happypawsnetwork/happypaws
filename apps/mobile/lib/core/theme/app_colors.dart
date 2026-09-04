import 'package:flutter/material.dart';

/// Central color definitions for the Happy Paws mobile application.
abstract final class AppColors {
  /// Primary brand teal color used across key branding and vector assets.
  static const Color primary = Color(0xFF008585);

  /// Primary accent color matching the Happy Paws brand teal.
  static const Color accent = Color(0xFF008585);

  /// Soft lavender background color for the splash screen to match the brand identity.
  static const Color splashBackground = Color(0xFFF6F4F9);

  /// Heart accent color for secondary celebratory highlights.
  static const Color heartPink = Color(0xFFE83D84);

  /// Neutral light surface color.
  static const Color surface = Color(0xFFFFFFFF);

  /// Dark slate color for readable primary body text.
  static const Color textPrimary = Color(0xFF1E293B);

  /// Muted slate color for secondary subtitles and metadata.
  static const Color textSecondary = Color(0xFF64748B);

  /// Success color
  static const Color success = Color(0xFF16A34A);

  /// Error color
  static const Color error = Color(0xFFDC2626);
}

abstract final class PostTypeColors {
  static const Color rescue = Color(0xFFDC2626);
  static const Color update = Color(0xFF0D9488);
  static const Color findHome = Color(0xFFD97706);
  static const Color highlight = Color(0xFF7C3AED);
  static const Color transport = Color(0xFF2563EB);
  static const Color treatment = Color(0xFF16A34A);
  static const Color sponsor = Color(0xFFF59E0B);
}

abstract final class UrgencyColors {
  static const Color criticalBg = Color(0xFFFEF2F2);
  static const Color criticalBorder = Color(0xFFFCA5A5);
  static const Color criticalText = Color(0xFFDC2626);

  static const Color highBg = Color(0xFFFFF7ED);
  static const Color highBorder = Color(0xFFFDBA74);
  static const Color highText = Color(0xFFD97706);

  static const Color mediumBg = Color(0xFFFEFCE8);
  static const Color mediumBorder = Color(0xFFFDE047);
  static const Color mediumText = Color(0xFFCA8A04);

  static const Color lowBg = Color(0xFFF0FDF4);
  static const Color lowBorder = Color(0xFF86EFAC);
  static const Color lowText = Color(0xFF16A34A);

  static const Color unknownBg = Color(0xFFF8FAFC);
  static const Color unknownBorder = Color(0xFFE2E8F0);
  static const Color unknownText = Color(0xFF64748B);
}
