import 'package:flutter/material.dart';
import '../views/authentication/admin_login_view.dart';
import '../views/authentication/user_login_view.dart';

class RoleSelectionView extends StatefulWidget {
  @override
  _RoleSelectionViewState createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  String _selectedRole = '';

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
    if (role == 'Admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginView()),
      );
    } else if (role == 'User') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserLoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Role',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5.0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B42F6), Color(0xFFB55DF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Who Are You?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              RoleCard(
                role: 'Admin',
                isSelected: _selectedRole == 'Admin',
                onTap: () => _selectRole('Admin'),
                icon: Icons.admin_panel_settings,
              ),
              const SizedBox(height: 20),
              RoleCard(
                role: 'User',
                isSelected: _selectedRole == 'User',
                onTap: () => _selectRole('User'),
                icon: Icons.person,
              ),
              const SizedBox(height: 30),
              if (_selectedRole.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'You have selected: $_selectedRole',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
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

class RoleCard extends StatelessWidget {
  final String role;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const RoleCard({
    Key? key,
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected ? [Color(0xFF1E88E5), Color(0xFF6AB7FF)] : [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 15),
            Text(
              role,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


