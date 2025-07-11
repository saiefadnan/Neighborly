import 'package:flutter/material.dart';

class LShapePainter extends CustomPainter {
  final double verticalHeight;
  final double horizontalLength;
  final Color color;

  LShapePainter({
    required this.verticalHeight,
    required this.horizontalLength,
    this.color = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2;

    // Vertical line
    canvas.drawLine(Offset(0, 0), Offset(0, verticalHeight), paint);

    // Horizontal line
    canvas.drawLine(
      Offset(0, verticalHeight),
      Offset(horizontalLength, verticalHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
