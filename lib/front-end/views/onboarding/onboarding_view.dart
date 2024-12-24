import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/other_dashboard/home_view.dart';

class OnboardingChecker extends StatefulWidget {
  const OnboardingChecker({super.key});

  @override
  _OnboardingCheckerState createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<OnboardingChecker> {
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  // Check if the app is being launched for the first time
  _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLaunch = prefs.getBool('isFirstLaunch');

    if (isFirstLaunch == null || isFirstLaunch) {
      // Show Onboarding if it's the first launch or flag is missing
      setState(() {
        _isFirstLaunch = true;
      });
      prefs.setBool('isFirstLaunch', false); // Set flag to false after first launch
    } else {
      // Skip onboarding if not the first launch
      setState(() {
        _isFirstLaunch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isFirstLaunch ? const OnboardingScreen() : const HomeView();
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to the App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Onboarding Page 1'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Go to the next onboarding screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingPage2()),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Page 2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Onboarding Page 2'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Directly navigate to HomeView without extra push
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
