import 'package:flutter/material.dart';

/// Apple Keynote & Liquid Glass Shadow & Specular Calculations
abstract class NeuShadows {
  /// Standard Elevation for Apple Keynote Bento surfaces and Glass cards
  /// Generates a layered ambient occlusion shadow instead of bulky neumorphism.
  static List<BoxShadow> elevation({
    required bool isDark,
    bool isPressed = false,
    double distance = 8.0,
    double blur = 16.0,
    double? offset,
  }) {
    if (isPressed) {
      if (isDark) {
        return const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ];
      } else {
        return const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ];
      }
    }

    if (isDark) {
      return [
        const BoxShadow(
          color: Color(0x40000000),
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
        const BoxShadow(
          color: Color(0x1F000000),
          offset: Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
    }

    return [
      const BoxShadow(
        color: Color(0x0A000000),
        offset: Offset(0, 10),
        blurRadius: 28,
        spreadRadius: -4,
      ),
      const BoxShadow(
        color: Color(0x05000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
  }

  /// Inset shadows / subtle pressed reaction
  static List<BoxShadow> inset({required bool isDark}) {
    return elevation(isDark: isDark, isPressed: true);
  }

  /// Liquid Glass outer specular glow (subtle refraction)
  static List<BoxShadow> glassGlow({required bool isDark}) {
    return [
      BoxShadow(
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000),
        offset: const Offset(0, 4),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ];
  }
}

