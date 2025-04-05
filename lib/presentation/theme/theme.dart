import 'package:flutter/material.dart';

ThemeData buildTheme() {
  Color primaryBlue = Color.fromARGB(255, 94, 213, 250);
  Color backgroundColor1 = Color.fromARGB(255, 65, 65, 65);
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    //scaffoldBackgroundColor: backgroundColor1,
    textTheme: TextTheme(
      bodySmall: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryBlue, // Barva tlačítek
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      //Barva tlačítek ve formuláři
    ),
  );
}
