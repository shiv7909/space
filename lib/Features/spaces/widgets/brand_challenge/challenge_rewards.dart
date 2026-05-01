// ════════════════════════════════════════════════════════════════════
// challenge_rewards.dart — Milestone rewards row + earned coupons
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import '../../cubits/brand_challenge_cubit.dart';
import 'challenge_helpers.dart';

class ChallengeRewardsRow extends StatelessWidget {
  final List<MilestoneModel> milestones;
  final BrandThemeData theme;
  final double s;

  const ChallengeRewardsRow({super.key, required this.milestones, required this.theme, required this.s});

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    final accent = theme.colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('MILESTONE REWARDS', s),
        SizedBox(height: 12 * s),
        SizedBox(
          height: 214 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: milestones.length,
            separatorBuilder: (_, __) => SizedBox(width: 12 * s),
            itemBuilder: (context, i) {
              final m = milestones[i];
              final reward = m.rewards.isNotEmpty ? m.rewards.first : null;
              final isUnlocked = m.isDone;
              final isActive = m.isActive;

                final cardColor = Colors.white;
                final textColor = AppTheme.onBackground;

                final statusPillBg = isUnlocked
                  ? AppTheme.accentGreen.withValues(alpha: 0.14)
                  : isActive
                    ? accent.withValues(alpha: 0.14)
                    : AppTheme.onBackground.withValues(alpha: 0.08);

                final statusPillTextColor = isUnlocked
                  ? AppTheme.accentGreen
                  : isActive
                    ? accent
                    : AppTheme.onSurfaceVariant;

                final cardBorderColor = isUnlocked
                  ? AppTheme.accentGreen.withValues(alpha: 0.32)
                  : isActive
                    ? accent.withValues(alpha: 0.32)
                    : AppTheme.onBackground.withValues(alpha: 0.08);

              final rewardTitle = reward?.title ?? m.label;
              final rewardSubtitle = isUnlocked
                  ? (reward?.earned == true ? 'Claimed' : 'Unlocked')
                  : isActive
                      ? 'In progress'
                      : 'Unlock on day ${m.dayTarget}';

              return Container(
                width: 156 * s,
                padding: EdgeInsets.all(12 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 * s),
                  color: cardColor,
                  border: Border.all(color: cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                          decoration: BoxDecoration(
                            color: statusPillBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isUnlocked ? 'UNLOCKED' : 'DAY ${m.dayTarget}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9 * s,
                              fontWeight: FontWeight.w900,
                              color: statusPillTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isUnlocked && reward?.earned == true)
                          Container(
                            padding: EdgeInsets.all(5 * s),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentGreen.withValues(alpha: 0.14),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12 * s,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10 * s),

                    if (reward != null && reward.imageUrl != null && reward.imageUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 86 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(
                            color: cardBorderColor,
                          ),
                          color: AppTheme.surface,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16 * s),
                          child: CachedNetworkImage(
                            imageUrl: reward.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.surface),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                size: 20 * s,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 86 * s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16 * s),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.18),
                          ),
                          color: textColor.withValues(alpha: 0.06),
                        ),
                        child: Text(
                          m.iconUrl ?? '🏅',
                          style: TextStyle(fontSize: 30 * s),
                        ),
                      ),

                    SizedBox(height: 10 * s),
                    Text(
                      rewardTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      rewardSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10 * s,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.78),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Earned coupons section
// ═══════════════════════════════════════════════════════════════════

class ChallengeEarnedCoupons extends StatelessWidget {
  final List<ChallengeCouponModel> coupons;
  final BrandThemeData theme;
  final double s;

  const ChallengeEarnedCoupons({super.key, required this.coupons, required this.theme, required this.s});

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) return const SizedBox.shrink();
    final accent = theme.colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('YOUR REWARDS', s),
        SizedBox(height: 10 * s),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: coupons.length,
          separatorBuilder: (_, __) => SizedBox(height: 12 * s),
          itemBuilder: (context, i) {
            final c = coupons[i];
            return Container(
              padding: EdgeInsets.all(16 * s),
              decoration: BoxDecoration(
                color: c.isExpired ? AppTheme.surface.withAlpha(128) : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.isUsed ? AppTheme.accentGreen.withAlpha(128) : (c.isExpired ? AppTheme.outline.withAlpha(76) : AppTheme.onBackground.withAlpha(15))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48 * s, height: 48 * s,
                        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.onBackground.withAlpha(12))),
                        child: c.reward.imageUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: c.reward.imageUrl!, fit: BoxFit.cover))
                            : const Center(child: Icon(Icons.star_rounded, color: AppTheme.onSurfaceVariant)),
                      ),
                      SizedBox(width: 14 * s),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.reward.title, style: GoogleFonts.plusJakartaSans(fontSize: 15 * s, fontWeight: FontWeight.w800, color: c.isExpired ? AppTheme.onSurfaceVariant : AppTheme.onBackground)),
                          SizedBox(height: 4 * s),
                          Row(children: [
                            Icon(c.reward.isPhysical ? Icons.local_shipping_rounded : Icons.confirmation_number_rounded, size: 14 * s, color: AppTheme.onSurfaceVariant),
                            SizedBox(width: 6 * s),
                            Text(c.reward.isPhysical ? 'Physical Reward' : 'Coupon Code', style: GoogleFonts.plusJakartaSans(fontSize: 12 * s, color: AppTheme.onSurfaceVariant)),
                          ]),
                        ],
                      )),
                    ],
                  ),
                  if (!c.reward.isPhysical && c.code != null) ...[
                    SizedBox(height: 16 * s),
                    const Divider(height: 1),
                    SizedBox(height: 16 * s),
                    Row(children: [
                      Expanded(child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
                        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                        child: SelectableText(c.code!, style: GoogleFonts.plusJakartaSans(fontSize: 16 * s, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: c.isUsed || c.isExpired ? AppTheme.onSurfaceVariant : AppTheme.onBackground, decoration: c.isUsed ? TextDecoration.lineThrough : null)),
                      )),
                      SizedBox(width: 12 * s),
                      if (c.isUsed)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
                          decoration: BoxDecoration(color: AppTheme.accentGreen.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 20),
                            SizedBox(width: 6 * s),
                            Text('Used', style: GoogleFonts.plusJakartaSans(fontSize: 14 * s, fontWeight: FontWeight.w800, color: AppTheme.accentGreen)),
                          ]),
                        )
                      else if (c.isExpired)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
                          decoration: BoxDecoration(color: AppTheme.outline.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Text('Expired', style: GoogleFonts.plusJakartaSans(fontSize: 14 * s, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant)),
                        )
                      else
                        ElevatedButton(
                          onPressed: () { HapticFeedback.mediumImpact(); context.read<BrandChallengeCubit>().redeemCoupon(c.id); },
                          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: Text('Mark Used', style: GoogleFonts.plusJakartaSans(fontSize: 14 * s, fontWeight: FontWeight.w800)),
                        ),
                    ]),
                    if (c.expiresAt != null) ...[
                      SizedBox(height: 8 * s),
                      Text(
                        'Expires ${c.expiresAt!.toLocal().toIso8601String().split('T').first}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12 * s, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ] else if (c.reward.isPhysical) ...[
                    SizedBox(height: 16 * s),
                    Container(
                      width: double.infinity, padding: EdgeInsets.all(12 * s),
                      decoration: BoxDecoration(color: AppTheme.accentGreen.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                      child: Text('Earned! Check your email for delivery details.', style: GoogleFonts.plusJakartaSans(fontSize: 13 * s, fontWeight: FontWeight.w700, color: AppTheme.accentGreen), textAlign: TextAlign.center),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
