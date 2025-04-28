import 'package:flutter/material.dart';
import '../dashboard/other_dashboard/faq/detail_screen.dart'; // Import the DetailScreen class

class ProgressHistoryView extends StatelessWidget {
  const ProgressHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
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
                    'lib/assets/images/scanner.png',
                    width: 60,
                    height: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Content Section
          Text(
            'Early view of hair fall is crucial for effective treatment. Learn more about our innovative solution.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Implement your "Read More" functionality here to navigate to DetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const DetailScreen(
                        title: 'Early Detection of Hair Fall',
                        content: '''
# Early Detection of Hair Fall

Early view of hair fall is crucial for effective treatment. Scalp Sense offers an innovative solution that helps you identify the first signs of hair loss, enabling you to take action before the situation worsens.

## How It Helps:
- **Scalp Analysis**: The app detects signs of thinning and other early indicators of hair loss.
- **Personalized Treatment Plans**: Based on your condition, Scalp Sense provides early interventions to prevent further damage.
- **Proactive Care**: Catching hair fall early means you can start treatments sooner, reducing the impact.

## Conclusion
With Scalp Sense, early view of hair fall is within your reach. By addressing hair loss early, you can ensure healthier hair in the long run.
''',
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Read More',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
