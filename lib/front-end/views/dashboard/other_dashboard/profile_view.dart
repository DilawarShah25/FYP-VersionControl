import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();

  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;
  PhoneNumber? _initialPhoneNumber;
  String? _currentCountryCode;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadProfileData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('phone') ?? '+923437649799';
      setState(() {
        _fullNameController.text = prefs.getString('name') ?? 'John Doe';
        _emailController.text = prefs.getString('email') ?? 'johndoe@example.com';
        _roleController.text = prefs.getString('role') ?? 'User';
        _initialPhoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: savedPhone);
        _phoneController.text = _initialPhoneNumber!.number;
        _currentCountryCode = _initialPhoneNumber!.countryCode;
      });
    } catch (e) {
      _showSnackBar('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _fullNameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      // Save complete phone number with country code
      final completePhoneNumber = '$_currentCountryCode${_phoneController.text.trim()}';
      await prefs.setString('phone', completePhoneNumber);

      setState(() => _isEditing = false);
      _showSuccessDialog();
    } catch (e) {
      _showSnackBar('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxHeight: 800,
          maxWidth: 800,
        );
        if (pickedFile != null) {
          setState(() => _profileImage = File(pickedFile.path));
        }
      } catch (e) {
        _showSnackBar('Error picking image: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        title: const Text(
          'Success',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profile updated successfully!',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004e92), Color(0xFF000428)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF004e92), Color(0xFF000428)]),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileImage(),
                    const SizedBox(height: 30),
                    _buildTextField(_fullNameController, 'Full Name', Icons.person_outline, enabled: _isEditing),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email', Icons.email, enabled: _isEditing),
                    const SizedBox(height: 20),
                    _buildTextField(_roleController, 'Role', Icons.verified_user, enabled: false),
                    const SizedBox(height: 20),
                    _buildPhoneField(),
                    const SizedBox(height: 30),
                    _buildEditSaveButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 80,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        required bool enabled,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 2), blurRadius: 5),
          BoxShadow(color: Colors.white.withOpacity(0.7), offset: const Offset(-2, -2), blurRadius: 5),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 2), blurRadius: 5),
          BoxShadow(color: Colors.white.withOpacity(0.7), offset: const Offset(-2, -2), blurRadius: 5),
        ],
      ),
      child: IntlPhoneField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
        initialCountryCode: _initialPhoneNumber?.countryISOCode,
        initialValue: _initialPhoneNumber?.number,
        enabled: _isEditing,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        invalidNumberMessage: 'Invalid phone number',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        showCountryFlag: true,
        showDropdownIcon: _isEditing,
        flagsButtonPadding: const EdgeInsets.only(left: 10),
        onChanged: (phone) {
          if (_isEditing) {
            setState(() {
              _phoneController.text = phone.number;
              _currentCountryCode = '+${phone.countryCode}';
            });
          }
        },
        onCountryChanged: (country) {
          if (_isEditing) {
            setState(() {
              _currentCountryCode = '+${country.dialCode}';
            });
          }
        },
      ),
    );
  }

  Widget _buildEditSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _isEditing ? Colors.green : Colors.blue,
              _isEditing ? Colors.green.shade700 : Colors.blue.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            _isEditing ? 'Save' : 'Edit Profile',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}