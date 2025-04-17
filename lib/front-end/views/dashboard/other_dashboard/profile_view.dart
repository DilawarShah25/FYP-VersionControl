import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../utils/app_theme.dart';
import '../../../Community/services/community_firebase_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final CommunityFirebaseService _service = CommunityFirebaseService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberPartController = TextEditingController();
  final _roleController = TextEditingController();
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _phoneCountryCode;
  String? _imageBase64;
  String? _uid;
  bool _showContactDetails = true;
  StreamSubscription<DocumentSnapshot>? _profileListener;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No user signed in. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      _uid = user.uid;
      _listenToProfileData();
    } catch (e) {
      _showSnackBar('Error initializing user: $e');
      debugPrint('Initialize error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listenToProfileData() {
    _profileListener?.cancel();
    _profileListener = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        _updateProfileUI(userData);
      } else {
        _showSnackBar('User data not found.');
        debugPrint('No Firestore data for user: $_uid');
      }
    }, onError: (e) {
      _showSnackBar('Error fetching profile: $e');
      debugPrint('Firestore listen error: $e');
    });
  }

  void _updateProfileUI(Map<String, dynamic> userData) {
    if (mounted) {
      setState(() {
        _fullNameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _roleController.text = userData['role'] ?? 'User';
        _imageBase64 = userData['image_base64'] is String && userData['image_base64'].isNotEmpty
            ? userData['image_base64']
            : null;
        _phoneCountryCode = userData['phoneCountryCode']?.toString() ?? '+1';
        _phoneNumberPartController.text = userData['phoneNumberPart'] ?? '';
        _showContactDetails = userData['showContactDetails'] ?? true;
      });
      debugPrint('Updated UI with Firestore data');
    }
  }

  bool _isValidPhoneNumberPart(String numberPart) =>
      numberPart.length >= 6 && numberPart.length <= 12 && !numberPart.startsWith('0');

  Future<void> _saveProfile() async {
    if (_uid == null) {
      _showSnackBar('No user ID. Please log in again.');
      debugPrint('No UID for save');
      return;
    }

    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumberPart = _phoneNumberPartController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter your full name');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email');
      return;
    }
    if (_phoneCountryCode == null) {
      _showSnackBar('Please select a country code');
      return;
    }
    if (!_isValidPhoneNumberPart(phoneNumberPart)) {
      _showSnackBar('Phone number must be 6-12 digits, no leading 0');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? newImageBase64 = _imageBase64;
      if (_profileImage != null) {
        if (!await _profileImage!.exists()) {
          _showSnackBar('Selected image file is missing or invalid.');
          setState(() => _profileImage = null);
          debugPrint('Invalid profile image');
          return;
        }
        final imageBytes = await _profileImage!.readAsBytes();
        newImageBase64 = base64Encode(imageBytes);
        debugPrint('Compressed image to base64 (length: ${newImageBase64.length})');
      }

      await _service.updateUserProfile(
        userId: _uid!,
        name: name,
        email: email,
        phoneCountryCode: _phoneCountryCode!,
        phoneNumberPart: phoneNumberPart,
        role: _roleController.text.trim(),
        imageBase64: newImageBase64,
        showContactDetails: _showContactDetails,
      );

      setState(() {
        _isEditing = false;
        _imageBase64 = newImageBase64;
        _profileImage = null;
      });
      _showSuccessDialog();
      debugPrint('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Error saving profile: $e');
      debugPrint('Save error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Image Source',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: Text('Camera', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: Text('Gallery', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() => _profileImage = File(pickedFile.path));
          debugPrint('Picked image: ${pickedFile.path}');
        } else {
          _showSnackBar('Failed to pick image.');
        }
      } catch (e) {
        _showSnackBar('Error picking image: $e');
        debugPrint('Image pick error: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(color: AppTheme.white)),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppTheme.white,
          title: Text(
            'Success',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile updated successfully!',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  ImageProvider? _buildImageProvider() {
    if (_profileImage != null && _profileImage!.existsSync()) {
      return FileImage(_profileImage!);
    }
    if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_imageBase64!));
      } catch (e) {
        debugPrint('Error decoding base64: $e');
        return null;
      }
    }
    return const AssetImage('assets/placeholder.png');
  }

  void _zoomImage() {
    final provider = _buildImageProvider();
    if (provider != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image(image: provider, fit: BoxFit.contain),
          ),
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
      data: AppTheme.theme,
      child: Scaffold(
        body: _uid == null || _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildContent()),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.white,
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _fullNameController.text.isEmpty ? 'Your Profile' : _fullNameController.text,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: _buildProfileImage()),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : _zoomImage,
      child: Hero(
        tag: 'profile_image_$_uid',
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.accentColor,
                  backgroundImage: _buildImageProvider(),
                  onBackgroundImageError: (_, __) {
                    debugPrint('Image load error');
                    setState(() => _imageBase64 = null);
                  },
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppTheme.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingMedium),
                _buildTextField(_fullNameController, 'Full Name', Icons.person_outline, enabled: _isEditing),
                const SizedBox(height: AppTheme.paddingMedium),
                _buildTextField(_emailController, 'Email', Icons.email, enabled: _isEditing),
                const SizedBox(height: AppTheme.paddingMedium),
                _buildTextField(_roleController, 'Role', Icons.verified_user, enabled: false),
                const SizedBox(height: AppTheme.paddingMedium),
                _buildPhoneField(),
                const SizedBox(height: AppTheme.paddingMedium),
                if (_isEditing)
                  SwitchListTile(
                    title: Text(
                      'Show contact details to others',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    value: _showContactDetails,
                    onChanged: (value) {
                      setState(() => _showContactDetails = value);
                    },
                    activeColor: AppTheme.secondaryColor,
                  ),
                const SizedBox(height: AppTheme.paddingLarge),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {required bool enabled}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }

  String _getIsoCountryCode(String phoneCountryCode) {
    final dialCode = phoneCountryCode.replaceAll('+', '');
    final country = countries.firstWhere(
          (c) => c.dialCode == dialCode,
      orElse: () => countries.firstWhere((c) => c.code == 'US'),
    );
    return country.code;
  }

  Widget _buildPhoneField() {
    String fullPhoneNumber = _phoneCountryCode != null && _phoneNumberPartController.text.isNotEmpty
        ? '$_phoneCountryCode${_phoneNumberPartController.text}'
        : 'Not set';

    return _isEditing
        ? IntlPhoneField(
      controller: _phoneNumberPartController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor),
        ),
      ),
      initialCountryCode: _phoneCountryCode != null ? _getIsoCountryCode(_phoneCountryCode!) : 'US',
      enabled: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      invalidNumberMessage: 'Invalid phone number',
      onCountryChanged: (country) {
        setState(() {
          _phoneCountryCode = '+${country.dialCode}';
        });
      },
      validator: (value) => (value == null || !_isValidPhoneNumberPart(value.number))
          ? 'Invalid phone number (6-12 digits, no leading 0)'
          : null,
    )
        : TextField(
      controller: TextEditingController(text: fullPhoneNumber),
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.3),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isEditing)
          ScaleTransition(
            scale: _scaleAnimation,
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                setState(() {
                  _isEditing = false;
                  _profileImage = null;
                });
                _listenToProfileData();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16)),
            ),
          ),
        if (_isEditing) const SizedBox(width: AppTheme.paddingMedium),
        ScaleTransition(
          scale: _scaleAnimation,
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
            child: _isLoading
                ? const CircularProgressIndicator(color: AppTheme.white)
                : Text(_isEditing ? 'Save' : 'Edit', style: GoogleFonts.poppins(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}