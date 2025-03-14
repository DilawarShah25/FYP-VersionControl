import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import 'verification_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberPartController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;
  String? errorMessage;
  String? _phoneCountryCode;
  String _selectedRole = 'User';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

  bool _isValidEmail(String email) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  bool _isValidPassword(String password) => password.length >= 6 && RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  bool _isValidPhoneNumberPart(String numberPart) => numberPart.length >= 6 && numberPart.length <= 12 && !numberPart.startsWith('0');

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedOption = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1976D2)),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (pickedOption != null) {
      final XFile? pickedFile = await picker.pickImage(source: pickedOption);
      if (pickedFile != null) setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phoneNumberPart = _phoneNumberPartController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phoneNumberPart.isEmpty) {
      setState(() => errorMessage = 'All fields are required.');
      return;
    }

    if (_phoneCountryCode == null) {
      setState(() => errorMessage = 'Please select a country code.');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = 'Invalid email format.');
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() => errorMessage = 'Password must be 6+ characters with a special character.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => errorMessage = 'Passwords do not match.');
      return;
    }

    if (!_isValidPhoneNumberPart(phoneNumberPart)) {
      setState(() => errorMessage = 'Invalid phone number (9-12 digits, no leading 0).');
      return;
    }

    print('Registering with:');
    print('Name: $name');
    print('Email: $email');
    print('PhoneCountryCode: $_phoneCountryCode');
    print('PhoneNumberPart: $phoneNumberPart');
    print('Role: $_selectedRole');

    Map<String, dynamic> result = await _authService.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      phoneCountryCode: _phoneCountryCode!,
      phoneNumberPart: phoneNumberPart,
      role: _selectedRole,
      profileImage: _profileImage,
    );

    if (result['error'] == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('role', _selectedRole);
      await prefs.setString('phoneCountryCode', _phoneCountryCode!);
      await prefs.setString('phoneNumberPart', phoneNumberPart);
      await prefs.setString('imageUrl', result['imageUrl'] ?? '');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerificationView(email: email)),
      );
    } else {
      setState(() => errorMessage = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSignUpForm(),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF1976D2), size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Join the Hair Loss System',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 20),
            _buildTextField(_emailController, "Email", Icons.email, isEmail: true),
            const SizedBox(height: 20),
            _buildPhoneField(),
            const SizedBox(height: 20),
            _buildPasswordField(_passwordController, "Password"),
            const SizedBox(height: 20),
            _buildPasswordField(_confirmPasswordController, "Confirm Password", isConfirm: true),
            const SizedBox(height: 25),
            _buildRoleSelection(),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 25),
            _buildRegisterButton(),
            const SizedBox(height: 20),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Please enter $label';
          if (isEmail && !_isValidEmail(value)) return 'Please enter a valid email';
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntlPhoneField(
        controller: _phoneNumberPartController,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        showCountryFlag: true,
        flagsButtonPadding: const EdgeInsets.only(left: 10),
        onCountryChanged: (country) {
          setState(() => _phoneCountryCode = '+${country.dialCode}');
        },
        onChanged: (phone) {
          setState(() => _phoneNumberPartController.text = phone.number);
        },
        validator: (value) {
          if (value == null || value.number.isEmpty) return 'Please enter a phone number';
          if (!_isValidPhoneNumberPart(value.number)) return 'Invalid phone number (9-12 digits, no leading 0)';
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isConfirm ? !_showConfirmPassword : !_showPassword,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF1976D2)),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirm ? (_showConfirmPassword ? Icons.visibility : Icons.visibility_off) : (_showPassword ? Icons.visibility : Icons.visibility_off),
              color: const Color(0xFF1976D2),
            ),
            onPressed: () => setState(() => isConfirm ? _showConfirmPassword = !_showConfirmPassword : _showPassword = !_showPassword),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (!isConfirm && !_isValidPassword(value)) return 'Password must be 6+ characters with a special character';
          if (isConfirm && value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['User', 'Admin'].map((role) => _roleButton(role)).toList(),
    );
  }

  Widget _roleButton(String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ChoiceChip(
        label: Text(
          role,
          style: TextStyle(
            color: _selectedRole == role ? Colors.white : const Color(0xFF1976D2),
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: _selectedRole == role,
        onSelected: (selected) => setState(() => _selectedRole = role),
        selectedColor: const Color(0xFF1976D2),
        backgroundColor: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(maxWidth: 300, minHeight: 50),
          child: const Text(
            'Register',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            "Login",
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}