import 'package:flutter/material.dart';
import 'login_view.dart';  // Import the Login Screen
import 'signup_view.dart'; // Import the Signup Screen


class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Light background for better visibility
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: 36, // Increased font size for better visibility
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Dark color for high contrast
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please choose an option to continue.",
                style: TextStyle(
                  fontSize: 18, // Slightly larger text for better readability
                  color: Colors.grey[700], // Dark grey for contrast
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginView()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Strong blue color for the button
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for the button
                  ),
                ),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(
                    fontSize: 20, // Larger text for better visibility
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                    color: Colors.white, // White text for high contrast
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Signup Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Bright green for the signup button
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners for the button
                  ),
                ),
                child: const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontSize: 20, // Larger text for better visibility
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                    color: Colors.white, // White text for high contrast
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
