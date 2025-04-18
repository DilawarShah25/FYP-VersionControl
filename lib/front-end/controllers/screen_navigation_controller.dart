import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Community/view/community_feed_screen.dart';
import '../utils/app_theme.dart';
import '../views/dashboard/other_dashboard/blog/blog_view.dart';
import '../views/dashboard/other_dashboard/faq/faq_view.dart';
import '../views/dashboard/other_dashboard/home_view.dart';
import '../views/dashboard/other_dashboard/profile_view.dart';

enum MoreMenuOption { notifications, blog, faq }

class ScreensManager extends StatefulWidget {
  const ScreensManager({super.key});

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeView(),
    ProfileView(),
    CommunityFeedScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _showMoreMenu(context);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showMoreMenu(BuildContext context) async {
    final menuOption = await showMenu<MoreMenuOption>(
      context: context,
      color: Colors.white,
      position: _calculateMenuPosition(context),
      items: [
        _buildMenuItem(MoreMenuOption.notifications, Icons.notifications, 'Set Up\nNotification'),
        _buildMenuItem(MoreMenuOption.blog, Icons.article, 'Blog'),
        _buildMenuItem(MoreMenuOption.faq, Icons.help_outline, 'FAQ'),
      ],
    );

    _handleMenuSelection(menuOption, context);
  }

  RelativeRect _calculateMenuPosition(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final button = context.findRenderObject() as RenderBox?;

    if (overlay == null || button == null) {
      debugPrint('Error: Overlay or button render object not found');
      return const RelativeRect.fromLTRB(0, 0, 0, 0);
    }

    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      overlay.size.width - 100,
      overlay.size.height - 100,
      0,
      0,
    );
  }

  PopupMenuItem<MoreMenuOption> _buildMenuItem(MoreMenuOption value, IconData icon, String text) {
    return PopupMenuItem<MoreMenuOption>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(MoreMenuOption? option, BuildContext context) {
    switch (option) {
      case MoreMenuOption.blog:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogView()));
        break;
      case MoreMenuOption.faq:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqView()));
        break;
      case MoreMenuOption.notifications:
      // TODO: Implement notification setup
        break;
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex == 0) return null;
    return PreferredSize(
      preferredSize: const Size.fromHeight(0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004e92), Color(0xFF000428)],
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
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.person, 'Profile', 1),
          _buildNavItem(Icons.group, 'Community', 2),
          _buildNavItem(Icons.menu, 'More', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: _selectedIndex == index ? 30 : 25,
        color: _selectedIndex == index ? AppTheme.primaryColor : Colors.grey,
      ),
      label: label,
    );
  }
}