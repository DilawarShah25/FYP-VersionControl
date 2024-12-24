import 'package:flutter/material.dart';

class ScreensManager extends StatefulWidget {

  @override
  State<ScreensManager> createState() => _ScreensManagerState();
}

class _ScreensManagerState extends State<ScreensManager> {

  final List<Widget> _pages = [
    const HomeView(),
    const ProfileView(),
  ];

  void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
  }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        0,
      ),
      items: [
        const PopupMenuItem(
          value: 'Set Up Notification',
        ),
        const PopupMenuItem(
        ),
        const PopupMenuItem(
          value: 'FAQ',
        ),
        const PopupMenuItem(
          value: 'LOGOUT',
        ),
      ],
    ).then((value) {
      if (value == 'LOGOUT') {
      } else if (value == 'FAQ') {
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
      ),
              icon: Icon(
                Icons.person,
              ),
            ),
              icon: Icon(
              ),
            ),
              icon: Icon(
                Icons.menu,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
