import 'package:flutter/material.dart';
import 'dart:math';

class CircularGraphPainter extends CustomPainter {
  final double confidence;

  CircularGraphPainter({required this.confidence});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    // final double radius = min(size.width / 2, size.height / 2); // Adjusted from 14 to 5
    const double radius = 70; // Adjusted from 14 to 5

    // Draw red portion
    circlePaint.color = Colors.red;
    final double redAngle = (1 - confidence) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2,
      redAngle,
      false,
      circlePaint,
    );

    // Draw green portion
    circlePaint.color = Colors.green;
    final double greenAngle = confidence * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2 + redAngle,
      greenAngle,
      false,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}