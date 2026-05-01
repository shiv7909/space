import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../solo/widgets/today_progress_widget.dart';

/// Stateless helper widgets for the hero carousel cards:
/// shimmer placeholder, premium space card, and locked card.
class HeroCarouselCards {
  HeroCarouselCards._();

  /// Blank shimmer placeholder while dashboard is loading.
  static Widget buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 1),
      ),
      child: const SizedBox.shrink(),
    );
  }

  /// Premium (unlocked) space card with tier info + progress bar.
  static Widget buildPremiumSpaceCard({
    required String tierLabel,
    required Color tierColor,
    required IconData icon,
    required BuildContext context,
  }) {
    final s = Responsive.scale(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 14 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 34 * s,
                  height: 34 * s,
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18 * s, color: tierColor),
                ),
                SizedBox(width: 10 * s),
                Text(
                  '$tierLabel Space',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onBackground,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 4 * s,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Unlocked',
                    style: GoogleFonts.inter(
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14 * s),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.0,
                minHeight: 6 * s,
                backgroundColor: const Color(0xFFF0F0F5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  tierColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            SizedBox(height: 10 * s),
            Text(
              'Navigate to $tierLabel tab to see your progress',
              style: GoogleFonts.inter(
                fontSize: 12 * s,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Locked/blurred space card for non-premium users.
  static Widget buildLockedCard({
    required String tierLabel,
    required Color tierColor,
    BuildContext? context,
  }) {
    final s = context != null ? Responsive.scale(context) : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: TodayProgressWidget(
                totalScheduled: 4,
                completed: 2,
                remaining: 2,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outline, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38 * s,
                        height: 38 * s,
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tierColor.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 17 * s,
                          color: tierColor,
                        ),
                      ),
                      SizedBox(height: 9 * s),
                      Text(
                        '$tierLabel Space',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      Text(
                        'Upgrade to unlock',
                        style: GoogleFonts.inter(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
