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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)], // Vibrant gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(0, 3),
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
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'You have selected: $_selectedRole',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [Color(0xFF3A7BD5), Color(0xFF00D2FF)] // Highlighted gradient
                : [Color(0xFF6FB1FC), Color(0xFF0052D4)], // Default gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.black26,
              blurRadius: 15.0,
              offset: const Offset(0, 6),
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
