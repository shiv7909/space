// ════════════════════════════════════════════════════════════════════
// challenge_rewards_section.dart — Single challenge's milestones section
// Used in detail page preview or dedicated rewards screen
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import 'milestone_circles.dart';

class ChallengeRewardsSection extends StatelessWidget {
  final ChallengeRewardsModel rewards;
  final bool showBanner;
  final bool compact;
  final double s;

  const ChallengeRewardsSection({
    super.key,
    required this.rewards,
    this.showBanner = true,
    this.compact = false,
    this.s = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = rewards.theme;
    final primaryColor = theme.colors.primary;
    final bgColor =
        primaryColor.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MILESTONES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12 * s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${rewards.earnedCount}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26 * s,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    'of ${rewards.totalMilestones} unlocked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * s),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rewards.progressFraction,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 4 * s,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20 * s),

        // ── MILESTONE CIRCLES ────────────────────────────────────
        SizedBox(
          height: compact ? 100 * s : 140 * s,
          child: MilestoneCircles(
            milestones: rewards.milestones,
            theme: theme,
            showLabels: !compact,
            scale: s,
          ),
        ),

        SizedBox(height: 24 * s),

        // ── REWARDS PREVIEW (Top 3 milestone rewards) ───────────
        if (!compact && _hasRewards())
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REWARDS YOU\'RE UNLOCKING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10 * s,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 12 * s),
                ..._topRewards().asMap().entries.map((e) {
                  final idx = e.key;
                  final reward = e.value;
                  return _RewardCard(
                    reward: reward,
                    primaryColor: primaryColor,
                    scale: s,
                    isLast: idx == _topRewards().length - 1,
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  bool _hasRewards() {
    return rewards.milestones.any((m) => m.rewards.isNotEmpty);
  }

  List<MilestoneReward> _topRewards() {
    final allRewards = rewards.milestones
        .where((m) => m.rewards.isNotEmpty)
        .expand((m) => m.rewards)
        .take(3)
        .toList();
    return allRewards;
  }
}

// ────────────────────────────────────────────────────────────────
// Individual reward card
// ────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final MilestoneReward reward;
  final Color primaryColor;
  final double scale;
  final bool isLast;

  const _RewardCard({
    required this.reward,
    required this.primaryColor,
    required this.scale,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isPhysical = reward.isPhysical;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12 * scale),
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Reward image or icon
            Container(
              width: 56 * scale,
              height: 56 * scale,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: reward.imageUrl != null && reward.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8 * scale),
                      child: Image.network(
                        reward.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(
                        isPhysical ? Icons.card_giftcard : Icons.local_offer,
                        color: primaryColor,
                        size: 24 * scale,
                      ),
                    ),
            ),

            SizedBox(width: 12 * scale),

            // Reward details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Text(
                          isPhysical ? '📦 Physical' : '🎟️ Coupon',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5 * scale,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Earned badge
            if (reward.earned)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12 * scale,
                      color: primaryColor,
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      'Earned',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5 * scale,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
