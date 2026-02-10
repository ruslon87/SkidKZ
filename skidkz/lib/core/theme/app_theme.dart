import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =========================
  // Graphite + Emerald Palette (FIXED)
  // =========================

  // Background / Surfaces
  static const Color background = Color(0xFF121817); // #121817
  static const Color surface = Color(0xFF1A1F1E); // #1A1F1E (cards, inputs)
  static const Color elevated = Color(0xFF202625); // #202625 (AppBar / Bottom)
  static const Color divider = Color(0xFF242B29); // #242B29

  // Accents
  static const Color primary = Color(0xFF1EC98B); // #1EC98B
  static const Color secondary = Color(0xFF17A673); // #17A673
  static const Color pressed = Color(0xFF0F7F5A); // #0F7F5A

  // Text
  static const Color textPrimary = Color(0xFFE6F2ED); // #E6F2ED
  static const Color textSecondary = Color(0xFF9FBDB2); // #9FBDB2
  static const Color textDisabled = Color(0xFF6F8F85); // #6F8F85

  // Status/system bars
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: divider,
  );

  // Errors (нейтрально, без “кислоты”)
  static const Color error = Color(0xFFE25C5C);

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    final scheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Color(0xFF04110B), // очень тёмный текст на emerald
      secondary: secondary,
      onSecondary: Color(0xFF04110B),
      background: background,
      onBackground: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: divider,

      // Typography
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF04110B),
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: elevated,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // BottomNavigationBar (как Freedom: читаемо, без неона)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: elevated,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Buttons (CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF04110B),
          disabledBackgroundColor: surface,
          disabledForegroundColor: textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return pressed.withOpacity(0.18);
            }
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Inputs / Search
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textDisabled),
        labelStyle: const TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      // Cards
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider),
        ),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
      ),
    );
  }
}
