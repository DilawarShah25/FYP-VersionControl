import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Community/view/community_feed_screen.dart';
import '../utils/app_theme.dart';
import '../views/authentication/login_view.dart';
import '../views/dashboard/blog/blog_view.dart';
import '../views/dashboard/faq/faq_view.dart';
import '../views/dashboard/home_view.dart';
import '../views/dashboard/profile_view.dart';
import '../controllers/session_controller.dart';

enum MoreMenuOption { notifications, blog, faq, logout }

class ScreensManager extends StatefulWidget {
  const ScreensManager({super.key});

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _sessionController = SessionController();
  String? _errorMessage;

  static const List<Widget> _pages = [
    HomeView(),
    ProfileView(),
    CommunityFeedScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Trigger the fade-in animation for the initial screen (HomeView)
    _animationController.forward();
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _showMoreMenu(context);
    } else {
      setState(() {
        _selectedIndex = index;
        _animationController.forward(from: 0);
      });
    }
  }

  void _showMoreMenu(BuildContext context) async {
    final menuOption = await showMenu<MoreMenuOption>(
      context: context,
      position: _calculateMenuPosition(context),
      items: [
        _buildMenuItem(MoreMenuOption.notifications, Icons.notifications, 'Notifications', 'View Notifications'),
        _buildMenuItem(MoreMenuOption.blog, Icons.article, 'Blog', 'View Blog'),
        _buildMenuItem(MoreMenuOption.faq, Icons.help_outline, 'FAQ', 'View FAQ'),
        _buildMenuItem(MoreMenuOption.logout, Icons.logout, 'Logout', 'Log Out'),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    );

    _handleMenuSelection(menuOption, context);
  }

  RelativeRect _calculateMenuPosition(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final button = context.findRenderObject() as RenderBox?;

    if (overlay == null || button == null) {
      setState(() {
        _errorMessage = 'Unable to position menu';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to position menu'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      // Fallback to bottom-right corner
      return const RelativeRect.fromLTRB(double.infinity, double.infinity, 16, 16);
    }

    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    final screenWidth = overlay.size.width;
    final screenHeight = overlay.size.height;
    const menuWidth = 150.0;
    const menuHeight = 200.0;

    // Position menu above the button, adjusting for screen boundaries
    double left = position.dx - menuWidth + button.size.width;
    double top = position.dy - menuHeight - 10;

    // Ensure menu stays within screen bounds
    left = left < 16 ? 16 : left;
    top = top < 16 ? position.dy + button.size.height + 10 : top;

    return RelativeRect.fromLTRB(
      left,
      top,
      screenWidth - left - menuWidth,
      screenHeight - top - menuHeight,
    );
  }

  PopupMenuItem<MoreMenuOption> _buildMenuItem(
      MoreMenuOption value, IconData icon, String text, String semanticLabel) {
    return PopupMenuItem<MoreMenuOption>(
      value: value,
      child: Semantics(
        label: semanticLabel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6D00), size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(MoreMenuOption? option, BuildContext context) async {
    if (option == null) return;

    switch (option) {
      case MoreMenuOption.notifications:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications feature coming soon'),
            backgroundColor: Color(0xFFFF6D00),
          ),
        );
        break;
      case MoreMenuOption.blog:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogView()));
        break;
      case MoreMenuOption.faq:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqView()));
        break;
      case MoreMenuOption.logout:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout', style: TextStyle(color: Color(0xFFD32F2F))),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            await FirebaseAuth.instance.signOut();
            _sessionController.clearSession();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: Color(0xFFFF6D00),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
            );
          } catch (e) {
            setState(() {
              _errorMessage = 'Error logging out: $e';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error logging out: $e'),
                backgroundColor: const Color(0xFFD32F2F),
              ),
            );
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildBackground(),
            Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFD32F2F),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _pages,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E0), Color(0xFFFFF3F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        unselectedItemColor: const Color(0xFF757575),
        selectedItemColor: const Color(0xFFFF6D00),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: [
          _buildNavItem(Icons.home, 'Home', 0, 'Home Screen'),
          _buildNavItem(Icons.person, 'Profile', 1, 'Profile Screen'),
          _buildNavItem(Icons.group, 'Community', 2, 'Community Feed'),
          _buildNavItem(Icons.menu, 'Menu', 3, 'More Options'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index, String semanticLabel) {
    return BottomNavigationBarItem(
      icon: Semantics(
        label: semanticLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Icon(
            icon,
            size: _selectedIndex == index ? 28 : 24,
            color: _selectedIndex == index ? const Color(0xFFFF6D00) : const Color(0xFF757575),
          ),
        ),
      ),
      label: label,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}