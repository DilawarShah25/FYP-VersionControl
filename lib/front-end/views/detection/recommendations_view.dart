import 'package:flutter/material.dart';

import '../app_theme.dart';

class RecommendationsView extends StatelessWidget {
  const RecommendationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Hair Health Tips',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Expanded(
              child: ListView(
                children: const [
                  _RecommendationTile(
                    icon: Icons.medical_services,
                    title: 'Visit a Dermatologist',
                    subtitle: 'For advanced care and professional diagnosis.',
                  ),
                  _RecommendationTile(
                    icon: Icons.nature_people,
                    title: 'Herbal Remedies',
                    subtitle: 'Try natural solutions to promote hair growth.',
                  ),
                  _RecommendationTile(
                    icon: Icons.bathtub,
                    title: 'Gentle Hair Care',
                    subtitle: 'Use sulfate-free shampoos to protect your scalp.',
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

class _RecommendationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecommendationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}