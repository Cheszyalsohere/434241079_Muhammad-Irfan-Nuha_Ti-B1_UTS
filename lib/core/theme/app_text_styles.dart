/// Typography tokens — display, headline, title, body, label variants.
///
/// Consumers should read styles from `Theme.of(context).textTheme` in
/// most cases; this class exists for places where a specific style is
/// needed without going through the theme lookup.
library;

import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Builder that returns a `TextTheme` configured for Material 3,
  /// respecting the surface text color passed in.
  static TextTheme textTheme(Color onSurface) {
    final Color muted = onSurface.withValues(alpha: 0.7);
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: onSurface),
      headlineMedium: headlineMedium.copyWith(color: onSurface),
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: muted),
      labelMedium: labelMedium.copyWith(color: muted),
      labelSmall: labelSmall.copyWith(color: muted),
    );
  }
}
