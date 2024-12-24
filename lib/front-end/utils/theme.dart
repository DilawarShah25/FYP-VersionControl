import 'package:flutter/material.dart';

// Define light theme
final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,  // Primary color for light theme
  scaffoldBackgroundColor: Colors.white,  // Background color for the whole app
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blueAccent,  // App bar background color
    elevation: 4,  // App bar shadow
    titleTextStyle: TextStyle(
      color: Colors.white,  // App bar text color
      fontSize: 20,  // Text size in the app bar
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.0,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontSize: 14.0,
      color: Colors.black54,
    ),
    bodySmall: TextStyle(
      fontSize: 12.0,
      color: Colors.black45,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blueAccent,  // Button background color
    textTheme: ButtonTextTheme.primary,  // Button text color
  ),
  iconTheme: const IconThemeData(
    color: Colors.blueAccent,  // Icon color
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),  // Border radius for text fields
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.blueAccent,  // Border color when text field is focused
      ),
    ),
    labelStyle: const TextStyle(
      color: Colors.blueAccent,  // Label color for text fields
    ),
  ),
);

// Define dark theme
final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,  // Primary color for dark theme
  scaffoldBackgroundColor: Colors.black87,  // Dark background color
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blueGrey,  // Dark theme app bar background
    elevation: 4,
    titleTextStyle: TextStyle(
      color: Colors.white,  // App bar text color
      fontSize: 20,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.0,
      color: Colors.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: 14.0,
      color: Colors.white54,
    ),
    bodySmall: TextStyle(
      fontSize: 12.0,
      color: Colors.white,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blueGrey,  // Button background color for dark theme
    textTheme: ButtonTextTheme.primary,  // Button text color for dark theme
  ),
  iconTheme: const IconThemeData(
    color: Colors.blueGrey,  // Icon color in dark theme
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),  // Border radius for text fields
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.blueGrey,  // Border color when text field is focused
      ),
    ),
    labelStyle: const TextStyle(
      color: Colors.blueGrey,  // Label color for text fields in dark theme
    ),
  ),
);
