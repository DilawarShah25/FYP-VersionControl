import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

class DiagnoseHistoryScreen extends StatelessWidget {
  final String userId;

  const DiagnoseHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis History', style: TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: firestoreService.getUploadHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTheme.theme.textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
              ),
            );
          }

          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return const Center(
              child: Text('No diagnosis history available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final imageBase64 = item['image_base64'] as String?;
              final diagnosis = item['diagnosis'] as String? ?? 'Unknown';
              final timestamp = item['timestamp'] as Timestamp?;
              final date = timestamp?.toDate().toString() ?? 'Unknown date';

              Widget imageWidget;
              if (imageBase64 != null && imageBase64.isNotEmpty) {
                try {
                  final imageBytes = base64Decode(imageBase64);
                  imageWidget = Image.memory(
                    imageBytes,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 100,
                    ),
                  );
                } catch (e) {
                  imageWidget = const Icon(Icons.broken_image, size: 100);
                }
              } else {
                imageWidget = const Icon(Icons.image_not_supported, size: 100);
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingMedium),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Diagnosis image',
                        child: imageWidget,
                      ),
                      const SizedBox(width: AppTheme.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: 'Diagnosis: $diagnosis',
                              child: Text(
                                'Diagnosis: $diagnosis',
                                style: AppTheme.theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Semantics(
                              label: 'Date: $date',
                              child: Text(
                                'Date: $date',
                                style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary.withOpacity(0.7),
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
            },
          );
        },
      ),
    );
  }
}