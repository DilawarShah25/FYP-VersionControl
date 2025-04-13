import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class UploadHistory extends StatelessWidget {
  final int totalUploads;
  final int withoutProblems;
  final int diagnosedProblems;

  const UploadHistory({
    super.key,
    required this.totalUploads,
    required this.withoutProblems,
    required this.diagnosedProblems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          children: [
            // Circular Graph
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double size = min(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
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
                      Text(
                        totalUploads.toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: AppTheme.paddingMedium),
            // Legends
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(context, Colors.grey, 'Uploads: $totalUploads'),
                  const SizedBox(height: AppTheme.paddingSmall),
                  _buildLegendDot(context, AppTheme.primaryColor, 'Healthy: $withoutProblems'),
                  const SizedBox(height: AppTheme.paddingSmall),
                  _buildLegendDot(context, AppTheme.errorColor, 'Issues: $diagnosedProblems'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(BuildContext context, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.paddingSmall),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
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
      ..strokeWidth = 12.0;

    final double radius = size.width / 2 - paint.strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -pi / 2;

    // Background Circle
    paint.color = AppTheme.accentColor;
    canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);

    // Without Problems Arc
    if (total > 0) {
      paint.color = AppTheme.primaryColor;
      final sweepAngle = (withoutProblems / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Diagnosed Problems Arc
    if (total > 0) {
      paint.color = AppTheme.errorColor;
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