import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF006C4C); // Deep Emerald
  static const Color primaryLight = Color(0xFF339D75);
  static const Color primaryDark = Color(0xFF003E29);

  // Secondary/Accent Colors
  static const Color accent = Color(0xFFC8E6C9); // Pale Leaf
  static const Color secondary = Color(0xFF8D6E63); // Earthy Brown

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF9FAFB); // Very Light Grey
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimaryLight = Color(0xFF1F2937); // Dark Grey
  static const Color textPrimary = textPrimaryLight; // Alias for backward compatibility
  static const Color textSecondaryLight = Color(0xFF6B7280); // Medium Grey
  static const Color textPrimaryDark = Color(0xFFF3F4F6); // Off White
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Light Grey
  static const Color textSecondary = textSecondaryLight; // Alias for backward compatibility

  // Functional
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
