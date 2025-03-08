import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'views/onboarding/splash_view.dart'; // Import splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure the app is properly initialized
  await Firebase.initializeApp();
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
