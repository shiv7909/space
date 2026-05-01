// ════════════════════════════════════════════════════════════════════
// challenge_stats.dart — Glass-morphism stats strip
// ════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';

class ChallengeStatsStrip extends StatelessWidget {
  final ChallengeStats stats;
  final BrandThemeData theme;
  final double s;

  const ChallengeStatsStrip({
    super.key,
    required this.stats,
    required this.theme,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final c = theme.colors;
    final t = theme.typography;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 10 * s),
      child: Row(
        children: [
          _glassStatCard(
            value: '${stats.daysLeft}', label: 'Days Left',
            valueGradient: [c.accent, c.accent.withValues(alpha: 0.7)],
            icon: Icons.timer_rounded, iconColor: c.accent, t: t, s: s,
          ),
          SizedBox(width: 10 * s),
          _glassStatCard(
            value: stats.formattedEnrolled, label: 'Members',
            valueGradient: const [Color(0xFF6C63FF), Color(0xFF9D8FFF)],
            icon: Icons.group_rounded, iconColor: const Color(0xFF6C63FF), t: t, s: s,
          ),
          SizedBox(width: 10 * s),
          _glassStatCard(
            value: stats.formattedCompletion, label: 'Completing',
            valueGradient: const [Color(0xFF00C853), Color(0xFF00E676)],
            icon: Icons.bolt_rounded, iconColor: const Color(0xFF00C853), t: t, s: s,
          ),
        ],
      ),
    );
  }

  Widget _glassStatCard({
    required String value, required String label,
    required List<Color> valueGradient, required IconData icon,
    required Color iconColor, required BrandTypography t, required double s,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * s),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14 * s, horizontal: 10 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: iconColor.withValues(alpha: 0.15), width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6 * s),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14 * s, color: iconColor),
                ),
                SizedBox(height: 6 * s),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: valueGradient).createShader(bounds),
                  child: Text(value, style: t.headingStyle(size: 17 * s, color: Colors.white, height: 1.0)),
                ),
                SizedBox(height: 3 * s),
                Text(
                  t.transform(label),
                  style: t.bodyStyle(size: 9 * s, weight: FontWeight.w600, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
