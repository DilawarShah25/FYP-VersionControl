import 'package:flutter/material.dart';

class PerformanceDetailsView extends StatelessWidget {
  const PerformanceDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color of the Scaffold to white
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Padding for all contents
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              height: 100,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20), // Rounded corners for the header
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Our test can help you detect hair fall early.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Image.asset(
                      'lib/front-end/assets/images/scanner.png',
                      width: 60,
                      height: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white, // Set the background color of the content section to white
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Early detection of hair fall is crucial for effective treatment. Learn more about our innovative solution.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20), // Added spacing between text and button
                  // Use `Center` to align the button in the center and wrap it with `Expanded` if necessary
                  Center(
                    child: SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Padding to give the button enough space
                        child: ElevatedButton(
                          onPressed: () {
                            // Implement your "Read More" functionality here
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), // Adjust button padding
                          ),
                          child: const Text('Read more'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
