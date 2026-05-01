// ════════════════════════════════════════════════════════════════════
// rewards_screen.dart — Show all user's enrolled challenges with milestones
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../models/brand_challenge_models.dart';
import '../../../services/brand_challenge_service.dart';
import '../cubits/brand_challenge_cubit.dart';
import '../cubits/brand_challenge_state.dart';
import '../widgets/brand_challenge/challenge_rewards_section.dart';

class RewardsScreen extends StatefulWidget {
  final String challengeId;

  const RewardsScreen({
    super.key,
    required this.challengeId,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late BrandChallengeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<BrandChallengeCubit>();
    _cubit.loadChallengeRewards(widget.challengeId);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final s = Responsive.scale(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<BrandChallengeCubit, BrandChallengeState>(
        builder: (context, state) {
          if (state is RewardsLoading) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppTheme.surface,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    'Milestones',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16 * s),
                    child: _buildShimmer(s),
                  ),
                ),
              ],
            );
          }

          if (state is ChallengeRewardsLoaded) {
            return _buildRewardsContent(state.rewards, topPad, s);
          }

          if (state is RewardsError) {
            return _buildError(state.message, s);
          }

          return _buildError('Unknown state', s);
        },
      ),
    );
  }

  Widget _buildRewardsContent(
    ChallengeRewardsModel rewards,
    double topPad,
    double s,
  ) {
    return CustomScrollView(
      slivers: [
        // ── APP BAR ──────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          pinned: true,
          expandedHeight: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Milestones',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        // ── CONTENT ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge header
                Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand logo + name
                      Row(
                        children: [
                          if (rewards.logoUrl != null && rewards.logoUrl!.isNotEmpty)
                            Container(
                              width: 48 * s,
                              height: 48 * s,
                              decoration: BoxDecoration(
                                color: rewards.theme.colors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10 * s),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10 * s),
                                child: Image.network(
                                  rewards.logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 48 * s,
                              height: 48 * s,
                              decoration: BoxDecoration(
                                color: rewards.theme.colors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10 * s),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.storefront,
                                  size: 24 * s,
                                  color: rewards.theme.colors.primary,
                                ),
                              ),
                            ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rewards.brandName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                Text(
                                  rewards.challengeTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13 * s,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onBackground,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16 * s),
                      // Progress info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${rewards.currentProgressDays} / ${rewards.durationDays} days',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          Text(
                            '${(rewards.progressFraction * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w700,
                              color: rewards.theme.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rewards section
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16 * s),
                  child: ChallengeRewardsSection(
                    rewards: rewards,
                    showBanner: false,
                    compact: false,
                    s: s,
                  ),
                ),

                SizedBox(height: 32 * s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message, double s) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Milestones',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16 * s,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48 * s,
              color: AppTheme.onSurfaceVariant,
            ),
            SizedBox(height: 16 * s),
            Text(
              'Failed to load milestones',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14 * s,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12 * s,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24 * s),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(double s) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F1F4),
      highlightColor: const Color(0xFFF8F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48 * s,
                height: 48 * s,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10 * s),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12 * s,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8 * s),
                    Container(
                      width: 150,
                      height: 16 * s,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * s),
          Container(
            width: double.infinity,
            height: 200 * s,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// All Rewards Screen — shows all enrolled challenges' rewards
// ────────────────────────────────────────────────────────────────

class AllRewardsScreen extends StatefulWidget {
  const AllRewardsScreen({super.key});

  @override
  State<AllRewardsScreen> createState() => _AllRewardsScreenState();
}

class _AllRewardsScreenState extends State<AllRewardsScreen> {
  late final BrandChallengeService _service;
  bool _isLoading = true;
  String? _error;
  List<ChallengeRewardsModel> _rewards = const [];
  List<ChallengeCouponModel> _coupons = const [];

  @override
  void initState() {
    super.initState();
    _service = BrandChallengeService(supabaseClient: Supabase.instance.client);
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rewardsModel = await _service.getMyRewards();
      final rewards = rewardsModel.challenges;

      final couponBuckets = await Future.wait(
        rewards
            .where((c) => c.challengeId.isNotEmpty)
            .map((c) => _service.getChallengeCoupons(c.challengeId)),
      );

      final map = <String, ChallengeCouponModel>{};
      for (final bucket in couponBuckets) {
        for (final coupon in bucket) {
          map[coupon.id] = coupon;
        }
      }

      if (!mounted) return;
      setState(() {
        _rewards = rewards;
        _coupons = map.values.toList()
          ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  int get _activeCoupons =>
      _coupons.where((c) => !c.isUsed && !c.isExpired).length;

  int get _usedOrExpiredCoupons =>
      _coupons.where((c) => c.isUsed || c.isExpired).length;

  int get _earnedMilestones =>
      _rewards.fold<int>(0, (sum, c) => sum + c.earnedCount);

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Your Rewards',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: _buildShimmerList(s),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Your Rewards',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFA32D2D),
                  size: 42 * s,
                ),
                SizedBox(height: 12 * s),
                Text(
                  'Could not load rewards wallet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5 * s,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16 * s),
                ElevatedButton(
                  onPressed: _loadWallet,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20 * s, 18 * s, 20 * s, 18 * s),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F1923), Color(0xFF1A2D3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HABITZ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5 * s,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    SizedBox(height: 6 * s),
                    Text(
                      'Your Rewards',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24 * s,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    Row(
                      children: [
                        Expanded(
                          child: _WalletStatPill(
                            label: 'Active',
                            value: _activeCoupons.toString(),
                            s: s,
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: _WalletStatPill(
                            label: 'Used',
                            value: _usedOrExpiredCoupons.toString(),
                            s: s,
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: _WalletStatPill(
                            label: 'Earned',
                            value: _earnedMilestones.toString(),
                            s: s,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  labelColor: const Color(0xFF1DCE8A),
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  indicatorColor: const Color(0xFF1DCE8A),
                  indicatorWeight: 2.6,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13 * s,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * s,
                  ),
                  tabs: const [
                    Tab(text: 'Coupons'),
                    Tab(text: 'Milestones'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCouponsTab(s),
                    _buildMilestonesTab(s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponsTab(double s) {
    if (_coupons.isEmpty) {
      return Center(
        child: Text(
          'No coupons yet.\nComplete challenges to earn!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13 * s,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    final active = _coupons.where((c) => !c.isUsed && !c.isExpired).toList();
    final used = _coupons.where((c) => c.isUsed || c.isExpired).toList();

    return ListView(
      padding: EdgeInsets.all(16 * s),
      children: [
        Text(
          'Active Coupons',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11 * s,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 10 * s),
        ...active.map((c) => _WalletCouponCard(coupon: c, s: s)).toList(),
        if (used.isNotEmpty) ...[
          SizedBox(height: 8 * s),
          Text(
            'Used & Expired',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11 * s,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10 * s),
          ...used.map((c) => _WalletCouponCard(coupon: c, s: s)).toList(),
        ],
      ],
    );
  }

  Widget _buildMilestonesTab(double s) {
    if (_rewards.isEmpty) {
      return Center(
        child: Text(
          'Join a challenge\nto earn milestone rewards!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13 * s,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16 * s),
      itemCount: _rewards.length,
      separatorBuilder: (_, __) => SizedBox(height: 14 * s),
      itemBuilder: (context, index) {
        return _WalletMilestoneCard(reward: _rewards[index], s: s);
      },
    );
  }

  Widget _buildShimmerList(double s) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F1F4),
      highlightColor: const Color(0xFFF8F9FB),
      child: ListView.builder(
        padding: EdgeInsets.all(16 * s),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 16 * s),
          child: Container(
            width: double.infinity,
            height: 200 * s,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * s),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletStatPill extends StatelessWidget {
  final String label;
  final String value;
  final double s;

  const _WalletStatPill({
    required this.label,
    required this.value,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 8 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20 * s,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1DCE8A),
              height: 1,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10 * s,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCouponCard extends StatelessWidget {
  final ChallengeCouponModel coupon;
  final double s;

  const _WalletCouponCard({required this.coupon, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDisabled = coupon.isUsed || coupon.isExpired;
    final brandColor = const Color(0xFF1DCE8A);
    final expiryText = coupon.isUsed
        ? 'Used'
        : coupon.isExpired
            ? 'Expired'
            : coupon.expiresAt != null
                ? 'Valid till ${_date(coupon.expiresAt!)}'
                : 'No expiry';

    return Container(
      margin: EdgeInsets.only(bottom: 14 * s),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42 * s,
                  height: 42 * s,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: brandColor,
                    size: 20 * s,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.brand.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11 * s,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        coupon.reward.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15 * s,
                          color: AppTheme.onBackground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        coupon.reward.isPhysical
                            ? 'Physical reward from milestone unlock'
                            : 'Coupon unlocked from challenge milestone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5 * s,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            child: Row(
              children: [
                _chip(
                  coupon.isUsed
                      ? 'Used'
                      : (coupon.isExpired ? 'Expired' : 'Active'),
                  coupon.isUsed
                      ? const Color(0xFF534AB7)
                      : (coupon.isExpired
                          ? const Color(0xFFA32D2D)
                          : const Color(0xFF0F6E56)),
                ),
                SizedBox(width: 6 * s),
                _chip(coupon.reward.title, AppTheme.onSurfaceVariant),
              ],
            ),
          ),
          SizedBox(height: 10 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            child: Row(
              children: [
                Container(
                  width: 14 * s,
                  height: 14 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.background,
                    border: Border.all(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                      width: 0.7,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: CustomPaint(painter: _DashedLinePainter()),
                  ),
                ),
                Container(
                  width: 14 * s,
                  height: 14 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.background,
                    border: Border.all(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
                      width: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 14 * s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COUPON CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10 * s,
                          letterSpacing: 1,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      Text(
                        coupon.code ?? 'NO-CODE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground.withValues(
                            alpha: isDisabled ? 0.45 : 1,
                          ),
                          decoration: isDisabled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        expiryText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11 * s,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10 * s),
                TextButton(
                  onPressed: isDisabled || (coupon.code == null)
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: coupon.code!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coupon code copied'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: isDisabled
                        ? AppTheme.background
                        : const Color(0xFF0F1923),
                    foregroundColor: isDisabled
                        ? AppTheme.onSurfaceVariant
                        : const Color(0xFF1DCE8A),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14 * s,
                      vertical: 10 * s,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                  ),
                  child: Text(
                    isDisabled ? '-' : 'Copy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10 * s,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _WalletMilestoneCard extends StatelessWidget {
  final ChallengeRewardsModel reward;
  final double s;

  const _WalletMilestoneCard({required this.reward, required this.s});

  @override
  Widget build(BuildContext context) {
    final primary = reward.theme.colors.primary;
    final pct = (reward.progressFraction * 100).clamp(0, 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 12 * s),
            child: Row(
              children: [
                Container(
                  width: 38 * s,
                  height: 38 * s,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9 * s),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: primary,
                    size: 20 * s,
                  ),
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.brandName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11 * s,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        reward.challengeTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.8,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.14),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 8 * s),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day ${reward.currentProgressDays} of ${reward.durationDays}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12 * s,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${reward.earnedCount}/${reward.totalMilestones} milestones earned',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5 * s,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7 * s),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6 * s,
                    backgroundColor: AppTheme.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1DCE8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 106 * s,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(14 * s, 4 * s, 14 * s, 14 * s),
              itemCount: reward.milestones.length,
              itemBuilder: (context, index) {
                final m = reward.milestones[index];
                return Container(
                  width: 96 * s,
                  margin: EdgeInsets.only(right: 10 * s),
                  padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 8 * s),
                  decoration: BoxDecoration(
                    color: m.isDone
                        ? const Color(0xFFE6FAF2)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12 * s),
                    border: Border.all(
                      color: m.isDone
                          ? const Color(0xFF1DCE8A)
                          : AppTheme.onSurfaceVariant.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (m.isDone)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 16 * s,
                            height: 16 * s,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DCE8A),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 10 * s,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _milestoneEmoji(index),
                            style: TextStyle(fontSize: 22 * s),
                          ),
                          SizedBox(height: 4 * s),
                          Text(
                            'Day ${m.dayTarget}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5 * s,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            m.rewards.isNotEmpty ? m.rewards.first.title : m.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5 * s,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onBackground,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _milestoneEmoji(int idx) {
    const icons = ['🌟', '🔥', '🏃', '🏆', '💧', '⚡', '🎯', '🥇'];
    return icons[idx % icons.length];
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD3DF)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const dash = 5.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      final end = (x + dash).clamp(0, size.width).toDouble();
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(end, size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
