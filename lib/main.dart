import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Import splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(), // Use SplashScreen as the initial screen
    );
  }
}
