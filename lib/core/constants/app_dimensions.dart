import 'package:flutter/material.dart';

/// Centralized dimensions, radius and spacing tokens for ScanPro.
class AppDimensions {
  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius roundedButton = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Element Heights & Sizes
  static const double buttonHeightCta = 56.0;
  static const double buttonHeightSm = 44.0;
  static const double searchBarHeight = 48.0;
  static const double scanButtonSize = 64.0;
  static const double bottomNavHeight = 70.0;

  // Spacing & Padding
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
}
