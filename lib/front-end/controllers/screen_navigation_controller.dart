import 'package:flutter/material.dart';
import '../views/dashboard/profile_view.dart'; // Correct import if profile_screen.dart is in the 'screens' folder
import '../views/dashboard/home_view.dart';
import '../views/authentication/role_selection_view.dart';
import '../views/dashboard/blog_view.dart';
// import '../views/dashboard/timer_view.dart'; // Add this import for TimerView

class ScreensManager extends StatefulWidget {
  const ScreensManager({super.key});

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {
  int _selectedIndex = 0; // Track the selected tab index

  // List of pages/screens for each tab
  final List<Widget> _pages = [
    const HomeView(),
    const ProfileView(),
    // const TimerView(), // Add TimerView to handle the Timer tab
  ];

  // Handle tab item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Show custom popup menu
  void _showPopupMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dy - 10, // Ensure alignment with the right-most edge
        0,
      ),
      items: [
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
        const PopupMenuItem(
          value: 'LOGOUT',
          child: Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
      elevation: 8.0,
      color: Colors.black,
    ).then((value) {
      if (value == 'LOGOUT') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RoleSelectionView()),
        );
      } else if (value == 'FAQ') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FaqView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _selectedIndex < _pages.length
            ? _pages[_selectedIndex] // Display the selected page
            : const Center(child: Text('Page not found')), // Fallback if index is invalid
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Profile tab
              IconButton(
                onPressed: () => _onItemTapped(1),
                icon: Icon(
                  Icons.person,
                  size: 30,
                  color: _selectedIndex == 1 ? Colors.green : Colors.blue,
                ),
                tooltip: 'Profile',
              ),
              // Home tab
              IconButton(
                onPressed: () => _onItemTapped(0),
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: _selectedIndex == 0 ? Colors.green : Colors.blue,
                ),
                tooltip: 'Home',
              ),
              // Timer tab
              IconButton(
                onPressed: () => _onItemTapped(2),
                icon: Icon(
                  Icons.timer,
                  size: 30,
                  color: _selectedIndex == 2 ? Colors.green : Colors.blue,
                ),
                tooltip: 'Home',
              ),
              // Popup Menu
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  _showPopupMenu(context, details.globalPosition);
                },
                child: Icon(
                  Icons.menu,
                  size: 30,
                  color: _selectedIndex == 3 ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
