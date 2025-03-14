import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_view.dart'; // Import LoginView

class VerificationView extends StatefulWidget {
  final String email;

  const VerificationView({super.key, required this.email});

  @override
  _VerificationViewState createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _message;
  Timer? _verificationTimer;

  // Theme constants
  static const Color primaryColor = Color(0xFF1E3C72); // Deep blue
  static const Color secondaryColor = Color(0xFF2A5298); // Lighter blue
  static const Color accentColor = Color(0xFF00C4B4); // Teal accent
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light gray
  static const Color textColor = Color(0xFF2D3748); // Dark gray

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    // Periodically check email verification status every 2 seconds
    _verificationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool isVerified = await _authService.isEmailVerified();
      if (isVerified) {
        setState(() {
          _message = 'Email verified successfully!';
        });
        timer.cancel(); // Stop the timer
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginView()),
            );
          }
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      User? user = _authService.getCurrentUser();
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _isLoading = false;
          _message = 'Verification email resent. Please check your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error resending email: $e';
      });
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel(); // Cancel the timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
          labelMedium: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    'A verification email has been sent to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Waiting for verification...',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _message!.contains('successfully') ? accentColor : Colors.yellow,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator(color: accentColor)
                      : _buildResendButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Verify Your Email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return GestureDetector(
      onTap: _resendVerificationEmail,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.8), secondaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 8)],
        ),
        child: const Center(
          child: Text(
            'Resend Verification Email',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }


}