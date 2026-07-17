import 'package:flutter/material.dart';

/// Nexus design system — enterprise minimalist.
/// Kameron for headings, Lato for body.
/// Palette from the approved design plan.
class NexusTheme {
  NexusTheme._();

  // ── Light Mode Colors ──
  static const _lightBackground = Color(0xFFF8FAFC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightPrimary = Color(0xFF1D4ED8);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightText = Color(0xFF0F172A);
  static const _lightTextSecondary = Color(0xFF64748B);
  static const _lightBorder = Color(0xFFE2E8F0);

  // ── Dark Mode Colors ──
  static const _darkBackground = Color(0xFF020817);
  static const _darkSurface = Color(0xFF0F172A);
  static const _darkPrimary = Color(0xFF2563EB);
  static const _darkOnPrimary = Color(0xFFFFFFFF);
  static const _darkText = Color(0xFFF8FAFC);
  static const _darkTextSecondary = Color(0xFF94A3B8);
  static const _darkBorder = Color(0xFF1E293B);

  // ── Shared ──
  static const _success = Color(0xFF10B981);

  // ── Text Theme (Lato body, Kameron headings applied per-widget) ──
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Lato', fontSize: 57, fontWeight: FontWeight.w400, color: primary),
      displayMedium: TextStyle(fontFamily: 'Lato', fontSize: 45, fontWeight: FontWeight.w400, color: primary),
      displaySmall: TextStyle(fontFamily: 'Lato', fontSize: 36, fontWeight: FontWeight.w400, color: primary),
      headlineLarge: TextStyle(fontFamily: 'Lato', fontSize: 32, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: TextStyle(fontFamily: 'Lato', fontSize: 28, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: TextStyle(fontFamily: 'Lato', fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      titleLarge: TextStyle(fontFamily: 'Lato', fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      titleMedium: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.w500, color: primary),
      titleSmall: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: primary),
      bodyLarge: TextStyle(fontFamily: 'Lato', fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w500, color: primary),
      labelMedium: TextStyle(fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.w500, color: primary),
      labelSmall: TextStyle(fontFamily: 'Lato', fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  // ── Light Theme ──
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      surface: _lightSurface,
      onSurface: _lightText,
      onSurfaceVariant: _lightTextSecondary,
      outline: _lightBorder,
      outlineVariant: _lightBorder,
      secondary: _success,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(_lightText, _lightTextSecondary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBackground,
        foregroundColor: _lightText,
        titleTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: _lightOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightText,
          side: const BorderSide(color: _lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        labelStyle: const TextStyle(fontFamily: 'Lato', fontSize: 14, color: _lightTextSecondary),
        hintStyle: const TextStyle(fontFamily: 'Lato', fontSize: 14, color: _lightTextSecondary),
      ),
      dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
    );
  }

  // ── Dark Theme ──
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      surface: _darkSurface,
      onSurface: _darkText,
      onSurfaceVariant: _darkTextSecondary,
      outline: _darkBorder,
      outlineVariant: _darkBorder,
      secondary: _success,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(_darkText, _darkTextSecondary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: _darkText,
        titleTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkText,
          side: const BorderSide(color: _darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        labelStyle: const TextStyle(fontFamily: 'Lato', fontSize: 14, color: _darkTextSecondary),
        hintStyle: const TextStyle(fontFamily: 'Lato', fontSize: 14, color: _darkTextSecondary),
      ),
      dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
    );
  }
}

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
