// ════════════════════════════════════════════════════════════════════
// challenge_journey.dart — Journey progress + Mark-Done + energy bar
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import '../../cubits/brand_challenge_cubit.dart';
import 'challenge_helpers.dart';

class ChallengeJourneySection extends StatelessWidget {
  final String challengeId;
  final ChallengeJourneyModel journey;
  final BrandThemeData theme;
  final double s;
  final bool canMarkDone;

  const ChallengeJourneySection({
    super.key,
    required this.challengeId,
    required this.journey,
    required this.theme,
    required this.s,
    this.canMarkDone = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = journey.progress;
    final accent = theme.colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('YOUR JOURNEY', s),
        SizedBox(height: 10 * s),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.all(20 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.progressPct}% Completed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  Text(
                    progress.dayLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24 * s),

              // Milestone track
              SizedBox(
                height: 62 * s,
                child: Stack(
                  children: [
                    Positioned(
                      top: 13 * s,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 5 * s,
                        decoration: BoxDecoration(
                          color: AppTheme.background.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 13 * s,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.progressFraction,
                          child: Container(
                            height: 5 * s,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent, const Color(0xFF0057FF)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...journey.milestones.map((m) {
                      final factor =
                          progress.durationDays > 0
                              ? (m.dayTarget / progress.durationDays)
                              : 0.0;
                      final isReached = m.isDone || m.isActive;

                      return Align(
                        alignment: FractionalOffset(
                          factor.clamp(0.0, 1.0),
                          0.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22 * s,
                              height: 22 * s,
                              decoration: BoxDecoration(
                                color:
                                    m.isDone
                                        ? accent
                                        : isReached
                                        ? accent.withValues(alpha: 0.18)
                                        : AppTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isReached
                                          ? accent
                                          : AppTheme.onSurfaceVariant,
                                  width: 1.7 * s,
                                ),
                                boxShadow:
                                    isReached
                                        ? [
                                          BoxShadow(
                                            color: accent.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 10 * s,
                                            offset: Offset(0, 3 * s),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Icon(
                                Icons.card_giftcard_rounded,
                                size: 12 * s,
                                color:
                                    isReached
                                        ? accent
                                        : AppTheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 4 * s),
                            Text(
                              'Day ${m.dayTarget}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9 * s,
                                fontWeight: FontWeight.w700,
                                color:
                                    isReached
                                        ? AppTheme.onBackground
                                        : AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // SizedBox(height: 8 * s),

              // const Divider(),
              SizedBox(height: 10 * s),
              SizedBox(
                width: double.infinity,
                height: 62 * s,
                child: ElevatedButton(
                  onPressed:
                      (!canMarkDone || progress.doneToday)
                          ? null
                          : () => _handleMarkDoneTap(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !canMarkDone
                            ? AppTheme.onSurfaceVariant
                            : (progress.doneToday
                                ? AppTheme.accentGreen
                                : AppTheme.onBackground),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        !canMarkDone
                            ? AppTheme.onSurfaceVariant
                            : AppTheme.accentGreen,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    !canMarkDone
                        ? 'Join to Mark Done'
                        : (progress.doneToday ? 'Done for today' : 'Mark Done'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleMarkDoneTap(BuildContext context) async {
    final shouldMarkDone = await _confirmMarkDone(context);
    if (shouldMarkDone != true || !context.mounted) return;

    HapticFeedback.heavyImpact();

    final result = await context.read<BrandChallengeCubit>().markHabitDone(
      challengeId,
    );
    if (!context.mounted) return;

    final success = result['success'] == true;
    if (!success) {
      final code = (result['code'] as String?) ?? '';
      final message = _errorMessageForCode(code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accentAmber,
        ),
      );
      return;
    }

    final celebration =
        result['celebration'] is Map
            ? Map<String, dynamic>.from(result['celebration'] as Map)
            : <String, dynamic>{};
    final message = (celebration['message'] as String?)?.trim();

    final reward =
        result['reward'] is Map
            ? Map<String, dynamic>.from(result['reward'] as Map)
            : null;

    if (reward != null && reward['earned'] == true) {
      await _showRewardUnlockDialog(context, reward, message);
      return;
    }

    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  Future<bool?> _confirmMarkDone(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Mark done, fr?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          content: Text(
            'You are about to lock in today. You sure?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Wait, not yet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.onBackground,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Yep, mark it',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _errorMessageForCode(String code) {
    switch (code) {
      case 'ALREADY_LOGGED':
        return 'Already marked done for today.';
      case 'NOT_SCHEDULED_TODAY':
        return 'This habit is not scheduled for today.';
      case 'NOT_ENROLLED':
        return 'Join the challenge to log today.';
      case 'CHALLENGE_INACTIVE':
        return 'This challenge is inactive now.';
      default:
        return 'Could not mark done right now. Please try again.';
    }
  }

  Future<void> _showRewardUnlockDialog(
    BuildContext context,
    Map<String, dynamic> reward,
    String? celebrationMessage,
  ) {
    final rewardTitle =
        (reward['reward_title'] as String?) ?? 'Reward unlocked';
    final milestone = (reward['milestone'] as String?) ?? 'Milestone reached';
    final dayTarget = reward['day_target'];
    final couponCode = reward['coupon_code'] as String?;
    final couponExpiresAtRaw = reward['coupon_expires_at']?.toString();
    final couponExpiresAt =
        couponExpiresAtRaw != null
            ? DateTime.tryParse(couponExpiresAtRaw)
            : null;
    final isPhysical = reward['is_physical'] == true;

    return showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reward Unlocked',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    rewardTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayTarget == null
                        ? milestone
                        : '$milestone • Day $dayTarget',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  if (celebrationMessage != null &&
                      celebrationMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      celebrationMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                  ],
                  if (!isPhysical &&
                      couponCode != null &&
                      couponCode.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        couponCode,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          color: AppTheme.onBackground,
                        ),
                      ),
                    ),
                    if (couponExpiresAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Valid until ${couponExpiresAt.toLocal().toIso8601String().split('T').first}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.onBackground,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Awesome',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ChallengeEnergyBar — Community energy progress
// ═══════════════════════════════════════════════════════════════════

class ChallengeEnergyBar extends StatelessWidget {
  final ChallengeEnergy energy;
  final BrandThemeData theme;
  final double s;

  const ChallengeEnergyBar({
    super.key,
    required this.energy,
    required this.theme,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colors.accent;
    final fraction = energy.fraction.clamp(0.0, 1.0);
    final pct = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('COMMUNITY ENERGY', s),
        SizedBox(height: 10 * s),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.all(20 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onBackground.withValues(alpha: 0.5),
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        '${energy.completionsToday} crushed it 🔥',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 6 * s,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$pct%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * s),
              Stack(
                children: [
                  Container(
                    height: 10 * s,
                    decoration: BoxDecoration(
                      color: AppTheme.onBackground.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 10 * s,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            Color.lerp(accent, const Color(0xFF00FFCC), 0.6)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * s),
              Text(
                energy.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
