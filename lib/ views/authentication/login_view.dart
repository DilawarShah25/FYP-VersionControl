import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(fontSize: 20.0)),
        backgroundColor: Colors.blue,  // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),  // Padding around the form
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(fontSize: 16.0),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,  // To hide password
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(fontSize: 16.0),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle login logic
              },
              child: Text('Login', style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,  // Button color
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
