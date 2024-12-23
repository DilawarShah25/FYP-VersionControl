import 'package:flutter/material.dart';
import 'signup_view.dart'; // Import the Signup Screen
import '../dashboard/home_view.dart';   // Import the Home Screen (Assuming it's your home screen)
import '../../controllers/screen_navigation_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controllers to hold the email and password
  TextEditingController emailController = TextEditingController(text: 'csdilawar@gmail.com');
  TextEditingController passwordController = TextEditingController(text: '1234');

  // Error message state
  String? errorMessage;

  // Dummy credentials for validation
  String dummyEmail = 'csdilawar@gmail.com';
  String dummyPassword = '1234';

  // Function to validate login credentials
  void _validateLogin() {
    if (emailController.text == dummyEmail && passwordController.text == dummyPassword) {
      // If credentials are correct, navigate to Home Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScreensManager()),
      );
    } else {
      setState(() {
        errorMessage = 'Incorrect email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Light background for better visibility
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
                'LOGIN',
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

                      // Centered Logo Image
                      Center(
                        child: Image.asset(
                          'lib/front-end/assets/icons/app_logo.png', // Replace with your image path
                          height: 120, // Increased height for better visibility
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email TextField
                      TextField(
                        controller: emailController, // Set the controller to pre-fill email
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password TextField
                      TextField(
                        controller: passwordController, // Set the controller to pre-fill password
                        obscureText: true, // Hide the password text
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message display
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Login Button
                      ElevatedButton(
                        onPressed: _validateLogin,
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

                      // Login Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Create a new account"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
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
