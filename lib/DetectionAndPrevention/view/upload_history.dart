import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scalpsense/views/authentication/login_view.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../../main.dart'; // Import main.dart for SignInScreen

class UploadHistory extends StatelessWidget {
  final String userId;

  const UploadHistory({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Theme(
      data: AppTheme.theme,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<Map<String, int>>(
          stream: firestoreService.streamUploadHistoryCounts(userId),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: AppTheme.theme.textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginView()),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              );
            }

            final counts = snapshot.data ?? {
              'totalUploads': 0,
              'withoutProblems': 0,
              'diagnosedProblems': 0,
            };
            final totalUploads = counts['totalUploads']!;
            final withoutProblems = counts['withoutProblems']!;
            final diagnosedProblems = counts['diagnosedProblems']!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Upload History title',
                  child: Center(
                    child: Text(
                      'Upload History',
                      style: AppTheme.theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.maxWidth * 0.9 > 100 ? constraints.maxWidth * 0.9 : 100.0;
                          return Semantics(
                            label:
                            'Upload history circular graph showing total $totalUploads, healthy $withoutProblems, and issues $diagnosedProblems',
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size(size, size),
                                  painter: CircularGraphPainter(
                                    total: totalUploads,
                                    withoutProblems: withoutProblems,
                                    diagnosedProblems: diagnosedProblems,
                                  ),
                                ),
                                Semantics(
                                  label: 'Total uploads: $totalUploads',
                                  child: Text(
                                    totalUploads.toString(),
                                    style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: Semantics(
                          label: 'Legend for upload history graph',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLegendDot(
                                context,
                                Colors.black87,
                                'Total: $totalUploads',
                              ),
                              const SizedBox(height: 8.0),
                              _buildLegendDot(
                                context,
                                Colors.green,
                                'Healthy: ${_calculatePercentage(withoutProblems, totalUploads)}%',
                              ),
                              const SizedBox(height: 8.0),
                              _buildLegendDot(
                                context,
                                Colors.red,
                                'Issues: ${_calculatePercentage(diagnosedProblems, totalUploads)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _calculatePercentage(int value, int total) {
    if (total == 0) return '0.0';
    return (value / total * 100).toStringAsFixed(1);
  }

  Widget _buildLegendDot(BuildContext context, Color color, String text) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        SemanticsService.announce(text, TextDirection.ltr);
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: const SizedBox(
                width: 12,
                height: 12,
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Semantics(
                label: text,
                child: Text(
                  text,
                  style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.0,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularGraphPainter extends CustomPainter {
  final int total;
  final int withoutProblems;
  final int diagnosedProblems;

  CircularGraphPainter({
    required this.total,
    required this.withoutProblems,
    required this.diagnosedProblems,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final double radius = size.width / 2 - paint.strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -pi / 2;

    paint.color = const Color(0x33CCCCCC);
    canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);

    if (total > 0) {
      paint.color = Colors.green;
      final sweepAngle = (withoutProblems / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    if (total > 0) {
      paint.color = Colors.red;
      final sweepAngle = (diagnosedProblems / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (withoutProblems / total) * 2 * pi,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularGraphPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.withoutProblems != withoutProblems ||
        oldDelegate.diagnosedProblems != diagnosedProblems;
  }
}