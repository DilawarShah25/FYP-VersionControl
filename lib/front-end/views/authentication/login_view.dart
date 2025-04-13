import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalpsense/front-end/views/authentication/sign_up.dart';
import '../../controllers/screen_navigation_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _showPassword = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    print('Initiating login for: $email');
    final result = await _authService.signInWithEmailAndPassword(email, password);

    setState(() => _isLoading = false);

    if (result['error'] == null) {
      print('Login successful, navigating to ScreensManager');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScreensManager()),
      );
    } else {
      setState(() {
        _errorMessage = result['error'];
      });
      print('Login failed: $_errorMessage');
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading || _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final result = await _authService.resetPassword(email);

    setState(() => _isLoading = false);

    if (result == null) {
      setState(() {
        _errorMessage = 'Password reset link sent! Check your email.';
      });
    } else {
      setState(() {
        _errorMessage = result;
      });
      print('Password reset failed: $_errorMessage');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.white,
            child: Icon(Icons.person, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.white),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Login',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
              ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Create a new account'),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpView())),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}