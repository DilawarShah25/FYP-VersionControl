import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ProfileViewState extends State<ProfileView> {
  final _service = CommunityFirebaseService();
  final _sessionController = SessionController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _username, _imageBase64, _role, _errorMessage;
  bool _isLoading = true, _isOwnProfile = false, _isEditing = false;
  ProfileData? _profile;

  @override
  void initState() {
    super.initState();
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
        _username = profile.username ?? widget.userName ?? 'Unknown';
        _emailController.text = profile.showEmail || _isOwnProfile ? profile.email : 'Restricted';
        _phoneController.text = (profile.showPhone || _isOwnProfile) && profile.phoneNumberPart.isNotEmpty
            ? '${profile.phoneCountryCode}${profile.phoneNumberPart}'
            : 'Restricted';
        _imageBase64 = profile.imageBase64;
        _role = profile.role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_isOwnProfile || !_isEditing) return;
    setState(() => _isLoading = true);
    try {
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
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error saving: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _sessionController.clearSession();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error logging out: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e', style: GoogleFonts.poppins())),
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
      labelStyle: GoogleFonts.poppins(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      filled: true,
      fillColor: Colors.grey[200],
      prefixText: label == 'Username' ? '' : null,
    );
  }

  InputDecoration _editableDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppTheme.primaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      filled: true,
      fillColor: AppTheme.accentColor.withOpacity(0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isOwnProfile) ...[
              IconButton(
                icon: Icon(_isEditing ? Icons.cancel : Icons.edit, color: AppTheme.white),
                tooltip: _isEditing ? 'Cancel' : 'Edit',
                onPressed: _toggleEdit,
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppTheme.white),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
            ],
            if (!_isOwnProfile)
              IconButton(
                icon: const Icon(Icons.message, color: AppTheme.white),
                tooltip: 'Send Message',
                onPressed: _navigateToChat,
              ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: GoogleFonts.poppins(color: AppTheme.errorColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry', style: GoogleFonts.poppins(color: AppTheme.white)),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTheme.paddingMedium),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.accentColor,
                  backgroundImage: _imageBase64 != null ? MemoryImage(base64Decode(_imageBase64!)) : null,
                  child: _imageBase64 == null
                      ? Text(
                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(fontSize: 40, color: AppTheme.primaryColor),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                _nameController.text,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextField(
                controller: TextEditingController(text: _username),
                decoration: _readOnlyDecoration('Username'),
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                readOnly: true,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextField(
                controller: _nameController,
                decoration: _editableDecoration('Full Name'),
                style: GoogleFonts.poppins(fontSize: 16),
                readOnly: !_isOwnProfile || !_isEditing,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextField(
                controller: _emailController,
                decoration: _editableDecoration('Email'),
                style: GoogleFonts.poppins(fontSize: 16),
                readOnly: !_isOwnProfile || !_isEditing,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextField(
                controller: _phoneController,
                decoration: _editableDecoration('Phone'),
                style: GoogleFonts.poppins(fontSize: 16),
                readOnly: !_isOwnProfile || !_isEditing,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              TextField(
                controller: TextEditingController(text: _role),
                decoration: _readOnlyDecoration('Role'),
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                readOnly: true,
              ),
              if (_isOwnProfile && _isEditing) ...[
                const SizedBox(height: AppTheme.paddingLarge),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.white),
                  ),
                ),
              ],
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
    super.dispose();
  }
}