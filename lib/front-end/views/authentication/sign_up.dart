import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_utils.dart';
import 'verification_view.dart';
import 'dart:io';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberPartController = TextEditingController();

  File? _profileImage;
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Image Source',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await ImageUtils.pickImage(source);
      if (image != null) {
        setState(() {
          _profileImage = image;
          _errorMessage = null;
        });
      }
    }
  }

  Future<void> _register() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

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
      return;
    }

    print('Initiating registration for: $email');
    final result = await _authService.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      phoneCountryCode: phoneCountryCode,
      phoneNumberPart: phoneNumberPart,
      role: _selectedRole,
      profileImage: _profileImage,
    );

    setState(() => _isLoading = false);

    if (result['error'] == null) {
      print('Registration successful, saving preferences');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('role', _selectedRole);
      await prefs.setString('phoneCountryCode', phoneCountryCode);
      await prefs.setString('phoneNumberPart', phoneNumberPart);
      await prefs.setString('image_base64', result['image_base64'] ?? '');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerificationView(email: email)),
      );
    } else {
      setState(() {
        _errorMessage = result['error'];
      });
      print('Registration failed: $_errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
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
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.accentColor,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/placeholder.png') as ImageProvider,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 20, color: AppTheme.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.white),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Join the Hair Loss System',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.trim().isEmpty) return 'Enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              IntlPhoneField(
                controller: _phoneNumberPartController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
                initialCountryCode: 'US',
                onCountryChanged: (country) {
                  setState(() => _phoneCountryCode = '+${country.dialCode}');
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) return 'Enter a phone number';
                  final number = phone.number;
                  if (number.length < 6 || number.length > 12 || number.startsWith('0')) {
                    return 'Enter a valid phone number (6-12 digits, no leading 0)';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value!.isEmpty) return 'Enter a password';
                  if (value.length < 6 || !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                    return 'Password must be 6+ chars with a special char';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                obscureText: !_showConfirmPassword,
                validator: (value) {
                  if (value!.isEmpty) return 'Confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['User', 'Admin'].map((role) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: _selectedRole == role,
                      onSelected: (selected) => setState(() => _selectedRole = role),
                      selectedColor: AppTheme.secondaryColor,
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }).toList(),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.paddingMedium),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppTheme.paddingLarge),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Login'),
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