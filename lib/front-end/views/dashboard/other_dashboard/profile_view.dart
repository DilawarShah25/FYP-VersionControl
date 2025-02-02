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
  final TextEditingController _usernameController =
  TextEditingController(text: '');
  final TextEditingController _bioController = TextEditingController(
      text: '');
  // State to manage profile picture
  File? _profileImage;

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
    final String updatedBio = _bioController.text;

    // Handle saving logic here, like updating a backend or database

    // Show a confirmation snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue, // Set background color here
        child: SafeArea(
          child: Column(
            children: [
              // First Container with Title
              Container(
                height: 80.0,
                width: double.infinity,
                alignment: Alignment.center, // Centers the child within the container
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20, // Optional: adjust the font size if needed
                  ),
                ),
              ),

              // Second Container with Curved Top, Shadow, and ScrollView
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
                  child: SingleChildScrollView( // Enable scrolling if the content overflows
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
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.blueAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.blueAccent),
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

                        // Editable Bio with modern text field styling
                        TextField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            labelStyle: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.blueAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.blueAccent),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 30),

                        // Save Profile Button with improved design
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: Colors.blueAccent.withOpacity(0.3),
                          ),
                          child: const Text('Save Profile',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(height: 20),
                        // Settings Button
                        TextButton(
                          onPressed: () {
                            // Navigate to Settings or perform logout
                          },
                          child: const Text(
                            'Settings',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
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
