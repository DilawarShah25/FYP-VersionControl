import 'package:flutter/material.dart';
import 'dart:async';

import '../../../controllers/session_controller.dart';
import '../../../utils/app_theme.dart';
import '../../authentication/login_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Wait for both the 3-second timer and SessionController initialization
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        SessionController.init(), // Ensure SharedPreferences is ready
      ]);

      if (mounted) {
        // Check session validity and navigate accordingly
        bool isSessionValid = await SessionController().isSessionValid();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error and still navigate to LoginView
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during initialization: $e')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.0,
                  height: 120.0,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    image: const DecorationImage(
                      image: AssetImage('lib/assets/images/revive_hair.png'),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                Text(
                  'Hair Health System',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'Hair Health System',
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'Predictive analysis for hair loss view\nand prevention.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.white.withOpacity(0.9),
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel:
                  'Predictive analysis for hair loss view and prevention.',
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                const CustomLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomLoadingIndicator extends StatefulWidget {
  const CustomLoadingIndicator({super.key});

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: AppTheme.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.favorite,
            color: AppTheme.secondaryColor,
            size: 24.0,
            semanticLabel: 'Loading',
          ),
        ),
      ),
    );
  }
}