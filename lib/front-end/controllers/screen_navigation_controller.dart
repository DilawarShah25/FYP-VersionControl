import 'package:flutter/material.dart';
import '../views/dashboard/other_dashboard/blog/blog_view.dart';
import '../views/dashboard/community_support_view/community_support_view.dart';
import '../views/dashboard/other_dashboard/faq/faq_view.dart';
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
    if (index != 3) {
      // Change index if not the "More" item
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // Show popup menu for the "More" item
      _showPopupMenu(context);
    }
  }

  // Show custom popup menu
  void _showPopupMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 100, // Adjust this value to position the menu correctly
        overlay.size.height - 100, // Adjust this value to position the menu correctly
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'Set Up Notification',
          child: _buildPopupMenuItem(Icons.notifications, 'Set Up\nNotification'),
        ),
        PopupMenuItem(
          value: 'BLOG',
          child: _buildPopupMenuItem(Icons.article, 'Blog'),
        ),
        PopupMenuItem(
          value: 'FAQ',
          child: _buildPopupMenuItem(Icons.help_outline, 'FAQ'),
        ),
        PopupMenuItem(
          value: 'LOGOUT',
          child: _buildPopupMenuItem(Icons.logout, 'Logout'),
        ),
      ],
    ).then((value) {
      if (value == 'LOGOUT') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RoleSelectionView()));
      } else if (value == 'BLOG') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogView()));
      } else if (value == 'FAQ') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqView())); // Replace with FAQView
      }
    });
  }

  // Build individual popup menu item with icon and text
  Widget _buildPopupMenuItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? null // Don't show AppBar for HomeView
          : PreferredSize(
        preferredSize: const Size.fromHeight(0.0), // height of the AppBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF004e92),
                  Color(0xFF000428),
                ],
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
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
          backgroundColor: Colors.transparent,
          elevation: 0,
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
