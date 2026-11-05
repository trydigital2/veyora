import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF7057E8);
  static const primaryDark = Color(0xFF5B44C9);
  static const secondary = Color(0xFFA78BFA);
  static const lavender = Color(0xFFEDE9FE);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8F7FC);
  static const card = Color(0xFFFFFFFF);
  static const dark = Color(0xFF111827);
  static const darkSurface = Color(0xFF0B1020);
  static const darkCard = Color(0xFF1A2233);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const ink = Color(0xFF1C1B2E);
  static const inkMuted = Color(0xFF6B7280);
  static const outline = Color(0xFFE7E4F2);
  static const star = Color(0xFFFBBF24);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7057E8), Color(0xFF8F7BF2), Color(0xFFA78BFA)],
  );

  static const deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1E6E), Color(0xFF4C35B8), Color(0xFF7057E8)],
  );

  static const mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5A4), Color(0xFF34D399)],
  );

  static const peachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
  );

  static const roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  );

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
  );

  static List<Color> scoreColors(int score) {
    if (score >= 80) return const [Color(0xFF10B981), Color(0xFF34D399)];
    if (score >= 60) return const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
    return const [Color(0xFFEF4444), Color(0xFFF97316)];
  }
}
