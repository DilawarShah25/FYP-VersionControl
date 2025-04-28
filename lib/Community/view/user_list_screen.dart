import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_data.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ProfileData> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final users = await _firestoreService.getAllProfiles();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching users: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Users',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white),
          ),
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
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              ElevatedButton(
                onPressed: _fetchUsers,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: AppTheme.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        )
            : _users.isEmpty
            ? Center(
          child: Text(
            'No users found.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return ListTile(
              leading: user.imageBase64 != null
                  ? CircleAvatar(
                backgroundImage: MemoryImage(base64Decode(user.imageBase64!)),
              )
                  : CircleAvatar(
                child: Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(color: AppTheme.white),
                ),
                backgroundColor: AppTheme.primaryColor,
              ),
              title: Text(
                user.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username ?? '@${user.name.toLowerCase().replaceAll(' ', '')}',
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: user.id,
                      otherUserName: user.name,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}