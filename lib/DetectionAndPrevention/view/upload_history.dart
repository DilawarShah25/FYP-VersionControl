import 'dart:math';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Upload History title',
            child: Center(
              child: Text(
                'Upload History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              // Circular Graph
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Reduced graph size
                    double size = constraints.maxWidth * 0.9; // Smaller size (50% of available width)
                    return Semantics(
                      label: 'Upload history circular graph showing total, healthy, and issues',
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
                          Text(
                            totalUploads.toString(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 24.0, // Reduced font size to match smaller graph
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              // Legends
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
                          'Healthy: ${_calculatePercentage(withoutProblems)}%',
                        ),
                        const SizedBox(height: 8.0),
                        _buildLegendDot(
                          context,
                          Colors.red,
                          'Issues: ${_calculatePercentage(diagnosedProblems)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculatePercentage(int value) {
    if (totalUploads == 0) return '0.0';
    return (value / totalUploads * 100).toStringAsFixed(1);
  }

  Widget _buildLegendDot(BuildContext context, Color color, String text) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );
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
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
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
      ..strokeWidth = 10.0; // Slightly reduced stroke width for smaller graph

    final double radius = size.width / 2 - paint.strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -pi / 2;

    // Background Circle
    paint.color = const Color(0x33CCCCCC);
    canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);

    // Healthy Arc
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

    // Issues Arc
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