import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../Community/view/chat_screen.dart';
import '../../../controllers/session_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../Community/services/community_firebase_service.dart';

class ProfileView extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ProfileView({super.key, this.userId, this.userName});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final CommunityFirebaseService _service = CommunityFirebaseService();
  final SessionController _sessionController = SessionController();
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
  bool _isOwnProfile = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setSystemUiOverlayStyle();
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

  void _setSystemUiOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _initializeUser() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('No user signed in. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _uid = widget.userId ?? currentUser.uid;
      _isOwnProfile = widget.userId == null || widget.userId == currentUser.uid;

      if (_isOwnProfile) {
        _listenToProfileData();
      } else {
        final userData = await _service.getUserProfile(_uid!);
        if (userData != null) {
          _updateProfileUI(userData);
        } else {
          _showSnackBar('User data not found.');
          debugPrint('No Firestore data for user: $_uid');
        }
      }
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
        _fullNameController.text = userData['name'] ?? widget.userName ?? '';
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),

        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          extendBodyBehindAppBar: true,
          body: _uid == null || _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor))
              : Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.white),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await _sessionController.clearSession();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    debugPrint('Logged out');
                  },
                )
              else
                IconButton(


                  icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
              const Spacer(),
              if (_isOwnProfile)
                const SizedBox(width: 40)
              else
                IconButton(
                  icon: const Icon(Icons.message, color: AppTheme.white),
                  tooltip: 'Send Message',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: _uid!,
                          otherUserName: _fullNameController.text.isEmpty
                              ? widget.userName ?? 'User'
                              : _fullNameController.text,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isEditing ? _pickImage : _zoomImage,
            child: Hero(
              tag: 'profile_image_$_uid',
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.accentColor,
                        backgroundImage: _buildImageProvider(),
                        onBackgroundImageError: (_, __) {
                          debugPrint('Image load error');
                          setState(() => _imageBase64 = null);
                        },
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.white, width: 1),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppTheme.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fullNameController.text.isEmpty ? widget.userName ?? 'Profile' : _fullNameController.text,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],
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
          color: AppTheme.white,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
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
                const SizedBox(height: 8),
                Flexible(
                  child: _buildTextField(
                    _fullNameController,
                    'Full Name',
                    Icons.person_outline,
                    enabled: _isEditing,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    enabled: _isEditing,
                    visible: _isOwnProfile || _showContactDetails,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: _buildTextField(
                    _roleController,
                    'Role',
                    Icons.verified_user,
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(child: _buildPhoneField()),
                if (_isOwnProfile) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      'Show contact details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    value: _showContactDetails,
                    onChanged: _isEditing
                        ? (value) {
                      setState(() => _showContactDetails = value);
                    }
                        : null,
                    activeColor: AppTheme.secondaryColor,
                    activeTrackColor: AppTheme.secondaryColor.withOpacity(0.4),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    dense: true,
                  ),
                  const SizedBox(height: 8),
                  _buildButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {required bool enabled, bool visible = true}) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: enabled ? Colors.black54 : Colors.black45,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
      ),
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

    if (!_isOwnProfile && !_showContactDetails) {
      return const SizedBox.shrink();
    }

    return _isEditing
        ? IntlPhoneField(
      controller: _phoneNumberPartController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: GoogleFonts.poppins(
          color: Colors.black54,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 1.2),
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
      ),
      validator: (value) => (value == null || !_isValidPhoneNumberPart(value.number))
          ? 'Invalid phone number (6-12 digits, no leading 0)'
          : null,
      dropdownIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 18),
      flagsButtonPadding: const EdgeInsets.only(left: 8),
    )
        : TextField(
      controller: TextEditingController(text: fullPhoneNumber),
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: GoogleFonts.poppins(
          color: Colors.black45,
          fontSize: 12,
        ),
        prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: AppTheme.accentColor.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
      ),
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
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.7)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppTheme.white,
                elevation: 2,
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        if (_isEditing) const SizedBox(width: 8),
        ScaleTransition(
          scale: _scaleAnimation,
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              shadowColor: AppTheme.secondaryColor.withOpacity(0.3),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppTheme.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _isEditing ? 'Save' : 'Edit',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}