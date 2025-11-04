import 'package:flutter/material.dart';

/// App color palette matching the design screenshots
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Background Colors
  static const Color primaryBackground = Color(0xFF1B1F3B); // Dark navy blue
  static const Color secondaryBackground = Color(0xFF252A48); // Slightly lighter navy
  static const Color cardBackground = Color(0xFF2C3154); // Dark blue-gray

  // Accent/Primary Colors
  static const Color accent = Color(0xFFF4B740); // Golden yellow
  static const Color primary = Color(0xFFF4B740); // Golden yellow (alias)

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB8BACC); // Light gray

  // Bottom Navigation Colors
  static const Color bottomNavInactive = Color(0xFF6B7280); // Gray
  static const Color bottomNavActive = Color(0xFFF4B740); // Golden yellow

  // Book Condition Colors
  static const Color conditionLikeNew = Color(0xFF4A9FF5); // Blue
  static const Color conditionGood = Color(0xFFFF9800); // Orange
  static const Color conditionUsed = Color(0xFF9E9E9E); // Gray
  static const Color conditionNew = Color(0xFF4CAF50); // Green

  // Status Colors
  static const Color statusPending = Color(0xFFFF9800); // Orange
  static const Color statusAccepted = Color(0xFF4CAF50); // Green
  static const Color statusRejected = Color(0xFFF44336); // Red

  // Chat Bubble Colors
  static const Color chatSent = Color(0xFFF4B740); // Golden yellow
  static const Color chatReceived = Color(0xFF2C3154); // Dark blue-gray

  // Additional UI Colors
  static const Color error = Color(0xFFF44336); // Red
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color info = Color(0xFF4A9FF5); // Blue

  // Divider and Border Colors
  static const Color divider = Color(0xFF3A3F5F); // Subtle divider
  static const Color border = Color(0xFF3A3F5F); // Input border

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // Semi-transparent black
}

