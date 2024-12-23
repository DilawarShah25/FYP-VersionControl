import 'package:flutter/material.dart';

class ImageUploadView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image', style: TextStyle(fontSize: 20.0)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle image selection logic
              },
              child: Text('Select Image from Gallery', style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,  // Button color
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Or Capture Image',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle image capture logic
              },
              child: Text('Capture Image', style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,  // Button color
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
