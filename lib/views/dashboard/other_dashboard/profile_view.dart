import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Community/view/chat_screen.dart';
import '../../../Community/services/community_firebase_service.dart';
import '../../../controllers/session_controller.dart';
import '../../../models/profile_data.dart';
import '../../../utils/app_theme.dart';

class ProfileView extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ProfileView({super.key, this.userId, this.userName});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final _service = CommunityFirebaseService();
  final _sessionController = SessionController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _username, _imageBase64, _role, _errorMessage;
  bool _isLoading = true, _isOwnProfile = false, _isEditing = false, _isUploadingImage = false;
  ProfileData? _profile;
  late AnimationController _animationController;
  late Animation<double> _avatarScaleAnimation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = widget.userId ?? user?.uid;
    if (uid == null) {
      setState(() {
        _errorMessage = 'No user logged in';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isOwnProfile = user != null && uid == user.uid);

    try {
      final profile = await _service.getUserProfile(uid);
      if (profile == null) {
        setState(() {
          _errorMessage = 'Profile not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _username = profile.username ?? widget.userName ?? user?.email?.split('@')[0] ?? 'Unknown';
        _emailController.text = profile.showEmail || _isOwnProfile ? profile.email : 'Restricted';
        _phoneController.text = (profile.showPhone || _isOwnProfile) && profile.phoneNumberPart.isNotEmpty
            ? '${profile.phoneCountryCode}${profile.phoneNumberPart}'
            : 'Restricted';
        _imageBase64 = profile.imageBase64;
        _role = profile.role;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (!_isOwnProfile || !_isEditing) return;
    setState(() => _isUploadingImage = true);

    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Image Source', style: Theme.of(context).textTheme.headlineMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text('Gallery', style: Theme.of(context).textTheme.bodyMedium),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text('Camera', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );

      if (source == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 1 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Image size exceeds 1MB limit';
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image size exceeds 1MB limit', style: Theme.of(context).textTheme.bodyMedium)),
          );
          return;
        }
        final base64String = base64Encode(bytes);
        setState(() {
          _imageBase64 = base64String;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected successfully', style: Theme.of(context).textTheme.bodyMedium)),
        );
      } else {
        setState(() {
          _errorMessage = 'No image selected';
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected', style: Theme.of(context).textTheme.bodyMedium)),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error picking image: $e';
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_isOwnProfile || !_isEditing) return;
    setState(() => _isLoading = true);

    try {
      // Validate inputs
      if (_imageBase64 != null) {
        try {
          base64Decode(_imageBase64!);
        } catch (e) {
          setState(() {
            _errorMessage = 'Invalid image data';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid image data', style: Theme.of(context).textTheme.bodyMedium)),
          );
          return;
        }
      }

      // Update profile with current data, ensuring username is preserved
      await _service.createUserProfile(
        userId: _profile!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().startsWith(_profile!.phoneCountryCode)
            ? _phoneController.text.trim().substring(_profile!.phoneCountryCode.length)
            : _phoneController.text.trim(),
        phoneCountryCode: _profile!.phoneCountryCode,
        imageBase64: _imageBase64,
        showContactDetails: _profile!.showContactDetails,
      );

      // Refresh profile to ensure UI reflects saved data
      await _fetchProfile();

      setState(() {
        _isEditing = false;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes done successfully', style: Theme.of(context).textTheme.bodyMedium)),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      setState(() {
        _errorMessage = 'Error saving: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _sessionController.clearSession();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint('Error logging out: $e');
      setState(() {
        _errorMessage = 'Error logging out: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: widget.userId!,
          otherUserName: _nameController.text.isEmpty ? widget.userName ?? 'User' : _nameController.text,
        ),
      ),
    );
  }

  InputDecoration _readOnlyDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
      ),
      filled: true,
      fillColor: AppTheme.accentColor.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }

  InputDecoration _editableDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
      ),
      filled: true,
      fillColor: AppTheme.accentColor.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }

  Widget _buildProfileHeader() {
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
          if (!_isOwnProfile)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          AnimatedBuilder(
            animation: _avatarScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _avatarScaleAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.accentColor,
                      backgroundImage: _imageBase64 != null ? MemoryImage(base64Decode(_imageBase64!)) : null,
                      child: _imageBase64 == null
                          ? Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    if (_isOwnProfile && _isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
                              color: AppTheme.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'User',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_username != null)
          const SizedBox(height: AppTheme.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isOwnProfile) ...[
                ElevatedButton(
                  onPressed: _toggleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    _isEditing ? 'Cancel' : 'Edit',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.secondaryColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded, color: AppTheme.secondaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _navigateToChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.secondaryColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    'Message',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium, vertical: AppTheme.paddingSmall),
        child: Container(
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Details',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextField(
                    controller: TextEditingController(text: _username),
                    decoration: _readOnlyDecoration('Username'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: true,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextField(
                    controller: _nameController,
                    decoration: _editableDecoration('Full Name'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: !_isOwnProfile || !_isEditing,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextField(
                    controller: _emailController,
                    decoration: _editableDecoration('Email'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: !_isOwnProfile || !_isEditing,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextField(
                    controller: _phoneController,
                    decoration: _editableDecoration('Phone'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: !_isOwnProfile || !_isEditing,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  TextField(
                    controller: TextEditingController(text: _role),
                    decoration: _readOnlyDecoration('Role'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    readOnly: true,
                  ),
                  if (_isOwnProfile && _isEditing) ...[
                    const SizedBox(height: AppTheme.paddingLarge),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          elevation: 2,
                        ),
                        child: Text(
                          'Save Changes',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          )
              : _errorMessage != null && _profile == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingMedium),
                ElevatedButton(
                  onPressed: _fetchProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    'Retry',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: [
              _buildProfileHeader(),
              _buildProfileDetails(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}