import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedRole = 'User';
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

      setState(() => _isLoading = false);

      if (result['error'] == null) {
        await _sessionController.saveLastLogin();
        debugPrint('Registration successful, session saved, navigating to VerificationView');
        try {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationView(email: email)),
          );
          debugPrint('Navigation to VerificationView completed');
        } catch (e) {
          debugPrint('Navigation error: $e');
          setState(() {
            _isLoading = false;
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
        _isLoading = false;
        _errorMessage = 'Unexpected error during registration: ${e.toString()}';
      });
      debugPrint('Unexpected error in _register: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildForm()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.paddingLarge,
        horizontal: AppTheme.paddingMedium,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Join the Hair Loss System',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.paddingSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.3),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be 2+ chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.3),
                ),
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              IntlPhoneField(
                controller: _phoneNumberPartController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.3),
                ),
                initialCountryCode: 'US',
                style: GoogleFonts.poppins(fontSize: 14),
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
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: AppTheme.primaryColor),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.3),
                ),
                obscureText: !_showPassword,
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }
                  if (value.length < 6 || !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                    return '6+ chars with a special char';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: AppTheme.primaryColor),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.3),
                ),
                obscureText: !_showConfirmPassword,
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['User', 'Admin'].map((role) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                    child: ChoiceChip(
                      label: Text(role, style: GoogleFonts.poppins(fontSize: 14)),
                      selected: _selectedRole == role,
                      onSelected: (selected) => setState(() => _selectedRole = role),
                      selectedColor: AppTheme.secondaryColor,
                      backgroundColor: AppTheme.accentColor,
                      labelStyle: TextStyle(color: _selectedRole == role ? AppTheme.white : Colors.black),
                    ),
                  );
                }).toList(),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppTheme.paddingMedium),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Register',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: GoogleFonts.poppins(fontSize: 12)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}