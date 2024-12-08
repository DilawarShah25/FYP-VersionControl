import 'package:flutter/material.dart';

class RecommendationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations', style: TextStyle(fontSize: 20.0)),
        backgroundColor: Colors.blue,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Personalized Recommendations for Your Hair Health',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Displaying recommendations (can be a list)
            ListTile(
              leading: Icon(Icons.medical_services),  // Icon for medical advice
              title: Text('Visit Dermatologist for Advanced Care', style: TextStyle(fontSize: 18.0)),
            ),
            ListTile(
              leading: Icon(Icons.nature_people),  // Icon for natural remedies
              title: Text('Try Herbal Remedies for Hair Growth', style: TextStyle(fontSize: 18.0)),
            ),
          ],
        ),
      ),
    );
  }
}
