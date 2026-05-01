// ════════════════════════════════════════════════════════════════════
// challenge_helpers.dart — Shared helpers for Brand Challenge screen
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Gradient accent bar + uppercase label used for section headers.
Widget buildSectionLabel(String text, double s) {
  return Row(
    children: [
      Container(
        width: 3 * s,
        height: 14 * s,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: 8 * s),
      Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11 * s,
          fontWeight: FontWeight.w900,
          color: AppTheme.onBackground,
          letterSpacing: 1.5,
        ),
      ),
    ],
  );
}

/// Frosted-glass circle button (back / share).
Widget navCircle(IconData icon, VoidCallback onTap, double s) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36 * s,
      height: 36 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.onBackground.withValues(alpha: 0.08),
      ),
      child: Icon(icon, size: 15 * s, color: AppTheme.onBackground),
    ),
  );
}

/// First 3 characters of a brand name, uppercased.
String brandInitials(String name) {
  return name.length >= 3
      ? name.substring(0, 3).toUpperCase()
      : name.toUpperCase();
}

/// Decorative grid overlay painted behind the hero.
class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double thickness;

  GridPainter({
    required this.color,
    required this.spacing,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return color != oldDelegate.color ||
        spacing != oldDelegate.spacing ||
        thickness != oldDelegate.thickness;
  }
}
