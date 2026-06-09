import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary     = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary   = Color(0xFF6366F1);

  // Backgrounds
  static const Color bgDark      = Color(0xFF0F1623);
  static const Color surfaceDark = Color(0xFF162032);
  static const Color surface2Dark= Color(0xFF1C2A3A);
  static const Color borderDark  = Color(0xFF1E3048);

  static const Color bgLight      = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light= Color(0xFFF8FAFC);
  static const Color borderLight  = Color(0xFFE2E8F0);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color danger  = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color purple  = Color(0xFF8B5CF6);

  // Text
  static const Color textDark  = Color(0xFFF1F5F9);
  static const Color textLight = Color(0xFF0F172A);
  static const Color muted     = Color(0xFF64748B);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF1A2A4A), Color(0xFF0F1623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}