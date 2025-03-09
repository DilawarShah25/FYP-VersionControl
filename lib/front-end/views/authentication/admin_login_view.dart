import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';
import '../../controllers/screen_navigation_controller.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({Key? key}) : super(key: key);

  @override
  _AdminLoginViewState createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController =
  TextEditingController(text: 'csdilawar@gmail.com');
  final TextEditingController _passwordController =
  TextEditingController(text: '1234');

  bool _showPassword = false;
  String? _errorMessage;

  // Function to handle Admin Login
  Future<void> _adminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and Password cannot be empty.');
      return;
    }

    try {
      // Firebase Login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists && userDoc['role'] == 'Admin') {
        // Save session data locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('role', 'Admin');

        // Navigate to Admin Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ScreensManager()),
        );
      } else {
        setState(() => _errorMessage = 'Access Denied: Admins Only.');
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Login failed.');
    }
  }

  // Function to reset password
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter your email first.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        _errorMessage = "Password reset link sent! Check your email.";
      });
    } catch (e) {
      setState(() => _errorMessage = "Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA5FECB), Color(0xFF20BDFF), Color(0xFF5433FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      _buildTextField(_emailController, "Email", Icons.email),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      _buildLoginButton(),
                      _buildForgotPassword(),
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA5FECB), Color(0xFF20BDFF), Color(0xFF5433FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '  Welcome Back  ',
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blueAccent),
          ),
          SizedBox(height: 10),
          Text("Admin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        labelStyle: const TextStyle(color: Colors.white),
        border: _outlineBorder(),
        focusedBorder: _outlineBorder(),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        border: _outlineBorder(),
        focusedBorder: _outlineBorder(),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _adminLogin,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blueAccent,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        'Login',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _resetPassword,
      child: const Text(
        'Forgot Password?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Create a new account", style: TextStyle(color: Colors.white)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpView())),
          child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  OutlineInputBorder _outlineBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.white),
    );
  }
}
