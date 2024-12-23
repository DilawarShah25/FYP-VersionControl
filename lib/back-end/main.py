import 'package:flutter/material.dart';
import ' views/onboarding/splash_view.dart'; // Import splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashView(), // Use SplashScreen as the initial screen
    );
  }
}
