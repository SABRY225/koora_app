import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color backgroundBlack = Color(0xFF0F1012);
  static const Color surfaceCharcoal = Color(0xFF1C1E22);
  static const Color primaryGreen = Color(0xFF00FF66);
  static const Color primaryGreenDark = Color(0xFF00B347);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA0A3A8);
  static const Color errorRed = Color(0xFFFF4C4C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: goldAccent,
        surface: surfaceCharcoal,
        error: errorRed,
        onPrimary: backgroundBlack,
        onSurface: textWhite,
      ),
      textTheme: TextTheme(
        // Use Oswald for bold, premium headers
        displayLarge: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displaySmall: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        // Use Inter for clean, readable body text
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textWhite,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: backgroundBlack,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceCharcoal,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: backgroundBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
