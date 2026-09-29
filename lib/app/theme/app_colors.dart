import 'package:flutter/material.dart';

/// Design Tokens for LogiFlow Mobile (Linear/Stripe/Apple Enterprise SaaS Aesthetic)
abstract class AppColors {
  // Brand & Logistics Accents
  static const Color primary = Color(0xFF2563EB); // Logistics Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryMuted = Color(0x1F2563EB);

  static const Color indigo = Color(0xFF4F46E5);
  static const Color emerald = Color(0xFF10B981); // Completed / Escrow Safe
  static const Color emeraldMuted = Color(0x1F10B981);
  static const Color amber = Color(0xFFF59E0B); // In-Transit / Pending / Warning
  static const Color amberMuted = Color(0x1FF59E0B);
  static const Color rose = Color(0xFFEF4444); // Error / Critical / Cancelled
  static const Color roseMuted = Color(0x1FEF4444);
  static const Color cyan = Color(0xFF06B6D4); // Telemetry / Live GPS

  // Dark Theme Palette (Deep Slate / Zinc Space)
  static const Color darkBackground = Color(0xFF090A0F);
  static const Color darkSurface = Color(0xFF12141C);
  static const Color darkSurfaceElevated = Color(0xFF181B26);
  static const Color darkBorder = Color(0xFF1E2230);
  static const Color darkBorderSubtle = Color(0xFF151824);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette (Crisp High-End SaaS)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF12141C), Color(0xFF161924)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient escrowGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
