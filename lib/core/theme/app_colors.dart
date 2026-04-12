import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color coral = Color(0xFFFF7A59);
  static const Color mint = Color(0xFF3FD7B4);
  static const Color sky = Color(0xFF79B8FF);
  static const Color blush = Color(0xFFFFD8CB);
  static const Color cream = Color(0xFFFFF3E8);
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD8E2EF);

  static const Color midnight = Color(0xFF0B1017);
  static const Color slate = Color(0xFF141B25);
  static const Color charcoal = Color(0xFF1B2431);
  static const Color neonMint = Color(0xFF43F4C6);
  static const Color neonAmber = Color(0xFFFFB76C);
  static const Color neonSky = Color(0xFF7EB7FF);
  static const Color darkBorder = Color(0xFF2B3748);

  static const Color softRed = Color(0xFFFF5F6D);

  static LinearGradient screenGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B1017), Color(0xFF121A24), Color(0xFF181F2B)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7FAFF), Color(0xFFFFF5EC), Color(0xFFEFFBF9)],
    );
  }

  static List<BoxShadow> softShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.26)
            : const Color(0xFF122033).withValues(alpha: 0.08),
        blurRadius: brightness == Brightness.dark ? 26 : 20,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
