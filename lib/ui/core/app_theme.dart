import 'package:flutter/material.dart';

class AppTheme {
  static const Color gold = Color(0xFFFF4D7B);
  static const Color cream = Color(0xFF1A1A2E);
  static const Color darkBg = Color(0xFFF7F5F2);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkSurface2 = Color(0xFFF1EFEC);
  static const Color subtleText = Color(0xFF9B9BAA);
  static const Color border = Color(0xFFE8E5E1);
  static const Color filmStage = Color(0xFF1A1A1A);
  static const String fontTheme = 'Lato';

  static ThemeData light() => _light();

  static ThemeData _light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: gold,
        onPrimary: Colors.white,
        secondary: Color(0xFF7B61FF),
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: cream,
        surfaceContainerHighest: darkSurface2,
        surfaceContainerLow: Color(0xFFFBF9F7),
        error: Color(0xFFFF3B30),
        onError: Colors.white,
        outline: border,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: cream,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontTheme,
          color: cream,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: cream),
        actionsIconTheme: const IconThemeData(color: gold),
      ),
      textTheme: base.textTheme.apply(fontFamily: fontTheme).copyWith(
            displayLarge: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 36,
                fontWeight: FontWeight.bold),
            displayMedium: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 28,
                fontWeight: FontWeight.bold),
            displaySmall: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 22,
                fontWeight: FontWeight.w600),
            headlineLarge: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 28,
                fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 22,
                fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 18,
                fontWeight: FontWeight.w600),
            titleLarge: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 18,
                fontWeight: FontWeight.w600),
            titleMedium: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 16,
                fontWeight: FontWeight.w500),
            titleSmall: TextStyle(
                fontFamily: fontTheme,
                color: subtleText,
                fontSize: 14,
                fontWeight: FontWeight.w500),
            bodyLarge:
                TextStyle(fontFamily: fontTheme, color: cream, fontSize: 16),
            bodyMedium: TextStyle(
                fontFamily: fontTheme, color: subtleText, fontSize: 14),
            bodySmall: TextStyle(
                fontFamily: fontTheme, color: subtleText, fontSize: 12),
            labelLarge: TextStyle(
                fontFamily: fontTheme,
                color: cream,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
            labelMedium: TextStyle(
                fontFamily: fontTheme,
                color: subtleText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface2,
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
          borderSide: const BorderSide(color: Color(0xFFFF3B30)),
        ),
        labelStyle: TextStyle(
            fontFamily: fontTheme, color: subtleText, fontSize: 14),
        hintStyle: const TextStyle(
            fontFamily: fontTheme, color: Color(0xFFBBBBC4), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: fontTheme,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: fontTheme, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSurface2,
          foregroundColor: cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface2,
        selectedColor: gold.withValues(alpha: 0.15),
        labelStyle:
            const TextStyle(fontFamily: fontTheme, fontSize: 12, color: cream),
        side: const BorderSide(color: border),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shadowColor: Color(0x18000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
        overlayColor: Color(0x26FF4D7B),
      ),
      iconTheme: const IconThemeData(color: cream),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
    );
  }
}
