import 'package:flutter/material.dart';
import 'admin_login_view.dart';
import 'user_login_view.dart';  // Import the Login Screen
// import 'admin_login_view.dart'; // Import the Signup Screen

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
        MaterialPageRoute(builder: (context) => AdminLoginView()),
      );
    } else if (role == 'User') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserLoginView()),
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
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5.0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
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
                Text(
                  'You have selected: $_selectedRole',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
          color: isSelected ? Colors.white : Colors.deepPurple[400],
          borderRadius: BorderRadius.circular(12.0),
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
              color: isSelected ? Colors.deepPurple : Colors.white,
              size: 30,
            ),
            const SizedBox(width: 15),
            Text(
              role,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

