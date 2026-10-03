import 'package:flutter/material.dart';

/// Centralized color palette for ScanPro.
/// Theme: Premium Deep Emerald Green (#064E3B) with high-contrast text and crisp accents.
class AppColors {
  // Brand Colors (Deep Rich Emerald)
  static const Color primary = Color(0xFF064E3B);
  static const Color primaryPressed = Color(0xFF04382A);
  static const Color primaryLight = Color(0xFF059669);
  static const Color primarySoftTint = Color(0xFFE8F5EE);
  static const Color primaryGradientStart = Color(0xFF064E3B);
  static const Color primaryGradientEnd = Color(0xFF0E7057);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE8ECEF);

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF047857);

  // Feature Accents
  static const Color premiumStart = Color(0xFFFFB800);
  static const Color premiumEnd = Color(0xFFFF7A00);
  static const Color aiAccent = Color(0xFF7C4DFF);
  static const Color aiSoftTint = Color(0xFFF3E8FF);

  // System State Colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0B120E);
  static const Color darkSurface = Color(0xFF131F19);
  static const Color darkSurfaceSecondary = Color(0xFF1B2C24);
  static const Color darkBorder = Color(0xFF233B30);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [premiumStart, premiumEnd],
  );
}
