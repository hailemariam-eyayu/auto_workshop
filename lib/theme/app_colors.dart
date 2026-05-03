import 'package:flutter/material.dart';

class AppColors {
  static const primary   = Color(0xFF1D3557); // dark navy
  static const accent    = Color(0xFFE63946); // bold red
  static const success   = Color(0xFF2A9D8F);
  static const warning   = Color(0xFFE9C46A);
  static const bg        = Color(0xFFF8F9FA);
  static const card      = Colors.white;
  static const border    = Color(0xFFE0E0E0);
  static const textDark  = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF6B7280);

  // Status badge colors
  static Color statusBg(String status) => switch (status) {
    'Borrowed'                  => const Color(0xFFFEE2E2),
    'Returned'                  => const Color(0xFFD1FAE5),
    'Not Started'               => const Color(0xFFF3F4F6),
    'In Progress'               => const Color(0xFFFEF3C7),
    'Completed/Pending Pickup'  => const Color(0xFFD1FAE5),
    'Delivered'                 => const Color(0xFFDBEAFE),
    _                           => const Color(0xFFF3F4F6),
  };

  static Color statusFg(String status) => switch (status) {
    'Borrowed'                  => const Color(0xFF991B1B),
    'Returned'                  => const Color(0xFF065F46),
    'Not Started'               => const Color(0xFF6B7280),
    'In Progress'               => const Color(0xFFD97706),
    'Completed/Pending Pickup'  => const Color(0xFF065F46),
    'Delivered'                 => const Color(0xFF1D4ED8),
    _                           => const Color(0xFF6B7280),
  };
}
