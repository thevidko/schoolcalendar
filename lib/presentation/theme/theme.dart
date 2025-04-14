import 'package:flutter/material.dart';
// Optional: Import Google Fonts if desired
// import 'package:google_fonts/google_fonts.dart';

ThemeData buildDarkBlueTheme() {
  // Definice barev
  const Color primaryBlue = Color.fromARGB(
    255,
    94,
    213,
    250,
  ); // Tvoje světle modrá (#5ED5FA)
  const Color backgroundDark = Color.fromARGB(
    255,
    30,
    30,
    30,
  ); // Velmi tmavě šedá (#1E1E1E)
  const Color surfaceDark = Color.fromARGB(
    255,
    45,
    45,
    45,
  ); // O něco světlejší povrch (#2D2D2D)
  const Color onPrimaryBlack = Colors.black;
  const Color onSurfaceWhite = Colors.white;
  const Color onBackgroundWhite = Colors.white;

  // --- DEFINUJTE SI BARVU PRO APPBAR ---
  // Příklad: Velmi tmavě modrá (podobná Navy/Midnight Blue)
  const Color darkBlueAppBar = Color(0xFF001F3F);
  // Jiné možnosti:
  // const Color darkBlueAppBar = Color(0xFF0D47A1); // Material Blue 900
  // const Color darkBlueAppBar = Color(0xFF1A237E); // Indigo 900

  // Vytvoříme tmavé ColorScheme a upravíme ho
  final darkColorScheme = ColorScheme.dark().copyWith(
    primary: primaryBlue,
    onPrimary: onPrimaryBlack,
    secondary: primaryBlue.withAlpha(200),
    onSecondary: onPrimaryBlack,
    background: backgroundDark,
    onBackground: onBackgroundWhite,
    surface: surfaceDark, // Ostatní povrchy mohou zůstat tmavě šedé
    onSurface: onSurfaceWhite,
  );

  final baseTextTheme = ThemeData.dark().textTheme;
  // final customTextTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    primaryColor: primaryBlue,

    // ----- Základní barvy -----
    scaffoldBackgroundColor: darkColorScheme.background,
    canvasColor: darkColorScheme.background,
    cardColor: darkColorScheme.surface, // Karty zůstanou tmavě šedé
    dialogBackgroundColor:
        darkColorScheme.surface, // Dialogy zůstanou tmavě šedé
    // ----- Text a Ikony -----
    textTheme: baseTextTheme, // Nebo customTextTheme
    iconTheme: IconThemeData(color: darkColorScheme.onSurface),
    primaryIconTheme: IconThemeData(color: darkColorScheme.onSurface),

    // ----- Témata pro specifické komponenty -----
    appBarTheme: AppBarTheme(
      // --- ZMĚNA ZDE ---
      backgroundColor: darkBlueAppBar, // Nastavení tmavě modrého pozadí
      // --- KONEC ZMĚNY ---
      foregroundColor:
          onSurfaceWhite, // Barva titulku a ikon - necháme bílou pro kontrast
      elevation: 2.0,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkColorScheme.primary),
    ),

    // ... zbytek vašich témat komponent ...
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
        side: BorderSide(color: darkColorScheme.primary.withOpacity(0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return darkColorScheme.primary;
        }
        return darkColorScheme.onSurface.withOpacity(0.6);
      }),
      checkColor: MaterialStateProperty.all(darkColorScheme.onPrimary),
      side: BorderSide(color: darkColorScheme.onSurface.withOpacity(0.8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkColorScheme.surface.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: darkColorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: darkColorScheme.primary, width: 2.0),
      ),
      labelStyle: TextStyle(color: darkColorScheme.onSurface.withOpacity(0.7)),
      hintStyle: TextStyle(color: darkColorScheme.onSurface.withOpacity(0.5)),
    ),
    cardTheme: CardTheme(
      elevation: 2.0,
      color: darkColorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkColorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: darkColorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 4.0,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: darkColorScheme.onSurface.withOpacity(0.8),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkColorScheme.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(color: darkColorScheme.onPrimary),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: MaterialStateProperty.all(true),
      thickness: MaterialStateProperty.all(6.0),
      thumbColor: MaterialStateProperty.all(
        darkColorScheme.primary.withOpacity(0.7),
      ),
      radius: const Radius.circular(3.0),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: darkColorScheme.primary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  );
}
