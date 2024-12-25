import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File support

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Controllers for the editable fields
  final TextEditingController _usernameController = TextEditingController(text: 'JohnDoe');
  final TextEditingController _emailController = TextEditingController(text: 'johndoe@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+1234567890');

  // State to manage profile picture
  File? _profileImage;

  // State to manage whether the profile is in edit mode
  bool _isEditing = false;

  // Method to pick a new image from camera or gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Show a dialog to let the user choose between camera or gallery
    final pickedOption = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        actions: <Widget>[
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

    if (pickedOption != null) {
      // Pick image based on the user's choice (camera or gallery)
      final XFile? pickedFile = await picker.pickImage(source: pickedOption);

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    }
  }

  // Method to save the updated profile details
  void _saveProfile() {
    final String updatedUsername = _usernameController.text;
    final String updatedEmail = _emailController.text;
    final String updatedPhone = _phoneController.text;

    // Handle saving logic here, like updating a backend or database

    // Show a styled confirmation snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Profile updated successfully!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
        elevation: 10,
      ),
    );
  }

  // Method to toggle between edit and static view
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // height of the AppBar
        child: Stack(
          children: [
            // AppBar with gradient extending outside the SafeArea
            Container(
              height: 70.0,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF004e92),
                    Color(0xFF000428),
                  ],
                ),
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Padding(
                padding: EdgeInsets.only(right: 50.0, top: 12.0),
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 36,
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004e92),
                Color(0xFF000428),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profile Image and editable fields go here
                        GestureDetector(
                          onTap: _pickImage, // Allow user to tap to change the image
                          child: CircleAvatar(
                            radius: 80,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const NetworkImage('') as ImageProvider,
                            backgroundColor: Colors.blueGrey.shade100,
                            child: _profileImage == null
                                ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Editable Username with modern text field styling
                        TextField(
                          controller: _usernameController,
                          enabled: _isEditing, // Enable or disable field based on _isEditing
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 20),

                        // Editable Email with modern text field styling
                        TextField(
                          controller: _emailController,
                          enabled: _isEditing, // Enable or disable field based on _isEditing
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 20),

                        // Editable Phone Number with optional country code
                        TextField(
                          controller: _phoneController,
                          enabled: _isEditing, // Enable or disable field based on _isEditing
                          decoration: InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 30),

                        // Edit/Save Button with dynamic colors
                        ElevatedButton(
                          onPressed: _isEditing ? _saveProfile : _toggleEditMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing ? Colors.green : Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: _isEditing
                                ? Colors.green.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                          ),
                          child: Text(
                            _isEditing ? 'Save' : 'Edit Profile',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
