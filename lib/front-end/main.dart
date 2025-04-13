import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scalpsense/front-end/views/app_theme.dart';
import 'package:scalpsense/front-end/views/dashboard/other_dashboard/home_view.dart';
import 'views/onboarding/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hair Health App',
      theme: AppTheme.theme,
      home: const SplashView(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeView(),
      },
    );
  }
}