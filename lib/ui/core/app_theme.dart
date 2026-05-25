import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color gold = Color(0xFFC9A84C);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurface2 = Color(0xFF242424);
  static const Color subtleText = Color(0xFFB0A890);
  static const Color border = Color(0xFF2A2A2A);

  static ThemeData light() => _dark();

  static ThemeData _dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: darkBg,
        secondary: Color(0xFF8B7355),
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: cream,
        surfaceContainerHighest: darkSurface2,
        surfaceContainerLow: Color(0xFF141414),
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
        outline: border,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: cream,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: cream,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: cream),
        actionsIconTheme: const IconThemeData(color: gold),
      ),
      textTheme: GoogleFonts.latoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 36, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 22, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 22, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.playfairDisplay(
            color: cream, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.lato(
            color: cream, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.lato(
            color: cream, fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.lato(
            color: subtleText, fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.lato(color: cream, fontSize: 16),
        bodyMedium: GoogleFonts.lato(color: subtleText, fontSize: 14),
        bodySmall: GoogleFonts.lato(color: subtleText, fontSize: 12),
        labelLarge: GoogleFonts.lato(
            color: cream,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
        labelMedium: GoogleFonts.lato(
            color: subtleText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        labelStyle: GoogleFonts.lato(color: Color(0xFF888888), fontSize: 14),
        hintStyle: GoogleFonts.lato(color: Color(0xFF555555), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: darkBg,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.lato(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSurface2,
          foregroundColor: cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface2,
        selectedColor: gold.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.lato(fontSize: 12, color: cream),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: darkBg,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        thumbColor: gold,
        inactiveTrackColor: border,
        overlayColor: Color(0x22C9A84C),
      ),
      iconTheme: const IconThemeData(color: cream),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
    );
  }
}
