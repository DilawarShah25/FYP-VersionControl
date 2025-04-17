import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Community/view/community_feed_screen.dart';
import '../utils/app_theme.dart';
import '../views/authentication/login_view.dart';
import '../views/dashboard/other_dashboard/blog/blog_view.dart';
import '../views/dashboard/other_dashboard/faq/faq_view.dart';
import '../views/dashboard/other_dashboard/home_view.dart';
import '../views/dashboard/other_dashboard/profile_view.dart';

class ScreensManager extends StatefulWidget {
  const ScreensManager({Key? key}) : super(key: key);

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const ProfileView(),
    const CommunityFeedScreen(),
  ];

  void _onItemTapped(int index) {
    if (index != 3) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      _showPopupMenu(context);
    }
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (overlay == null || button == null) {
      debugPrint('Error: Overlay or button not found for popup menu');
      return;
    }
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        overlay.size.width - 100,
        overlay.size.height - 100,
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
        FirebaseAuth.instance.signOut().then((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
          );
        }).catchError((e) {
          debugPrint('Logout error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to logout: $e')),
          );
        });
      } else if (value == 'BLOG') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogView()));
      } else if (value == 'FAQ') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqView()));
      }
    });
  }

  Widget _buildPopupMenuItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF004e92),
              Color(0xFF000428),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
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
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: _selectedIndex == 0 ? 30 : 25,
                color: _selectedIndex == 0 ? AppTheme.primaryColor : Colors.grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: _selectedIndex == 1 ? 30 : 25,
                color: _selectedIndex == 1 ? AppTheme.primaryColor : Colors.grey,
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.chat,
                size: _selectedIndex == 2 ? 30 : 25,
                color: _selectedIndex == 2 ? AppTheme.primaryColor : Colors.grey,
              ),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.menu,
                size: _selectedIndex == 3 ? 30 : 25,
                color: _selectedIndex == 3 ? AppTheme.primaryColor : Colors.grey,
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}