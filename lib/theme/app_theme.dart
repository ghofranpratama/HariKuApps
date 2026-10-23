import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema "lembar harian": kertas hangat, tinta, satu warna aksen jingga-merah.
/// Sengaja tidak memakai ColorScheme.fromSeed agar tidak terlihat seperti
/// template Material bawaan.
class AppTheme {
  static ThemeData light() => _build(const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1B1A17), // tinta
        onPrimary: Color(0xFFF4EFE6),
        secondary: Color(0xFFD8432B), // aksen
        onSecondary: Color(0xFFFFFFFF),
        error: Color(0xFFD8432B),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFFF4EFE6), // kertas
        onSurface: Color(0xFF1B1A17),
        surfaceContainerHighest: Color(0xFFE9E2D3),
        outline: Color(0xFF857E70),
        outlineVariant: Color(0xFFD6CEBC),
      ));

  static ThemeData dark() => _build(const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFEDE7D9),
        onPrimary: Color(0xFF171510),
        secondary: Color(0xFFF26B4F),
        onSecondary: Color(0xFF1B0F0B),
        error: Color(0xFFF26B4F),
        onError: Color(0xFF1B0F0B),
        surface: Color(0xFF171510),
        onSurface: Color(0xFFEDE7D9),
        surfaceContainerHighest: Color(0xFF24211A),
        outline: Color(0xFF9A9384),
        outlineVariant: Color(0xFF38342A),
      ));

  static ThemeData _build(ColorScheme cs) {
    final text = GoogleFonts.dmSansTextTheme()
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    final square = RoundedRectangleBorder(borderRadius: BorderRadius.circular(3));

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        shape: square,
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: Colors.transparent,
        selectedColor: cs.primary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        extendedTextStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.primary,
        contentTextStyle: GoogleFonts.dmSans(color: cs.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 1.5)),
        errorBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: cs.secondary)),
        focusedErrorBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: cs.secondary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: square),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: square,
          side: BorderSide(color: cs.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: square),
      ),
    );
  }
}

/// Gaya teks khusus: serif untuk judul/angka, mono untuk metadata.
class AppText {
  static TextStyle display({
    double size = 28,
    Color? color,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.05,
      );

  static TextStyle mono({
    double size = 11,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: 0.8,
      );
}
