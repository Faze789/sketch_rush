import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4A3DB5);

  // Accent
  static const Color accent = Color(0xFF00B894);
  static const Color accentLight = Color(0xFF55EFC4);

  // Backgrounds
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color bgDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // Canvas
  static const Color canvasBg = Color(0xFFFFFFFF);
  static const Color canvasBorder = Color(0xFFDFE6E9);

  // Game states
  static const Color correct = Color(0xFF00B894);
  static const Color wrong = Color(0xFFE17055);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF0984E3);

  // Chat
  static const Color systemMessage = Color(0xFF636E72);
  static const Color correctGuessMsg = Color(0xFF00B894);
  static const Color closeGuessMsg = Color(0xFFFDCB6E);

  // Drawing palette
  static const List<Color> drawingPalette = [
    Color(0xFF000000), // Black
    Color(0xFF636E72), // Gray
    Color(0xFFFFFFFF), // White
    Color(0xFFE17055), // Red
    Color(0xFFFF7675), // Light Red
    Color(0xFFFDCB6E), // Yellow
    Color(0xFFFAB1A0), // Peach
    Color(0xFF00B894), // Green
    Color(0xFF55EFC4), // Light Green
    Color(0xFF0984E3), // Blue
    Color(0xFF74B9FF), // Light Blue
    Color(0xFF6C5CE7), // Purple
    Color(0xFFA29BFE), // Light Purple
    Color(0xFFE84393), // Pink
    Color(0xFF00CEC9), // Teal
    Color(0xFFD63031), // Dark Red
    Color(0xFF2D3436), // Dark Gray
    Color(0xFFE58E26), // Orange
  ];

  // Brush sizes
  static const List<double> brushSizes = [2.0, 4.0, 8.0, 14.0, 24.0];
}
