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
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
        extendBodyBehindAppBar: true,
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppTheme.paddingMedium),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppTheme.paddingLarge,
        MediaQuery.of(context).padding.top + AppTheme.paddingLarge,
        AppTheme.paddingLarge,
        AppTheme.paddingLarge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        // For solid color, uncomment below and comment gradient
        // color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.white,
            child: Icon(
              Icons.person_add_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Join the Hair Loss System',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: AppTheme.paddingMedium),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                keyboardType: TextInputType.emailAddress,
                style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: AppTheme.paddingMedium),
              IntlPhoneField(
                controller: _phoneNumberPartController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                initialCountryCode: 'US',
                style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: AppTheme.paddingMedium),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                obscureText: !_showPassword,
                style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: AppTheme.paddingMedium),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                obscureText: !_showConfirmPassword,
                style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['User', 'Admin'].map((role) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                    child: ChoiceChip(
                      label: Text(role, style: Theme.of(context).textTheme.bodyMedium),
                      selected: _selectedRole == role,
                      onSelected: (selected) => setState(() => _selectedRole = role),
                      selectedColor: AppTheme.secondaryColor,
                      backgroundColor: AppTheme.accentColor,
                      labelStyle: TextStyle(
                        color: _selectedRole == role ? AppTheme.white : Colors.black87,
                      ),
                      elevation: 2,
                      pressElevation: 4,
                    ),
                  );
                }).toList(),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.paddingMedium, bottom: AppTheme.paddingSmall),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppTheme.paddingMedium),
              _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  'Register',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
                    child: Text(
                      'Login',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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