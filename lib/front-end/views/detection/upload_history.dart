import 'dart:math';
import 'package:flutter/material.dart';

class UploadHistory extends StatelessWidget {
  final int totalUploads;
  final int withoutProblems;
  final int diagnosedProblems;

  const UploadHistory({
    Key? key,
    required this.totalUploads,
    required this.withoutProblems,
    required this.diagnosedProblems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Container
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          // Legends
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.grey, 'Photos uploaded: $totalUploads'),
              const SizedBox(height: 8),
              _buildLegendDot(Colors.blue, 'Without problems: $withoutProblems'),
              const SizedBox(height: 8),
              _buildLegendDot(Colors.red, 'Diagnosed problems: $diagnosedProblems'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
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
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black),
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
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double startAngle = -pi / 2;

    // Draw Total (Gray Circle)
    paint.color = Colors.grey;
    canvas.drawCircle(center, radius, paint);

    // Draw Without Problems (Blue Arc)
    if (total > 0) {
      paint.color = Colors.blue;
      final double sweepAngle = (withoutProblems / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw Diagnosed Problems (Red Arc)
    if (total > 0) {
      paint.color = Colors.red;
      final double sweepAngle = (diagnosedProblems / total) * 2 * pi;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
