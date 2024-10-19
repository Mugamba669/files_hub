import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  RipplePainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity(1 - animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double radius = (size.width / 2) * animationValue;

    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
