import 'package:flutter/material.dart';

class UserManualView extends StatelessWidget {
  const UserManualView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Light background for better visibility
      body: SafeArea(
        child: Column(
          children: [
            // First Container with Title
            Container(
              height: 60.0,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
            ),

            // Second Container with Curved Top, Shadow, and ScrollView
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Guideline Sections
                      for (int i = 1; i <= 10; i++)
                        GuidelineSection(number: i),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuidelineSection extends StatelessWidget {
  final int number;

  const GuidelineSection({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. Guideline Title $number:',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'This is the description for guideline $number. Please follow these instructions carefully.',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

