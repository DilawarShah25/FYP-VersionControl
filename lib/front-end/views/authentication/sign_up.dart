import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? errorMessage;
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => email.contains('@') && email.contains('.');
  bool _isValidPassword(String password) => password.length >= 6 && RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  bool _isValidUsername(String username) => username.length >= 3 && !username.contains(' ');

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => errorMessage = 'All fields are required.');
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() => errorMessage = 'Username must be at least 3 characters with no spaces.');
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

    try {
      // Check if username is unique
      final usernameQuery = await _firestore.collection('users').where('username', isEqualTo: username).get();
      if (usernameQuery.docs.isNotEmpty) {
        setState(() => errorMessage = 'Username already taken.');
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'username': username,
        'email': email,
        'role': _selectedRole,
        'phone': '',
        'imageUrl': '',
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('username', username);
      await prefs.setString('email', email);
      await prefs.setString('role', _selectedRole);
      await prefs.setString('phone', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration Successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = "Error: ${e.toString()}");
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
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: const Radius.circular(40)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_add, size: 50, color: Color(0xFF1976D2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Account',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          const Text(
            'Join the Hair Fall System',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          _buildTextField(_nameController, "Full Name", Icons.person),
          const SizedBox(height: 20),
          _buildTextField(_usernameController, "Username", Icons.account_circle),
          const SizedBox(height: 20),
          _buildTextField(_emailController, "Email", Icons.email, isEmail: true),
          const SizedBox(height: 20),
          _buildPasswordField(_passwordController, "Password"),
          const SizedBox(height: 20),
          _buildPasswordField(_confirmPasswordController, "Confirm Password", isConfirm: true),
          const SizedBox(height: 20),
          _buildRoleSelection(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(errorMessage!, style: const TextStyle(color: Color(0xFFD32F2F))),
            ),
          const SizedBox(height: 20),
          _buildRegisterButton(),
          const SizedBox(height: 20),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white.withOpacity(0.1), offset: const Offset(-4, -4), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white.withOpacity(0.1), offset: const Offset(-4, -4), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isConfirm ? !_showConfirmPassword : !_showPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirm ? (_showConfirmPassword ? Icons.visibility : Icons.visibility_off) : (_showPassword ? Icons.visibility : Icons.visibility_off),
              color: Colors.white70,
            ),
            onPressed: () => setState(() => isConfirm ? _showConfirmPassword = !_showConfirmPassword : _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
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
        label: Text(role, style: TextStyle(color: _selectedRole == role ? Colors.blue : Colors.white70)),
        selected: _selectedRole == role,
        onSelected: (selected) => setState(() => _selectedRole = role),
        selectedColor: Colors.white.withOpacity(0.2),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white70),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _register,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 8)],
        ),
        child: const Center(
          child: Text(
            'Register',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}