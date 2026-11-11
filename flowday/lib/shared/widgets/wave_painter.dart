import 'package:flutter/material.dart';

/// Vagues décoratives de l'en-tête sombre (design de référence).
class WavePainter extends CustomPainter {
  const WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 9; i++) {
      final path = Path();
      final y = 15.0 + i * 13;

      path.moveTo(size.width * 0.25, y);

      path.cubicTo(
        size.width * 0.45,
        y - 65,
        size.width * 0.55,
        y + 80,
        size.width * 0.78,
        y + 5,
      );

      path.cubicTo(
        size.width * 0.9,
        y - 30,
        size.width * 0.9,
        y + 60,
        size.width,
        y + 15,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
