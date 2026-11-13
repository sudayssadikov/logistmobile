import 'package:flutter/material.dart';

/// Typography scale for LogiFlow - Apple Keynote & Liquid Glass Aesthetic
/// Featuring Archivo (wdth 125, weight 800) punchy wordmark / display hierarchy
/// and Geist / SF Pro tight-tracking precision UI typography.
abstract class AppTypography {
  static const List<String> fontFallbacks = [
    'Geist',
    'SF Pro Display',
    'SF Pro Text',
    'Inter',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const List<String> displayFallbacks = [
    'Archivo',
    'Geist',
    'SF Pro Display',
    'Inter',
    'sans-serif',
  ];

  /// Wordmark & Hero Keynote Headline (Archivo Heavy weight 800 aesthetic)
  static const TextStyle wordmark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
    fontFamilyFallback: displayFallbacks,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.9,
    height: 1.18,
    fontFamilyFallback: displayFallbacks,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.22,
    fontFamilyFallback: displayFallbacks,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.15,
    height: 1.4,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
    height: 1.4,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.25,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle monoMetric = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFamily: 'monospace',
    fontFamilyFallback: ['Geist Mono', 'SF Mono', 'Consolas', 'Courier New', 'monospace'],
  );
}

