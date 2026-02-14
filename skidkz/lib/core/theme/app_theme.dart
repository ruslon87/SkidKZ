// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Финтеховый графитовый фон
  static const Color bg = Color(0xFF0B1114);
  static const Color bg2 = Color(0xFF0E1519);

  // Поверхности
  static const Color surface = Color(0xFF121B20);
  static const Color surface2 = Color(0xFF0F171C);
  static const Color border = Color(0xFF1C2A31);

  // Текст
  static const Color text = Color(0xFFE6EDF6);
  static const Color textMuted = Color(0xFF9FB0C8);
  static const Color textDisabled = Color(0xFF6E7F96);

  // Изумрудный бренд
  static const Color accent = Color(0xFF1EDC8A);
  static const Color accentSoft = Color(0xFF39F0A5);
  static const Color accentDark = Color(0xFF0FA36B);

  static const Color danger = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF1EDC8A);
}

class AppRadii {
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Colors.black,
      secondary: AppColors.accentSoft,
      onSecondary: Colors.black,
      error: AppColors.danger,
      onError: Colors.white,
      background: AppColors.bg,
      onBackground: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return base.copyWith(
      colorScheme: colorScheme,

      // ВАЖНО: чтобы при переходах/подгрузке не было "другого" холста
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      dialogBackgroundColor: AppColors.surface,

      // ВАЖНО: убираем грязный overlay при тапах (Ink/ripple)
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      // Переходы более "ровные" (можно оставить по умолчанию, но так стабильнее)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.text,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.r16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.r16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ).copyWith(
          // мягкое свечение
          shadowColor: MaterialStatePropertyAll(
            AppColors.accent.withOpacity(0.35),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.r16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.r16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.3),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
