import 'package:flutter/material.dart';

/// A premium separator that looks like the lower half of a rounded rectangle,
/// joining two habits with a modern bracket aesthetic.
class HabitSeparator extends StatelessWidget {
  const HabitSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: SizedBox(
        width: double.infinity,
        height:
            8, // Necessary height to give CustomPaint space to draw the shape!
        child: CustomPaint(
          painter: _BracketPainter(
            color: const Color(
              0xFFD1D1D6,
            ).withValues(alpha: 0.8), // Soft visible gray
            strokeWidth: 2.0,
          ),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _BracketPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double w = size.width;
    // Fallback height in case size.height is 0
    final double h = size.height > 0 ? size.height : 12.0;

    // The "lower part of a rounded rectangle" connecting the full width of the cards
    // Modern card corner radius. We clamp it to the height so it scales perfectly
    // without breaking if the parent shrinks the height.
    final double rawCr = 16.0;
    final double cr = rawCr > h ? h : rawCr;

    // Spans the full width
    final double startX = 0;
    final double endX = w;

    // Start at top-left of the lower part
    path.moveTo(startX, 0);

    // Vertical drop down on the left
    path.lineTo(startX, h - cr);

    // Rounded bottom-left corner curving right
    path.quadraticBezierTo(startX, h, startX + cr, h);

    // The 'straight' horizontal line in the middle
    path.lineTo(endX - cr, h);

    // Rounded bottom-right corner curving up
    path.quadraticBezierTo(endX, h, endX, h - cr);

    // Vertical rise up to top-right of the lower part
    path.lineTo(endX, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
