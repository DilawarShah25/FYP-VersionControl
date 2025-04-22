import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'login_view.dart';

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
  String? _username;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _startVerificationCheck();
  }

  Future<void> _fetchUsername() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          setState(() {
            _username = snapshot.get('username');
          });
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        bool isVerified = await _authService.isEmailVerified();
        if (isVerified) {
          timer.cancel();
          setState(() {
            _message = 'Email verified successfully!';
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            }
          });
        }
      } catch (e) {
        print('❌ Error checking verification: $e');
        setState(() {
          _message = 'Error checking verification.';
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    print('Attempting to resend verification email');
    final result = await _authService.resendVerificationEmail();

    setState(() {
      _isLoading = false;
      _message = result ?? 'Verification email resent. Check your inbox and spam folder.';
    });

    if (result != null) {
      print('Resend failed: $result');
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Your Email'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'A verification email has been sent to ${widget.email}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_username != null) ...[
                      const SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        'Your username: $_username',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'Waiting for verification...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    if (_message != null)
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _message!.contains('successfully')
                              ? AppTheme.secondaryColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _resendVerificationEmail,
                      child: const Text('Resend Verification Email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}