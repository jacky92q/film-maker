import 'package:flutter/material.dart';

class AppTheme {
  // ── Font ──────────────────────────────────────────────────────────────────
  static const String fontTheme = 'Lato';

  // ── Warm Light Palette (login / home / projects) ─────────────────────────
  static const Color primary     = Color(0xFFC07842);
  static const Color primaryDark = Color(0xFF8B5A2B);
  static const Color bg          = Color(0xFFFAF5ED);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surface2    = Color(0xFFFFF8F2);
  static const Color textDark    = Color(0xFF2C1810);
  static const Color textMid     = Color(0xFF8B7355);
  static const Color line        = Color(0xFFECE0D4);

  // ── Dark Editor Palette (editor / preview / export use these directly) ────
  static const Color gold        = Color(0xFFC9A84C);
  static const Color cream       = Color(0xFFF5F0E8);
  static const Color darkBg      = Color(0xFF0D0D0D);
  static const Color darkSurface  = Color(0xFF1A1A1A);
  static const Color darkSurface2 = Color(0xFF242424);
  static const Color subtleText  = Color(0xFFB0A890);
  static const Color border      = Color(0xFF2A2A2A);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryDark,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textDark,
        surfaceContainerHighest: surface2,
        surfaceContainerLow: bg,
        error: Color(0xFFE85D4A),
        onError: Colors.white,
        outline: line,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontTheme,
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textDark),
        actionsIconTheme: IconThemeData(color: primary),
      ),
      textTheme: base.textTheme.apply(fontFamily: fontTheme).copyWith(
        displayLarge:  TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 36, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall:  TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 22, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 26, fontWeight: FontWeight.bold),
        headlineMedium:TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 22, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge:    TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall:    TextStyle(fontFamily: fontTheme, color: textMid,  fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 16),
        bodyMedium:    TextStyle(fontFamily: fontTheme, color: textMid,  fontSize: 14),
        bodySmall:     TextStyle(fontFamily: fontTheme, color: textMid,  fontSize: 12),
        labelLarge:    TextStyle(fontFamily: fontTheme, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        labelMedium:   TextStyle(fontFamily: fontTheme, color: textMid,  fontSize: 12, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE85D4A))),
        labelStyle: const TextStyle(fontFamily: fontTheme, color: textMid,  fontSize: 14),
        hintStyle:  const TextStyle(fontFamily: fontTheme, color: Color(0xFFBFAA90), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: textMid,
        suffixIconColor: textMid,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: fontTheme, fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: fontTheme, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: textDark,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontFamily: fontTheme, fontSize: 12, color: textDark),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: line,
        overlayColor: Color(0x22C07842),
      ),
      iconTheme: const IconThemeData(color: textDark),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: fontTheme, color: textDark, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(fontFamily: fontTheme, color: textMid, fontSize: 14),
      ),
    );
  }
}
