import 'package:flutter/material.dart';
import 'login_view.dart';  // Import the Login Screen
import 'signup_view.dart'; // Import the Signup Screen

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          children: [
            // First Container with Title
            Container(
              height: 80.0,
              width: double.infinity,
              alignment: Alignment.center, // Centers the child within the container
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: const Text(
                'REGISTRATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 36, // Optional: adjust the font size if needed
                ),
              ),
            ),

            // Second Container with Curved Top, Shadow, and ScrollView
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView( // Enable scrolling if the content overflows
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Please choose an option to continue.",
                        style: TextStyle(
                          fontSize: 18, // Slightly larger text for better readability
                          color: Colors.grey[700], // Dark grey for contrast
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Centered Logo Image
                      Center(
                        child: Image.asset(
                          'lib/front-end/assets/icons/app_logo.png', // Replace with your image path
                          height: 120, // Increased height for better visibility
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Login Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
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
            ),
          ],
        ),
      ),
    );
  }
}
