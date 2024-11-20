import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'profile_screen.dart'; // Correct import if profile_screen.dart is in the 'screens' folder
import 'home_screen.dart';
import 'socialCircle/social.dart';

class ScreensManager extends StatefulWidget {
  const ScreensManager({super.key});

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0; // Track the selected tab index

  // List of pages/screens for each tab
  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfileScreen(),
    const SocialPage(),
  ];

  // Handle tab item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Show options to take a picture (camera/gallery)
  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.blue),
                title: const Text('Camera',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final XFile? image =
                  await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    print("Picked image from camera: ${image.path}");
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.blue),
                title: const Text('Gallery',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final XFile? image =
                  await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    print("Picked image from gallery: ${image.path}");
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Center(
      //     child: Text(
      //       'Revive Your Hair',
      //       style: TextStyle(
      //           color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 28),
      //     ),
      //   ),
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      // ),
      body: SafeArea(
        child: _pages[_selectedIndex], // Display the selected page
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home tab
              IconButton(
                onPressed: () => _onItemTapped(0),
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: _selectedIndex == 0 ? Colors.green : Colors.blue,
                ),
              ),
              // Profile tab
              IconButton(
                onPressed: () => _onItemTapped(1),
                icon: Icon(
                  Icons.person,
                  size: 30,
                  color: _selectedIndex == 1 ? Colors.green : Colors.blue,
                ),
              ),
              // Camera button in the center
              ElevatedButton(
                onPressed: _showCameraOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(18.0),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
              // Timer/Other tab
              IconButton(
                onPressed: () => _onItemTapped(2),
                icon: Icon(
                  Icons.timer,
                  size: 30,
                  color: _selectedIndex == 2 ? Colors.green : Colors.blue,
                ),
              ),
              // Popup Menu (optional)
              PopupMenuButton(
                color: Colors.black,
                icon: Icon(
                  Icons.menu,
                  size: 30,
                  color: _selectedIndex == 3 ? Colors.green : Colors.blue,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Set Up Notification',
                    child: Text(
                      'Set Up Notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Blog',
                    child: Text(
                      'Blog',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'FAQ',
                    child: Text(
                      'FAQ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'FAQ') _showCameraOptions();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

