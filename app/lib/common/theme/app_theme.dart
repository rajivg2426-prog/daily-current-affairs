import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 theme: Plus Jakarta Sans headlines, Inter body,
/// Noto Sans Devanagari as the fallback for Hindi text.
abstract final class DcaTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: DcaPalette.primary,
          onPrimary: Colors.white,
          primaryContainer: DcaPalette.primaryContainer,
          onPrimaryContainer: DcaPalette.primaryDeep,
          secondary: DcaPalette.primaryDeep,
          onSecondary: Colors.white,
          error: DcaPalette.error,
          onError: Colors.white,
          surface: DcaPalette.background,
          onSurface: DcaPalette.ink,
          surfaceContainerLowest: DcaPalette.background,
          surfaceContainerLow: DcaPalette.surface,
          surfaceContainer: DcaPalette.surface,
          surfaceContainerHigh: DcaPalette.surfaceHigh,
          surfaceContainerHighest: DcaPalette.surfaceHigh,
          onSurfaceVariant: DcaPalette.inkSecondary,
          outline: DcaPalette.outline,
          outlineVariant: DcaPalette.outline,
        ),
        dcaColors: DcaColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: DcaPalette.primaryDark,
          onPrimary: Color(0xFF0A1638),
          primaryContainer: DcaPalette.primaryContainerDark,
          onPrimaryContainer: DcaPalette.primaryDeepDark,
          secondary: DcaPalette.primaryDeepDark,
          onSecondary: Color(0xFF0A1638),
          error: Color(0xFFFF6B6F),
          onError: Color(0xFF0A0F1E),
          surface: DcaPalette.backgroundDark,
          onSurface: DcaPalette.inkDark,
          surfaceContainerLowest: DcaPalette.backgroundDark,
          surfaceContainerLow: DcaPalette.surfaceDark,
          surfaceContainer: DcaPalette.surfaceDark,
          surfaceContainerHigh: DcaPalette.surfaceHighDark,
          surfaceContainerHighest: DcaPalette.surfaceHighDark,
          onSurfaceVariant: DcaPalette.inkSecondaryDark,
          outline: DcaPalette.outlineDark,
          outlineVariant: DcaPalette.outlineDark,
        ),
        dcaColors: DcaColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required DcaColors dcaColors,
  }) {
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final body = GoogleFonts.interTextTheme(base.textTheme);
    final head = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final hindi = GoogleFonts.notoSansDevanagari().fontFamily;
    final fallback = <String>[if (hindi != null) hindi];

    TextStyle? h(TextStyle? s, double size, double height, FontWeight w) =>
        s?.copyWith(fontSize: size, height: height / size, fontWeight: w, color: scheme.onSurface, fontFamilyFallback: fallback);
    TextStyle? b(TextStyle? s, double size, double height, FontWeight w) =>
        s?.copyWith(fontSize: size, height: height / size, fontWeight: w, color: scheme.onSurface, fontFamilyFallback: fallback);

    final textTheme = body.copyWith(
      displaySmall: h(head.displaySmall, 32, 40, FontWeight.w800),
      headlineMedium: h(head.headlineMedium, 24, 32, FontWeight.w800),
      headlineSmall: h(head.headlineSmall, 20, 28, FontWeight.w700),
      titleLarge: h(head.titleLarge, 18, 24, FontWeight.w700),
      titleMedium: b(body.titleMedium, 17, 24, FontWeight.w600),
      titleSmall: b(body.titleSmall, 15, 22, FontWeight.w600),
      bodyLarge: b(body.bodyLarge, 16, 26, FontWeight.w400),
      bodyMedium: b(body.bodyMedium, 14, 20, FontWeight.w400),
      labelLarge: b(body.labelLarge, 14, 20, FontWeight.w700),
      labelMedium: b(body.labelMedium, 12, 16, FontWeight.w600),
      labelSmall: b(body.labelSmall, 11, 14, FontWeight.w500),
    );

    final shape16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [dcaColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape16,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: shape16,
          side: BorderSide(color: scheme.outline, width: 1.5),
          foregroundColor: scheme.onSurface,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outline),
        labelStyle: textTheme.labelMedium?.copyWith(fontSize: 13),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontSize: 15),
      ),
    );
  }
}
