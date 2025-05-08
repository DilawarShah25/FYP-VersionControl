import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2); // Accessible Blue (WCAG-compliant)
  static const Color secondaryColor = Color(0xFF4CAF50); // Accessible Green
  static const Color accentColor = Color(0xFFE0E0E0); // Neutral Gray for subtle accents
  static const Color backgroundColor = Color(0xFFF8FAFC); // Off-White for reduced eye strain
  static const Color errorColor = Color(0xFFD32F2F); // Accessible Red for errors
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: white,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF424242)),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF424242)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 3, // Slightly higher for better depth perception
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), // Larger touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: accentColor.withOpacity(0.3), // Subtle fill for better visibility
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08), // Softer shadow for accessibility
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static const double paddingSmall = 10.0; // Slightly larger for touch comfort
  static const double paddingMedium = 20.0;
  static const double paddingLarge = 30.0;
}