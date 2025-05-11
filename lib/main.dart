import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scalpsense/utils/app_theme.dart';
import 'package:scalpsense/views/authentication/login_view.dart';
import 'package:scalpsense/views/authentication/sign_up.dart';
import 'package:scalpsense/views/dashboard/blog/blog_view.dart';
import 'package:scalpsense/views/dashboard/faq/faq_view.dart';
import 'package:scalpsense/views/dashboard/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Community/view/community_feed_screen.dart';
import 'controllers/screen_navigation_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionController.init(); // Initialize SessionController early

  bool firebaseInitialized = false;
  int retryCount = 0;
  const maxRetries = 3;
  const retryDelay = Duration(milliseconds: 500); // Reduced retry delay

  // Retry Firebase initialization with shorter delay
  while (!firebaseInitialized && retryCount < maxRetries) {
    try {
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase initialized successfully on attempt ${retryCount + 1}');
      firebaseInitialized = true;
    } catch (e) {
      retryCount++;
      debugPrint('Firebase initialization failed on attempt $retryCount: $e');
      if (retryCount == maxRetries) {
        debugPrint('Max retries reached. Proceeding with limited functionality.');
      }
      await Future.delayed(retryDelay); // Shorter delay
    }
  }

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

        return FutureBuilder<bool>(
          future: _validateSessionWithTokenRefresh(sessionController, snapshot.data!),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('SplashView: Waiting for session validation');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
              );
            }

            if (sessionSnapshot.hasError || sessionSnapshot.data == false) {
              debugPrint('SplashView: Session validation failed or error: ${sessionSnapshot.error}');
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await FirebaseAuth.instance.signOut();
                await sessionController.clearSession();
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
              );
            }

            debugPrint('SplashView: Session valid, navigating to /screens_manager');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/screens_manager');
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
      // Check if token is still valid before forcing refresh
      final currentToken = await user.getIdTokenResult();
      final isTokenValid = currentToken.expirationTime?.isAfter(DateTime.now()) ?? false;
      if (!isTokenValid) {
        await user.getIdToken(true); // Refresh only if expired
        debugPrint('Token refreshed for user: ${user.uid}');
      } else {
        debugPrint('Token still valid for user: ${user.uid}');
      }

      bool isValid = await sessionController.isSessionValid();
      if (!isValid) {
        debugPrint('Session validation failed for user: ${user.uid}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error during token refresh or session validation: $e');
      return false;
    }
  }
}

// Optimized SessionController
class SessionController {
  static const String _lastLoginKey = 'last_login_timestamp';
  static const int sessionTimeoutDays = 7; // Session timeout remains 7 days
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized');
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  Future<void> saveLastLogin() async {
    final prefs = await _getPrefs();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastLoginKey, now);
    debugPrint('Saved last login: ${DateTime.fromMillisecondsSinceEpoch(now)}');
  }

  Future<bool> isSessionValid() async {
    final prefs = await _getPrefs();
    final lastLogin = prefs.getInt(_lastLoginKey);
    if (lastLogin == null) {
      debugPrint('No last login found');
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    const timeoutMillis = sessionTimeoutDays * 24 * 60 * 60 * 1000;
    final isValid = (now - lastLogin) < timeoutMillis;
    debugPrint('Session valid: $isValid, Last login: ${DateTime.fromMillisecondsSinceEpoch(lastLogin)}');
    return isValid;
  }

  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_lastLoginKey);
    debugPrint('Cleared session');
  }
}