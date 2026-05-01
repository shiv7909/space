import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../constants/solo_constants.dart';

class StickyHeaderBanner extends StatelessWidget {
  final StickyHeader header;

  const StickyHeaderBanner({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    final color = _getAccentColor(header.type);
    final icon = _getHeaderIcon(header.type);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.rs(context), vertical: 14.rs(context)),
      decoration: BoxDecoration(
        color: _getBackgroundColor(header.type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22.rs(context)),
          SizedBox(width: 14.rs(context)),
          Expanded(
            child: Text(
              header.message,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14.rs(context),
                letterSpacing: -0.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'milestone':
        return const Color(0xFFFFF9EE);
      case 'warning':
        return const Color(0xFFFFF7ED);
      case 'break':
        return const Color(0xFFFCECEC);
      case 'recovery':
        return const Color(0xFFFFF7ED);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  Color _getAccentColor(String type) {
    switch (type) {
      case 'milestone':
        return const Color(0xFF8B6914);
      case 'warning':
        return const Color(0xFFA06B2A);
      case 'break':
        return const Color(0xFFB54248);
      case 'recovery':
        return const Color(0xFFA06B2A);
      default:
        return AppTheme.onSurface;
    }
  }

  IconData _getHeaderIcon(String type) {
    switch (type) {
      case 'milestone':
        return Icons.emoji_events_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'break':
        return Icons.heart_broken_outlined;
      case 'recovery':
        return Icons.shield_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
