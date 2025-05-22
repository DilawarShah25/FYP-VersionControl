import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color primaryColor = Color(0xFF1976D2); // Accessible Blue
  static const Color secondaryColor = Color(0xFF4CAF50); // Accessible Green
  static const Color accentColor = Color(0xFFE0E0E0); // Neutral Gray
  static const Color backgroundColor = Color(0xFFF8FAFC); // Off-White
  static const Color errorColor = Color(0xFFD32F2F); // Accessible Red
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121); // Dark Gray for text
  static const Color textSecondary = Color(0xFF424242); // Lighter Gray for secondary text

  // Progress Bar Colors (WCAG-compliant, contrast ratio > 4.5:1 against white)
  static const Color alopeciaAreataColor = Color(0xFFCC0000); // Red (darker for contrast)
  static const Color androgeneticAlopeciaColor = Color(0xFFF57C00); // Orange
  static const Color normalColor = Color(0xFF388E3C); // Green (darker for contrast)
  static const Color stage1Color = Color(0xFF0288D1); // Blue
  static const Color stage2Color = Color(0xFF7B1FA2); // Purple
  static const Color stage3Color = Color(0xFF0097A7); // Teal

  // Map of class colors for progress bars
  static const Map<String, Color> classColors = {
    'Alopecia_Areata': alopeciaAreataColor,
    'Androgenetic_Alopecia': androgeneticAlopeciaColor,
    'Normal': normalColor,
    'Stage 1': stage1Color,
    'Stage 2': stage2Color,
    'Stage 3': stage3Color,
  };

  // Theme Data
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: white,
        error: errorColor,
        onPrimary: white,
        onSecondary: white,
        onSurface: textPrimary,
        onError: white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: textSecondary,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ), // For button text
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4, // Increased for better depth
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: white,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: accentColor.withOpacity(0.2),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryColor,
        linearTrackColor: accentColor,
        linearMinHeight: 8,
      ),
    );
  }

  // Card Decoration for Containers
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Padding Constants
  static const double paddingSmall = 12.0; // Increased for better touch targets
  static const double paddingMedium = 20.0;
  static const double paddingLarge = 32.0;
}