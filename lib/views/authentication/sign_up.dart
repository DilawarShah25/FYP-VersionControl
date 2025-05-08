import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../controllers/session_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'verification_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SessionController _sessionController = SessionController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberPartController = TextEditingController();

  String? _errorMessage;
  String? _phoneCountryCode;
  String _selectedRole = 'User'; // Default role
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberPartController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      debugPrint('Form validation failed or already loading');
      setState(() {
        _errorMessage = 'Please fill all fields correctly.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneNumberPart = _phoneNumberPartController.text.trim();
    final phoneCountryCode = _phoneCountryCode;

    if (phoneCountryCode == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please select a country code.';
      });
      debugPrint('Error: No country code selected');
      return;
    }

    debugPrint('Initiating registration for: $email');
    debugPrint('Input parameters: name=$name, email=$email, phone=$phoneCountryCode$phoneNumberPart, role=$_selectedRole');

    try {
      final result = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        phoneCountryCode: phoneCountryCode,
        phoneNumberPart: phoneNumberPart,
        role: _selectedRole,
      );

      debugPrint('Registration result: $result');

      if (result['error'] == null) {
        await _sessionController.saveLastLogin();
        debugPrint('Registration successful, session saved');

        if (!mounted) {
          debugPrint('Context not mounted, aborting navigation');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Navigation failed: Context not available.';
          });
          return;
        }

        try {
          debugPrint('Navigating to VerificationView for email: $email');
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationView(email: email)),
          );
          debugPrint('Navigation to VerificationView completed');
        } catch (e) {
          debugPrint('Navigation error: $e');
          setState(() {
            _errorMessage = 'Failed to navigate to verification screen: ${e.toString()}';
          });
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Unknown registration error';
        });
        debugPrint('Registration failed: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error during registration: ${e.toString()}';
      });
      debugPrint('Unexpected error in _register: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E0), Color(0xFFFFF3F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6D00), size: 24),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(8),
        ),
        const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 48), // Spacer for symmetry
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'John Doe',
                hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be 2+ chars';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'johndoe@gmail.com',
                hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntlPhoneField(
              controller: _phoneNumberPartController,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              initialCountryCode: 'US',
              style: const TextStyle(fontSize: 16),
              onCountryChanged: (country) {
                setState(() => _phoneCountryCode = '+${country.dialCode}');
              },
              validator: (phone) {
                if (phone == null || phone.number.isEmpty) {
                  return 'Enter a phone number';
                }
                final number = phone.number;
                if (!RegExp(r'^[1-9][0-9]{5,11}$').hasMatch(number)) {
                  return '6-12 digits, no leading 0';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Semantics(
              label: 'Role Selection',
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  hintText: 'Select Role',
                  hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
                items: const [
                  DropdownMenuItem(
                    value: 'User',
                    child: Text('User'),
                  ),
                  DropdownMenuItem(
                    value: 'Doctor',
                    child: Text('Doctor'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
                dropdownColor: Colors.white,
                iconEnabledColor: const Color(0xFFFF6D00),
                focusColor: const Color(0xFFFF6D00),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Semantics(
                  label: _showPassword ? 'Hide password' : 'Show password',
                  child: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFFFF6D00),
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),
              obscureText: !_showPassword,
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a password';
                }
                if (value.length < 6 || !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                  return '6+ chars with a special char';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Semantics(
                  label: _showConfirmPassword ? 'Hide confirm password' : 'Show confirm password',
                  child: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFFFF6D00),
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              obscureText: !_showConfirmPassword,
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
            ),
          )
              : Semantics(
            label: 'Sign Up Button',
            child: ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'By clicking the button, you accept ScalpSense’s Terms of Service and Privacy Policy',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6D00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}