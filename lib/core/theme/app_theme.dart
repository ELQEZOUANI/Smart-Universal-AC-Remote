import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/design_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      fontFamily: 'SF Pro Display',
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontFamily: 'Georgia',
          fontSize: 64,
          fontWeight: FontWeight.w500,
          letterSpacing: -3.2,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontFamily: 'Georgia',
          fontSize: 34,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.1,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: -.55,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.45,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: scheme.outlineVariant.withValues(alpha: isDark ? .42 : .5),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surface : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? .6 : .68),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: isDark
              ? Colors.transparent
              : AppColors.lightSurface.withValues(alpha: .75),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? .62 : .72),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
