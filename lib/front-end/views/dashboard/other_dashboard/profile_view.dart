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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSuccessDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: const Text('Success', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Profile updated successfully!', style: TextStyle(fontSize: 16, color: Colors.black87))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: _buildAppBar(),
      body: _uid == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildBody(),
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
          title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,

        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF004e92), Color(0xFF000428)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -4))],
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
                      _buildButtons(),
                      const SizedBox(height: 30),
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
              gradient: LinearGradient(colors: [Colors.blue.shade200, Colors.blue.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {required bool enabled}) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }

  // Helper method to get ISO country code from phone country code
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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 2), blurRadius: 5),
          BoxShadow(color: Colors.white.withOpacity(0.7), offset: const Offset(-2, -2), blurRadius: 5),
        ],
      ),
      child: _isEditing
          ? IntlPhoneField(
        controller: _phoneNumberPartController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
        initialCountryCode: _phoneCountryCode != null
            ? _getIsoCountryCode(_phoneCountryCode!) // Convert "+92" to "PK"
            : 'US', // Default to "US" if null
        enabled: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        invalidNumberMessage: 'Invalid phone number',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        showCountryFlag: true,
        showDropdownIcon: true,
        flagsButtonPadding: const EdgeInsets.only(left: 10),
        onCountryChanged: (country) {
          setState(() {
            _phoneCountryCode = '+${country.dialCode}';
            print('Country changed to: $_phoneCountryCode');
          });
        },
        onChanged: (phone) {
          setState(() {
            _phoneCountryCode = phone.countryCode; // e.g., "+92"
            _phoneNumberPartController.text = phone.number; // e.g., "3001234567"
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
          labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
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
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.grey, Colors.grey.shade700]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 8)],
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ),
        if (_isEditing) const SizedBox(width: 20),
        GestureDetector(
          onTap: _isLoading ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_isEditing ? Colors.green : Colors.blue, _isEditing ? Colors.green.shade700 : Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 8)],
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}