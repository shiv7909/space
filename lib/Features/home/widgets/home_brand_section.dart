import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../services/brand_challenge_service.dart';
import '../../spaces/cubits/brand_challenge_cubit.dart';
import '../../spaces/screens/rewards_screen.dart';
import '../../../models/home_brand_section_model.dart';

// ════════════════════════════════════════════════════════════════════
// HOME BRAND SECTION — container + layout
// ════════════════════════════════════════════════════════════════════
class HomeBrandSection extends StatelessWidget {
  final HomeBrandSectionModel? section;
  final bool isLoading;
  final void Function(String challengeId) onOpenCard;
  final VoidCallback onShowMoreBrandDrops;

  const HomeBrandSection({
    super.key,
    required this.section,
    required this.isLoading,
    required this.onOpenCard,
    required this.onShowMoreBrandDrops,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: _BrandSectionShimmer(),
      );
    }

    final data = section;
    if (data == null || !data.hasAnyCard) return const SizedBox.shrink();

    final card = data.card;
    if (card == null) return const SizedBox.shrink();
    final isEnrolled = card.isActiveCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                'Brand Drops',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A3D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Spacer(),
              if (isEnrolled)
                GestureDetector(
                  onTap: onShowMoreBrandDrops,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'More brand drops',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.appleBlue,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.appleBlue,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HomeBrandCard(
            card: card,
            snapLimit: data.snapLimit,
            isEnrolled: isEnrolled,
            showHeroBanner: false,
            onOpen: () => onOpenCard(card.challengeId),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// BRAND CARD — editorial white card matching discovery feed
// ════════════════════════════════════════════════════════════════════
class HomeBrandCard extends StatefulWidget {
  final HomeBrandCardModel card;
  final int snapLimit;
  final bool isEnrolled;
  final bool showHeroBanner;
  final String? enrolledActionLabel;
  final VoidCallback onOpen;

  const HomeBrandCard({
    required this.card,
    required this.snapLimit,
    required this.isEnrolled,
    this.showHeroBanner = true,
    this.enrolledActionLabel,
    required this.onOpen,
    super.key,
  });

  @override
  State<HomeBrandCard> createState() => _HomeBrandCardState();
}

class _HomeBrandCardState extends State<HomeBrandCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeSlide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeSlide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    Future.microtask(() {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final card = widget.card;

    // Resolve a legible accent from brand theme
    Color rawAccent = card.theme.colors.accent;
    if (rawAccent.computeLuminance() > 0.7) {
      final hsl = HSLColor.fromColor(rawAccent);
      rawAccent =
          hsl.withLightness((hsl.lightness - 0.3).clamp(0.2, 1.0)).toColor();
    }
    final accent = rawAccent;

    final remaining = math.max(0, card.snapsRemainingToday);

    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.lightImpact();
            widget.onOpen();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.978 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Hero Banner ───────────────────────────────────────
                    if (widget.showHeroBanner)
                      _HeroBanner(
                        bannerUrl: card.bannerUrl,
                        accent: accent,
                        isEnrolled: widget.isEnrolled,
                        daysLeft: card.daysLeft,
                      ),

                    // ── Header (brand + title) ────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand name row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (card.logoUrl != null &&
                                  card.logoUrl!.isNotEmpty) ...[
                                Container(
                                  width: 16 * s,
                                  height: 16 * s,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    imageUrl: card.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorWidget:
                                        (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                                SizedBox(width: 6 * s),
                              ],
                              Flexible(
                                child: Text(
                                  card.brandName.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 1.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (card.isVerified) ...[
                                SizedBox(width: 4 * s),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 11 * s,
                                  color: AppColors.appleBlue,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4 * s),
                          // Challenge title — last word in accent
                          _AccentTitle(
                            title: card.challengeTitle,
                            accent: accent,
                            s: s,
                          ),
                        ],
                      ),
                    ),

                    // ── Enrolled: progress + milestone teaser ─────────────
                    if (widget.isEnrolled) ...[
                      SizedBox(height: 12 * s),
                      _EnrolledProgressSection(
                        card: card,
                        accent: accent,
                        s: s,
                      ),
                    ],

                    // ── Reward pills row ──────────────────────────────────
                    if (!widget.isEnrolled) ...[
                      SizedBox(height: 10 * s),
                      _DiscoverRewardPills(card: card, accent: accent, s: s),
                    ],

                    SizedBox(height: 14 * s),

                    // ── Footer ────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
                      child: Row(
                        children: [
                          // Left: reward pool OR stats
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * s,
                                vertical: 8 * s,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(12 * s),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.16),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12 * s,
                                    color: accent,
                                  ),
                                  SizedBox(width: 6 * s),
                                  Flexible(
                                    child: Text(
                                      card.rewardPoolText.isNotEmpty
                                          ? card.rewardPoolText
                                          : '${_formatCount(card.stats.totalEnrolled)} joined',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11 * s,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Right: action button or earned rewards badge
                          if (widget.isEnrolled && card.earnedRewardsCount > 0)
                            _EarnedRewardsBadge(
                              count: card.earnedRewardsCount,
                              s: s,
                              onTap: () => _openRewardsPage(context, card.challengeId),
                            )
                          else
                            _ActionButton(
                              isEnrolled: widget.isEnrolled,
                              remaining: remaining,
                              labelOverride:
                                  widget.isEnrolled
                                      ? widget.enrolledActionLabel
                                      : null,
                              s: s,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRewardsPage(BuildContext context, String challengeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => BrandChallengeCubit(
            BrandChallengeService(supabaseClient: Supabase.instance.client),
          ),
          child: RewardsScreen(challengeId: challengeId),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// HERO BANNER — with live dot + chip overlay
// ════════════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  final String? bannerUrl;
  final Color accent;
  final bool isEnrolled;
  final int daysLeft;

  const _HeroBanner({
    required this.bannerUrl,
    required this.accent,
    required this.isEnrolled,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final hasBanner = bannerUrl != null && bannerUrl!.isNotEmpty;

    if (!hasBanner) return const SizedBox.shrink();

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 150 * s,
          child: CachedNetworkImage(
            imageUrl: bannerUrl!,
            fit: BoxFit.cover,
            placeholder:
                (_, __) => Container(color: accent.withValues(alpha: 0.12)),
            errorWidget:
                (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.25),
                        const Color(0xFFF7F6FC),
                      ],
                    ),
                  ),
                ),
          ),
        ),

        // Top-left: LIVE dot
        Positioned(
          top: 10 * s,
          left: 12 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5 * s,
                  height: 5 * s,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 5 * s),
                Text(
                  'LIVE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5 * s,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top-right: enrolled badge OR days-left chip
        Positioned(
          top: 10 * s,
          right: 12 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color:
                  isEnrolled
                      ? const Color(0xFF00C896).withValues(alpha: 0.92)
                      : Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isEnrolled ? '✓ Enrolled' : '${daysLeft}d left',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9 * s,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ACCENT TITLE — last word highlighted in brand accent colour
// ════════════════════════════════════════════════════════════════════
class _AccentTitle extends StatelessWidget {
  final String title;
  final Color accent;
  final double s;

  const _AccentTitle({
    required this.title,
    required this.accent,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final words = title.trim().split(' ');
    final body =
        words.length > 1
            ? '${words.sublist(0, words.length - 1).join(' ')} '
            : '';
    final accentWord = words.last;

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 19 * s,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111111),
          height: 1.15,
          letterSpacing: -0.4,
        ),
        children: [
          if (body.isNotEmpty) TextSpan(text: body),
          TextSpan(text: accentWord, style: TextStyle(color: accent)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ENROLLED PROGRESS SECTION — days done + milestone teaser
// ════════════════════════════════════════════════════════════════════
class _EnrolledProgressSection extends StatelessWidget {
  final HomeBrandCardModel card;
  final Color accent;
  final double s;

  const _EnrolledProgressSection({
    required this.card,
    required this.accent,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final next = card.nextMilestone;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      child: Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14 * s),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child:
            next == null
                ? Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6 * s),
                    Text(
                      "You've unlocked everything!",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5 * s,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Progress text + line
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${card.daysCompleted} / ${next.dayTarget} Days Done',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5 * s,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressValue(card, next),
                              backgroundColor: accent.withValues(alpha: 0.14),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                              minHeight: 6 * s,
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            '${next.daysToUnlock} more days to unlock ${next.reward?.title ?? next.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5 * s,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    // Reward image (finish line)
                    if (next.reward?.imageUrl != null)
                      Container(
                        width: 40 * s,
                        height: 40 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8 * s),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.2),
                          ),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              next.reward!.imageUrl!,
                            ),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 40 * s,
                        height: 40 * s,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8 * s),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.redeem_rounded,
                            size: 24 * s,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  double _progressValue(HomeBrandCardModel card, HomeBrandNextMilestone? next) {
    if (next == null) return 1.0;
    final target = next.dayTarget > 0 ? next.dayTarget : 1;
    return (card.daysCompleted / target).clamp(0.0, 1.0);
  }
}

// ════════════════════════════════════════════════════════════════════
// DISCOVER REWARD PILLS — scrollable challenge milestones
// ════════════════════════════════════════════════════════════════════
class _DiscoverRewardPills extends StatelessWidget {
  final HomeBrandCardModel card;
  final Color accent;
  final double s;

  const _DiscoverRewardPills({
    required this.card,
    required this.accent,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    // Show next milestone as the highlighted pill + generic placeholders
    final next = card.nextMilestone;

    return SizedBox(
      height: 36 * s,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        clipBehavior: Clip.none,
        children: [
          if (next != null) ...[
            _RewardPill(
              label: 'Day ${next.dayTarget}',
              reward: next.reward?.title ?? next.label,
              active: true,
              accent: accent,
              imageUrl: next.reward?.imageUrl,
              s: s,
            ),
            SizedBox(width: 8 * s),
          ],
          _RewardPill(
            label: 'Start',
            reward:
                card.rewardPoolText.isNotEmpty
                    ? card.rewardPoolText
                    : 'Starter Gift',
            active: false,
            accent: accent,
            s: s,
          ),
          SizedBox(width: 8 * s),
          _RewardPill(
            label: '${card.daysLeft}d Challenge',
            reward: 'Grand Prize',
            active: false,
            accent: accent,
            s: s,
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  final String label;
  final String reward;
  final bool active;
  final Color accent;
  final String? imageUrl;
  final double s;

  const _RewardPill({
    required this.label,
    required this.reward,
    required this.active,
    required this.accent,
    required this.s,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color:
            active
                ? accent.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              active
                  ? accent.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Container(
              width: 14 * s,
              height: 14 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Text(
              active ? '✦' : '✧',
              style: TextStyle(
                fontSize: 10 * s,
                color: active ? accent : Colors.black45,
              ),
            ),
          SizedBox(width: 5 * s),
          Text(
            reward,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5 * s,
              fontWeight: FontWeight.w700,
              color: active ? accent : Colors.black87,
            ),
          ),
          SizedBox(width: 6 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color:
                  active
                      ? accent.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5 * s,
                fontWeight: FontWeight.w800,
                color: active ? accent : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ════════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final bool isEnrolled;
  final int remaining;
  final String? labelOverride;
  final double s;

  const _ActionButton({
    required this.isEnrolled,
    required this.remaining,
    this.labelOverride,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        isEnrolled
            ? (labelOverride ??
                (remaining > 0 ? 'Go For It 🔥' : 'Crushed It 🎯'))
            : 'Explore';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0F),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 9 * s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12 * s,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (!isEnrolled || remaining > 0 || labelOverride != null) ...[
            SizedBox(width: 6 * s),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 13 * s,
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// EARNED REWARDS BADGE — trophy count
// ════════════════════════════════════════════════════════════════════
class _EarnedRewardsBadge extends StatefulWidget {
  final int count;
  final double s;
  final VoidCallback onTap;

  const _EarnedRewardsBadge({
    required this.count,
    required this.s,
    required this.onTap,
  });

  @override
  State<_EarnedRewardsBadge> createState() => _EarnedRewardsBadgeState();
}

class _EarnedRewardsBadgeState extends State<_EarnedRewardsBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    final s = widget.s;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 12)),
            SizedBox(width: 5 * s),
            Text(
              '${widget.count}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12 * s,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
              ),
            ),
            // Subtle pulse dot to hint there's something to claim
            SizedBox(width: 6 * s),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final opacity = 0.5 + (_pulseCtrl.value * 0.5);
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF4848).withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4848).withValues(alpha: 0.24),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// SHIMMER SKELETON
// ════════════════════════════════════════════════════════════════════
class _BrandSectionShimmer extends StatelessWidget {
  const _BrandSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 138,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 14),
        const _ShimmerCardPlaceholder(),
        const SizedBox(height: 16),
        const _ShimmerCardPlaceholder(),
      ],
    );
  }
}

class _ShimmerCardPlaceholder extends StatelessWidget {
  const _ShimmerCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════
String _formatCount(int value) {
  final safe = value < 0 ? 0 : value;
  final chars = safe.toString().split('').reversed.toList();
  final out = <String>[];
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) out.add(',');
    out.add(chars[i]);
  }
  return out.reversed.join();
}
