import 'dart:async'; // For StreamSubscription
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentSnapshot
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart'; // Import for country list
import '../../../services/auth_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberPartController = TextEditingController();
  final _roleController = TextEditingController();

  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _phoneCountryCode; // e.g., "+92"
  String? _imageUrl;
  String? _uid;
  StreamSubscription<DocumentSnapshot>? _profileListener;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Define custom theme colors
  static const Color primaryColor = Color(0xFF004e92); // Deep blue
  static const Color secondaryColor = Color(0xFF000428); // Darker blue
  static const Color accentColor = Color(0xFF00C4B4); // Teal accent
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light gray background
  static const Color textColor = Color(0xFF2D3748); // Dark gray text

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);
    try {
      User? user = _authService.getCurrentUser();
      if (user == null) {
        _showSnackBar('No user signed in. Please log in.');
        Navigator.pop(context);
        return;
      }
      _uid = user.uid;
      print('Initializing user with UID: $_uid');
      _listenToProfileData();
    } catch (e) {
      _showSnackBar('Error initializing user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listenToProfileData() {
    _profileListener?.cancel(); // Cancel any existing subscription
    _profileListener = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        print('Profile data from Firebase: $userData');
        _updateProfileUI(userData);
      } else {
        _showSnackBar('User data not found in Firebase.');
        print('No data exists for UID: $_uid');
      }
    }, onError: (e) {
      _showSnackBar('Error listening to profile data: $e');
      print('Error in profile listener: $e');
    });
  }

  void _updateProfileUI(Map<String, dynamic> userData) {
    if (mounted) {
      setState(() {
        _fullNameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _roleController.text = userData['role'] ?? 'User';
        _imageUrl = userData['imageUrl'] ?? '';
        _phoneCountryCode = userData['phoneCountryCode']?.toString() ?? '+1'; // Default to "+1" if null
        _phoneNumberPartController.text = userData['phoneNumberPart'] ?? '';
        print('Updated UI: phoneCountryCode=$_phoneCountryCode, phoneNumberPart=${_phoneNumberPartController.text}');
      });
    }
  }

  bool _isValidPhoneNumberPart(String numberPart) => numberPart.length >= 9 && numberPart.length <= 12 && !numberPart.startsWith('0');

  Future<void> _saveProfile() async {
    if (_uid == null) {
      _showSnackBar('No user ID available. Please log in again.');
      return;
    }

    final phoneNumberPart = _phoneNumberPartController.text.trim();
    if (_fullNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email');
      return;
    }
    if (_phoneCountryCode == null) {
      _showSnackBar('Please select a country code');
      return;
    }
    if (!_isValidPhoneNumberPart(phoneNumberPart)) {
      _showSnackBar('Phone number must be 9-12 digits and not start with 0');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? newImageUrl = _imageUrl;
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/$_uid.jpg');
        await ref.putFile(_profileImage!, SettableMetadata(contentType: 'image/jpeg'));
        newImageUrl = await ref.getDownloadURL();
      }

      final updatedData = {
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneCountryCode': _phoneCountryCode!,
        'phoneNumberPart': phoneNumberPart,
        if (newImageUrl != null && newImageUrl.isNotEmpty) 'imageUrl': newImageUrl,
      };

      String? error = await _authService.updateUserData(_uid!, updatedData);
      if (error != null) {
        _showSnackBar(error);
      } else {
        setState(() {
          _isEditing = false;
          _imageUrl = newImageUrl;
          _profileImage = null;
        });
        _showSuccessDialog();
      }
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
        title: const Text('Choose Image Source', style: TextStyle(color: textColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera', style: TextStyle(color: accentColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: source, maxHeight: 800, maxWidth: 800);
        if (pickedFile != null) {
          setState(() => _profileImage = File(pickedFile.path));
        }
      } catch (e) {
        _showSnackBar('Error picking image: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: backgroundColor,
          title: const Text('Success', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 20)),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: accentColor, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Profile updated successfully!', style: TextStyle(fontSize: 16, color: textColor))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _profileListener?.cancel();
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberPartController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
          labelMedium: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _uid == null
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          automaticallyImplyLeading: false, // This removes the back button
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      // Gradient Background for the body
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF004e92),
            Color(0xFF000428),
          ],
          // begin: Alignment.topLeft,
          // end: Alignment.bottomRight,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, -6))],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileImage(),
                      const SizedBox(height: 32),
                      _buildTextField(_fullNameController, 'Full Name', Icons.person_outline, enabled: _isEditing),
                      const SizedBox(height: 20),
                      _buildTextField(_emailController, 'Email', Icons.email, enabled: _isEditing),
                      const SizedBox(height: 20),
                      _buildTextField(_roleController, 'Role', Icons.verified_user, enabled: false),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                      const SizedBox(height: 32),
                      _buildButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
              gradient: LinearGradient(colors: [primaryColor.withOpacity(0.8), accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: CircleAvatar(
              radius: 80,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                  ? NetworkImage(_imageUrl!)
                  : const NetworkImage('https://via.placeholder.com/150')) as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                ),
                child: const Icon(Icons.camera_alt, color: primaryColor, size: 28),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {required bool enabled}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 6),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  String _getIsoCountryCode(String phoneCountryCode) {
    final dialCode = phoneCountryCode.replaceAll('+', ''); // e.g., "92" from "+92"
    final country = countries.firstWhere(
          (c) => c.dialCode == dialCode,
      orElse: () => countries.firstWhere((c) => c.code == 'US'), // Default to US if not found
    );
    return country.code; // e.g., "PK" for "+92"
  }

  Widget _buildPhoneField() {
    String fullPhoneNumber = _phoneCountryCode != null && _phoneNumberPartController.text.isNotEmpty
        ? '$_phoneCountryCode${_phoneNumberPartController.text}'
        : 'Not set';

    print('Building phone field: phoneCountryCode=$_phoneCountryCode, phoneNumberPart=${_phoneNumberPartController.text}, fullPhoneNumber=$fullPhoneNumber');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 6),
        ],
      ),
      child: _isEditing
          ? IntlPhoneField(
        controller: _phoneNumberPartController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        initialCountryCode: _phoneCountryCode != null ? _getIsoCountryCode(_phoneCountryCode!) : 'US',
        enabled: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        invalidNumberMessage: 'Invalid phone number',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
        showCountryFlag: true,
        showDropdownIcon: true,
        flagsButtonPadding: const EdgeInsets.only(left: 12),
        onCountryChanged: (country) {
          setState(() {
            _phoneCountryCode = '+${country.dialCode}';
            print('Country changed to: $_phoneCountryCode');
          });
        },
        onChanged: (phone) {
          setState(() {
            _phoneCountryCode = phone.countryCode;
            _phoneNumberPartController.text = phone.number;
            print('Phone changed: countryCode=$_phoneCountryCode, number=${_phoneNumberPartController.text}');
          });
        },
        validator: (value) => (value == null || !_isValidPhoneNumberPart(value.number))
            ? 'Invalid phone number (9-12 digits, no leading 0)'
            : null,
      )
          : TextField(
        controller: TextEditingController(text: fullPhoneNumber),
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.phone, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isEditing)
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => setState(() {
              _isEditing = false;
              _profileImage = null;
              _listenToProfileData();
            }),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.grey, Colors.grey]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 8)],
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        if (_isEditing) const SizedBox(width: 16),
        GestureDetector(
          onTap: _isLoading ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_isEditing ? accentColor : primaryColor, _isEditing ? accentColor.withOpacity(0.8) : primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 8)],
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}