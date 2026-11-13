import 'package:flutter/material.dart';

/// Design Tokens for LogiFlow Mobile - Apple Keynote & iOS Liquid Glass Direction
/// Inspired by: Warm off-white canvas, Deep Black UI, iOS Liquid Glass surfaces.
abstract class AppColors {
  // --- Apple Keynote Light Palette (Warm off-white & crisp surfaces) ---
  static const Color lightBackground = Color(0xFFFBFBF9); // Warm off-white canvas
  static const Color lightCanvasWarm = Color(0xFFF6F6F2); // Subtle warm accent canvas
  static const Color lightSurface = Color(0xFFFFFFFF);     // Crisp pure card surface
  static const Color lightSurfaceGlass = Color(0xCCFFFFFF); // 80% Frosted Liquid Glass
  static const Color lightSurfacePressed = Color(0xFFF0F0EB);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF0D0D0E);   // Sharp obsidian black
  static const Color lightTextSecondary = Color(0xFF555B63);
  static const Color lightTextMuted = Color(0xFF878D96);

  // Glass & Ambient Specular Highlights (Replaces bulky neumorphism)
  static const Color lightShadowLight = Color(0x40FFFFFF);
  static const Color lightShadowDark = Color(0x0F000000);
  static const Color lightAmbientShadow = Color(0x0A000000);
  static const Color lightGlassHighlight = Color(0x66FFFFFF);

  // --- Apple Keynote Dark Palette (Deep Obsidian & Liquid Glass) ---
  static const Color darkBackground = Color(0xFF0B0B0D);    // Deep obsidian
  static const Color darkCanvasDeep = Color(0xFF111114);
  static const Color darkSurface = Color(0xFF161619);       // Subtle deep card surface
  static const Color darkSurfaceGlass = Color(0xCC161619);  // Frosted dark glass
  static const Color darkSurfacePressed = Color(0xFF1F1F24);
  static const Color darkSurfaceElevated = Color(0xFF202025);

  static const Color darkTextPrimary = Color(0xFFF8F8F9);
  static const Color darkTextSecondary = Color(0xFF9CA0A9);
  static const Color darkTextMuted = Color(0xFF676A73);

  static const Color darkShadowLight = Color(0x0DFFFFFF);
  static const Color darkShadowDark = Color(0x40000000);
  static const Color darkAmbientShadow = Color(0x33000000);
  static const Color darkGlassHighlight = Color(0x1AFFFFFF);

  // --- Brand & Black UI Elements ---
  static const Color primary = Color(0xFF0D0D0E);        // Jet Black UI
  static const Color primaryDark = Color(0xFF000000);    // Absolute black
  static const Color primaryLight = Color(0xFF26262A);
  static const Color primaryMuted = Color(0x140D0D0E);   // 8% pill tint

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D0D0E), Color(0xFF26262B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral grays & borders
  static const Color neutral = Color(0xFF555B63);
  static const Color neutralLight = Color(0xFF8E95A0);
  static const Color neutralBorder = Color(0xFFE5E5DF);  // Hairline warm border

  // Status & Telemetry - Crisp, un-glowing Keynote signals
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldMuted = Color(0x1A10B981);

  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberMuted = Color(0x1AF59E0B);

  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color rose = Color(0xFFEF4444);
  static const Color roseMuted = Color(0x1AEF4444);

  // Aliases strictly mapped to monochrome
  static const Color cyan = Color(0xFF555B63);
  static const Color indigo = Color(0xFF0D0D0E);
  static const Color blue = Color(0xFF0D0D0E);
  static const Color purple = Color(0xFF0D0D0E);

  // Micro Hairline Borders (Crisp 1px / 0.5px Apple edges)
  static const Color lightBorder = Color(0xFFE7E7E1);
  static const Color lightBorderSubtle = Color(0xFFF0F0EB);
  static const Color darkBorder = Color(0xFF26262B);
  static const Color darkBorderSubtle = Color(0xFF1E1E23);

  // Glass Specular Borders
  static const Color glassBorderLight = Color(0x1A000000);
  static const Color glassBorderHighlightLight = Color(0x80FFFFFF);
  static const Color glassBorderDark = Color(0x26FFFFFF);
  static const Color glassBorderHighlightDark = Color(0x40FFFFFF);

  /// Elevation helper mapping to Keynote & Liquid Glass depth
  static List<BoxShadow> neuElevation({
    required bool isDark,
    bool isPressed = false,
    double distance = 8.0,
    double blur = 16.0,
    double? offset,
  }) {
    if (isPressed) {
      return [
        BoxShadow(
          color: isDark ? const Color(0x33000000) : const Color(0x0A000000),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      BoxShadow(
        color: isDark ? const Color(0x38000000) : const Color(0x0A000000),
        offset: const Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: isDark ? const Color(0x1A000000) : const Color(0x05000000),
        offset: const Offset(0, 2),
        blurRadius: 6,
      ),
    ];
  }
}
