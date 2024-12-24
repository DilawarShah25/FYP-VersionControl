import 'package:flutter/material.dart';
import '../views/dashboard/other_dashboard/blog_view.dart';
import '../views/dashboard/community_support_view/community_support_view.dart';
import '../views/dashboard/other_dashboard/profile_view.dart';
import '../views/dashboard/other_dashboard/home_view.dart';
import 'role_controller.dart';

class ScreensManager extends StatefulWidget {
  const ScreensManager({Key? key}) : super(key: key);

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {
  int _selectedIndex = 0;

  // Pages for each tab
  final List<Widget> _pages = [
    const HomeView(),
    const ProfileView(),
    const CommunitySupportView(),
  ];

  // Handle tab selection
  void _onItemTapped(int index) {
    if (index != 3) { // Only change the index if it's not the "More" item
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Show the popup menu for the "More" item
      _showPopupMenu(context);
    }
  }

  // Show popup menu
  void _showPopupMenu(BuildContext context) {
    // Get the position of the "More" icon
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 100, // Adjust this value to position the menu correctly
        overlay.size.height - 100, // Adjust this value to position the menu correctly
        0,
        0,
      ),
      items: [
        const PopupMenuItem(
          value: 'Set Up Notification',
          child: Text('Set Up Notification'),
        ),
        const PopupMenuItem(
          value: 'BLOG',
          child: Text('Blog'),
        ),
        const PopupMenuItem(
          value: 'FAQ',
          child: Text('FAQ'),
        ),
        const PopupMenuItem(
          value: 'LOGOUT',
          child: Text('Logout'),
        ),
      ],
    ).then((value) {
      if (value == 'LOGOUT') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RoleSelectionView()));
      } else if (value == 'BLOG') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqView()));
      } else if (value == 'FAQ') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqView())); // Replace with FAQView
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background for better visibility
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10), // Adjust margins to reduce size
        decoration: BoxDecoration(
          color: Colors.white, // Decent background color for the bottom bar
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent, // Make the background transparent for the navigation bar
          elevation: 0, // Remove default elevation
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: _selectedIndex == 0 ? 30 : 25,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: _selectedIndex == 1 ? 30 : 25,
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.groups,
                size: _selectedIndex == 2 ? 30 : 25,
              ),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.menu,
                size: _selectedIndex == 3 ? 30 : 25,
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
