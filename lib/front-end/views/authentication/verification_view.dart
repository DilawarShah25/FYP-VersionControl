import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';


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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    bool isVerified = await _authService.isEmailVerified();
    setState(() {
      _isLoading = false;
      if (isVerified) {
        _message = 'Email verified successfully!';
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home'); // Replace with your home route
        });
      } else {
        _message = 'Email not yet verified. Please check your inbox.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
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
                const SizedBox(height: 20),
                if (_message != null)
                  Text(
                    _message!,
                    style: const TextStyle(fontSize: 16, color: Colors.yellow),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'I’ve Verified My Email',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _resendVerificationEmail,
                  child: const Text(
                    'Resend Verification Email',
                    style: TextStyle(fontSize: 16, color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _authService.signOut().then((_) => Navigator.pop(context)),
                  child: const Text(
                    'Cancel and Sign Out',
                    style: TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}