import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/app_theme.dart';

class CircularGraphPainter extends CustomPainter {
  final double confidence;

  CircularGraphPainter({required this.confidence});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final double radius = min(size.width / 2, size.height / 2) - 7;

    // Draw red portion
    circlePaint.color = AppTheme.errorColor;
    final double redAngle = (1 - confidence) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2,
      redAngle,
      false,
      circlePaint,
    );

    // Draw green portion
    circlePaint.color = AppTheme.secondaryColor;
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
  bool shouldRepaint(covariant CircularGraphPainter oldDelegate) {
    return oldDelegate.confidence != confidence;
  }
}