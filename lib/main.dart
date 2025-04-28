import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scalpsense/utils/app_theme.dart';
import 'package:scalpsense/views/authentication/login_view.dart';
import 'package:scalpsense/views/authentication/sign_up.dart';
import 'package:scalpsense/views/dashboard/other_dashboard/blog/blog_view.dart';
import 'package:scalpsense/views/dashboard/other_dashboard/faq/faq_view.dart';
import 'package:scalpsense/views/dashboard/other_dashboard/home_view.dart';

import 'Community/view/community_feed_screen.dart';
import 'controllers/screen_navigation_controller.dart';
import 'controllers/session_controller.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseInitialized = false;
  int retryCount = 0;
  const maxRetries = 3;

  // Retry Firebase initialization up to maxRetries
  while (!firebaseInitialized && retryCount < maxRetries) {
    try {
      await Firebase.initializeApp();
      // Configure Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      // Set Firebase Authentication persistence to LOCAL
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase initialized successfully on attempt ${retryCount + 1}');
      firebaseInitialized = true;
    } catch (e) {
      retryCount++;
      debugPrint('Firebase initialization failed on attempt $retryCount: $e');
      if (retryCount == maxRetries) {
        debugPrint('Max retries reached. Proceeding with limited functionality.');
      }
      await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
    }
  }

  // Debug authentication state
  FirebaseAuth.instance.authStateChanges().listen((user) {
    debugPrint('Auth state changed: UID=${user?.uid ?? "null"}, Email=${user?.email ?? "null"}');
  });

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
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalKey<NavigatorState>(),
      home: const SplashView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignUpView(),
        '/screens_manager': (context) => const ScreensManager(),
        '/home': (context) => const HomeView(),
        '/community': (context) => const CommunityFeedScreen(),
        '/blog': (context) => const BlogView(),
        '/faq': (context) => const FaqView(),
      },
      onUnknownRoute: (settings) {
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const LoginView());
      },
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController sessionController = SessionController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('SplashView: Waiting for auth state');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint('SplashView: No authenticated user, navigating to /login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          );
        }

        // Check session validity with token refresh
        return FutureBuilder<bool>(
          future: _validateSessionWithTokenRefresh(sessionController, snapshot.data!),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('SplashView: Waiting for session validation');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
              );
            }

            if (sessionSnapshot.hasError) {
              debugPrint('SplashView: Session validation error: ${sessionSnapshot.error}');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FirebaseAuth.instance.signOut();
                sessionController.clearSession();
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (sessionSnapshot.data == true) {
                debugPrint('SplashView: Session valid, navigating to /screens_manager');
                Navigator.pushReplacementNamed(context, '/screens_manager');
              } else {
                debugPrint('SplashView: Session expired, signing out and navigating to /login');
                FirebaseAuth.instance.signOut();
                sessionController.clearSession();
                Navigator.pushReplacementNamed(context, '/login');
              }
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
            );
          },
        );
      },
    );
  }

  Future<bool> _validateSessionWithTokenRefresh(SessionController sessionController, User user) async {
    try {
      // Attempt to refresh the user's token
      await user.getIdToken(true);
      debugPrint('Token refreshed successfully for user: ${user.uid}');
      // Validate the session
      bool isValid = await sessionController.isSessionValid();
      if (!isValid) {
        debugPrint('Session validation failed after token refresh for user: ${user.uid}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error during token refresh or session validation: $e');
      return false;
    }
  }
}