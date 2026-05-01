// ════════════════════════════════════════════════════════════════════
// milestone_circles.dart — Horizontal scrollable milestone circles
// Shows earned (checkmark), active (progress), and locked (greyed) states
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';

class MilestoneCircles extends StatelessWidget {
  final List<MilestoneModel> milestones;
  final BrandThemeData theme;
  final bool showLabels;
  final double scale;

  const MilestoneCircles({
    super.key,
    required this.milestones,
    required this.theme,
    this.showLabels = true,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return SizedBox(
        height: 120 * scale,
        child: Center(
          child: Text(
            'No milestones yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final primaryColor = theme.colors.primary;
    final accentColor = theme.colors.accent;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          children: List.generate(
            milestones.length,
            (index) {
              final milestone = milestones[index];
              return Padding(
                padding: EdgeInsets.only(right: 16 * scale),
                child: _MilestoneCircle(
                  milestone: milestone,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  showLabel: showLabels,
                  scale: scale,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MilestoneCircle extends StatelessWidget {
  final MilestoneModel milestone;
  final Color primaryColor;
  final Color accentColor;
  final bool showLabel;
  final double scale;

  const _MilestoneCircle({
    required this.milestone,
    required this.primaryColor,
    required this.accentColor,
    required this.showLabel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isEarned = milestone.isDone;
    final isActive = milestone.isActive;
    // Circle sizing
    const baseCircleSize = 72.0;
    final circleSize = baseCircleSize * scale;

    // Color logic
    final bgColor = isEarned
      ? primaryColor
        : isActive
        ? primaryColor.withValues(alpha: 0.12)
            : AppTheme.surface;

    final borderColor = isEarned
      ? primaryColor
        : isActive
        ? primaryColor
            : AppTheme.onSurfaceVariant.withValues(alpha: 0.3);

    final textColor = isEarned
        ? Colors.white
        : isActive
        ? primaryColor
            : AppTheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Milestone circle with badge
        Stack(
          alignment: Alignment.center,
          children: [
            // Main circle
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 2 * scale,
                ),
                boxShadow: isActive || isEarned
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.12),
                          blurRadius: 12 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  'Day\n${milestone.dayTarget}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            // Earned checkmark badge (top-right)
            if (isEarned)
              Positioned(
                top: -6 * scale,
                right: -6 * scale,
                child: Container(
                  width: 28 * scale,
                  height: 28 * scale,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surface,
                      width: 2 * scale,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16 * scale,
                    ),
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 8 * scale),

        // Label/sublabel below circle
        if (showLabel)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                milestone.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: isEarned
                      ? primaryColor.withValues(alpha: 0.1)
                      : isActive
                          ? accentColor.withValues(alpha: 0.1)
                          : AppTheme.background,
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Text(
                  milestone.sublabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5 * scale,
                    fontWeight: FontWeight.w600,
                    color: isEarned
                        ? primaryColor
                        : isActive
                            ? accentColor
                            : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
