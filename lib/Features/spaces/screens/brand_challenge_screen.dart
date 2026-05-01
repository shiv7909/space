import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/brand_challenge_models.dart';
import '../../../models/brand_theme_data.dart';
import '../../snaps/cubit/snap_cubit.dart';
import '../../../services/brand_challenge_service.dart';
import '../../../services/snap_service.dart';
import '../cubits/brand_challenge_cubit.dart';
import '../cubits/brand_challenge_state.dart';

// Import extracted components
import '../widgets/brand_challenge/challenge_app_bar.dart';
import '../widgets/brand_challenge/challenge_hero.dart';
import '../widgets/brand_challenge/challenge_stats.dart';
import '../widgets/brand_challenge/challenge_pulse.dart';
import '../widgets/brand_challenge/challenge_snaps.dart';
import '../widgets/brand_challenge/challenge_journey.dart';
import '../widgets/brand_challenge/challenge_product.dart';
import '../widgets/brand_challenge/challenge_rewards.dart';
import '../widgets/brand_challenge/challenge_join_cta.dart';
import '../widgets/brand_challenge/challenge_helpers.dart';

class BrandChallengeScreen extends StatelessWidget {
  final String challengeId;
  const BrandChallengeScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BrandChallengeCubit(BrandChallengeService(supabaseClient: Supabase.instance.client))..loadChallenge(challengeId),
        ),
        BlocProvider(
          create: (_) => SnapCubit(SnapService(supabaseClient: Supabase.instance.client), userId: currentUserId),
        ),
      ],
      child: _BrandChallengeView(challengeId: challengeId),
    );
  }
}

class _BrandChallengePageShimmer extends StatelessWidget {
  final double s;
  const _BrandChallengePageShimmer({required this.s});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F1F4),
      highlightColor: const Color(0xFFF8F9FB),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, topPad + 12 * s, 16 * s, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ShimmerBlock(width: 40 * s, height: 40 * s, radius: 12 * s),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ShimmerBlock(width: 120 * s, height: 12 * s, radius: 6 * s),
                                SizedBox(height: 8 * s),
                                _ShimmerBlock(width: 170 * s, height: 18 * s, radius: 8 * s),
                              ],
                            ),
                          ),
                          _ShimmerBlock(width: 40 * s, height: 40 * s, radius: 12 * s),
                        ],
                      ),
                      SizedBox(height: 16 * s),
                      _ShimmerBlock(width: double.infinity, height: 224 * s, radius: 28 * s),
                      SizedBox(height: 12 * s),
                      _ShimmerBlock(width: double.infinity, height: 44 * s, radius: 12 * s),
                      SizedBox(height: 12 * s),
                      Row(
                        children: [
                          Expanded(child: _ShimmerBlock(width: double.infinity, height: 68 * s, radius: 16 * s)),
                          SizedBox(width: 10 * s),
                          Expanded(child: _ShimmerBlock(width: double.infinity, height: 68 * s, radius: 16 * s)),
                          SizedBox(width: 10 * s),
                          Expanded(child: _ShimmerBlock(width: double.infinity, height: 68 * s, radius: 16 * s)),
                        ],
                      ),
                      SizedBox(height: 18 * s),
                      _BrandChallengeBelowFoldShimmer(s: s),
                      SizedBox(height: 160 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, MediaQuery.paddingOf(context).bottom + 14 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBlock(width: 120 * s, height: 10 * s, radius: 6 * s),
                        SizedBox(height: 8 * s),
                        _ShimmerBlock(width: 170 * s, height: 16 * s, radius: 8 * s),
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  _ShimmerBlock(width: 112 * s, height: 42 * s, radius: 12 * s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandChallengeBelowFoldShimmer extends StatelessWidget {
  final double s;
  const _BrandChallengeBelowFoldShimmer({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBlock(width: 130 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 154 * s, radius: 20 * s),
        SizedBox(height: 24 * s),
        _ShimmerBlock(width: 110 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 132 * s, radius: 20 * s),
        SizedBox(height: 24 * s),
        _ShimmerBlock(width: 150 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 14 * s, radius: 7 * s),
        SizedBox(height: 20 * s),
        _ShimmerBlock(width: 120 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 174 * s, radius: 20 * s),
        SizedBox(height: 24 * s),
        _ShimmerBlock(width: 100 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 134 * s, radius: 20 * s),
        SizedBox(height: 24 * s),
        _ShimmerBlock(width: 118 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        Row(
          children: [
            Expanded(child: _ShimmerBlock(width: double.infinity, height: 88 * s, radius: 16 * s)),
            SizedBox(width: 10 * s),
            Expanded(child: _ShimmerBlock(width: double.infinity, height: 88 * s, radius: 16 * s)),
            SizedBox(width: 10 * s),
            Expanded(child: _ShimmerBlock(width: double.infinity, height: 88 * s, radius: 16 * s)),
          ],
        ),
        SizedBox(height: 24 * s),
        _ShimmerBlock(width: 124 * s, height: 10 * s, radius: 6 * s),
        SizedBox(height: 10 * s),
        _ShimmerBlock(width: double.infinity, height: 122 * s, radius: 20 * s),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _BrandChallengeView extends StatefulWidget {
  final String challengeId;
  const _BrandChallengeView({required this.challengeId});

  @override
  State<_BrandChallengeView> createState() => _BrandChallengeViewState();
}

class _BrandChallengeViewState extends State<_BrandChallengeView> {
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandChallengeCubit, BrandChallengeState>(
      builder: (context, state) {
        if (state is BrandChallengeLoading || state is BrandChallengeInitial) return _buildLoading();
        if (state is BrandChallengeError) return _buildError(state.message);

        if (state is BrandChallengeAboveFoldLoaded) {
          return _buildScreen(context, header: state.header, journey: state.journey, pulse: null, stories: ChallengeStoriesResponse.empty, products: [], coupons: [], isLoadingBelowFold: true, isActiveMember: state.isActiveMember, exitedDaysCompleted: state.exitedDaysCompleted, exitedRewardsUnlocked: state.exitedRewardsUnlocked);
        }

        if (state is BrandChallengeFullyLoaded) {
          return _buildScreen(context, header: state.header, journey: state.journey, pulse: state.pulse, stories: state.stories, products: state.products, coupons: state.coupons, isLoadingBelowFold: false, isSendingSnap: state.isSendingSnap, isActiveMember: state.isActiveMember, exitedDaysCompleted: state.exitedDaysCompleted, exitedRewardsUnlocked: state.exitedRewardsUnlocked);
        }

        return _buildLoading();
      },
    );
  }

  Widget _buildLoading() => Scaffold(
    backgroundColor: AppTheme.background,
    body: _BrandChallengePageShimmer(s: Responsive.scale(context)),
  );

  Widget _buildError(String message) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onBackground)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => context.read<BrandChallengeCubit>().loadChallenge(widget.challengeId), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, {required ChallengeHeaderModel header, required ChallengeJourneyModel journey, required PulsePostModel? pulse, required ChallengeStoriesResponse stories, required List<BrandProductModel> products, required List<ChallengeCouponModel> coupons, required bool isLoadingBelowFold, bool isSendingSnap = false, bool isActiveMember = true, int exitedDaysCompleted = 0, int exitedRewardsUnlocked = 0}) {
    final s = Responsive.scale(context);
    final theme = header.brand.parsedTheme;
    final brandTyp = theme.typography;
    final brandC = theme.colors;
    final hasChallengeDescription =
        header.descriptionSegments.isNotEmpty ||
        (header.challengeDescription?.trim().isNotEmpty == true);
    final hasWebsite = header.brand.websiteUrl?.trim().isNotEmpty == true;
    final showAboutCard = hasChallengeDescription || hasWebsite;
    final hasJoinCta = !header.isEnrolled;
    final exitedResumeMessage = hasJoinCta && !isActiveMember
      ? 'You joined before and exited. Wanna resume and earn rewards?'
      : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => context.read<BrandChallengeCubit>().refresh(widget.challengeId),
            color: brandC.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                ChallengeAppBar(
                  header: header,
                  theme: theme,
                  brandTyp: brandTyp,
                  s: s,
                  scrollOffset: _scrollOffset,
                  onShareTap: () => _shareChallenge(header, journey),
                ),
                SliverToBoxAdapter(child: ChallengeHeroSection(header: header, theme: theme, s: s, topOffset: (64 * s) + MediaQuery.paddingOf(context).top)),

                if (showAboutCard)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 0),
                      child: GestureDetector(
                        onTap: () => _showAboutChallengeSheet(context, header, theme, s),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(10 * s, 11 * s, 10 * s, 11 * s),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colors.surface,
                                theme.colors.surface.withValues(alpha: 0.94),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14 * s),
                            border: Border.all(
                              color: theme.colors.border.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 14 * s,
                                offset: Offset(0, 4 * s),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(child: buildSectionLabel('ABOUT THIS CHALLENGE', s)),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: theme.colors.textSecondary,
                                size: 19 * s,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: ChallengeStatsStrip(stats: header.stats, theme: theme, s: s)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18 * s, 10 * s, 18 * s, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!header.isEnrolled) ...[
                          ChallengeRewardsRow(milestones: journey.milestones, theme: theme, s: s),
                          SizedBox(height: 24 * s),
                        ],
                        if (pulse != null) ...[ChallengePulseSection(post: pulse, brand: header.brand, theme: theme, s: s), SizedBox(height: 24 * s)],
                        ChallengeSnapsSection(
                          stories: stories,
                          energy: journey.energy,
                          theme: theme,
                          s: s,
                          isSendingSnap: isSendingSnap,
                          challengeId: widget.challengeId,
                          isEnrolled: header.isEnrolled,
                          activeUsersToday: header.stats.activeUsersToday,
                          enrolledCountLabel: header.stats.formattedEnrolled,
                        ),
                        SizedBox(height: 24 * s),
                        ChallengeJourneySection(challengeId: widget.challengeId, journey: journey, theme: theme, s: s, canMarkDone: header.isEnrolled && isActiveMember),
                        SizedBox(height: 24 * s),
                        if (products.isNotEmpty) ...[ChallengeProductCard(product: products.first, theme: theme, s: s), SizedBox(height: 24 * s)],
                        if (header.isEnrolled) ...[
                          ChallengeRewardsRow(milestones: journey.milestones, theme: theme, s: s),
                          SizedBox(height: 8 * s),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _confirmExitChallenge(context, theme, s),
                              icon: Icon(
                                Icons.exit_to_app_rounded,
                                size: 14 * s,
                                color: const Color(0xFFD32F2F),
                              ),
                              label: Text(
                                'Exit Challenge',
                                style: TextStyle(
                                  fontSize: 11.5 * s,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 6 * s),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                          SizedBox(height: 24 * s),
                        ],
                        if (coupons.isNotEmpty) ...[ChallengeEarnedCoupons(coupons: coupons, theme: theme, s: s), SizedBox(height: 24 * s)],
                        if (isLoadingBelowFold) ...[
                          _BrandChallengeBelowFoldShimmer(s: s),
                          SizedBox(height: 24 * s),
                        ],
                        SizedBox(height: header.isEnrolled ? 32 * s : 140 * s),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasJoinCta)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: JoinCtaPanel(
                accent: brandC.accent,
                enrolled: header.stats.formattedEnrolled,
                daysLeft: header.stats.daysLeft,
                s: s,
                topMessage: exitedResumeMessage,
                onJoin: () => context.read<BrandChallengeCubit>().enrollInChallenge(widget.challengeId),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareChallenge(
    ChallengeHeaderModel header,
    ChallengeJourneyModel journey,
  ) async {
    try {
      final rewardCount = journey.milestones
          .expand((m) => m.rewards)
          .length;
      final rewardSummary = header.rewardPoolText.trim().isNotEmpty
          ? header.rewardPoolText.trim()
          : '$rewardCount rewards in this challenge';
      final lines = <String>[
        'Challenge: ${header.title}',
        'Brand: ${header.brand.name}',
        'Stats: ${header.stats.daysLeft} days left • ${header.stats.formattedEnrolled} members • ${header.stats.formattedCompletion} completion',
        'Rewards: $rewardSummary',
        '',
        'Download Habitz: https://habitz.app/download',
      ];

      final logoBytes = await _downloadImageBytes(header.brand.logoUrl);
      if (logoBytes != null) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              logoBytes,
              name: 'habitz_brand_${header.brand.id}.png',
              mimeType: 'image/png',
            ),
          ],
          text: lines.join('\n'),
        );
      } else {
        await Share.share(lines.join('\n'));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share challenge right now: $e')),
      );
    }
  }

  Future<Uint8List?> _downloadImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return await consolidateHttpClientResponseBytes(response);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _confirmExitChallenge(
    BuildContext context,
    BrandThemeData theme,
    double s,
  ) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * s),
          ),
          title: const Text('Exit challenge?'),
          content: const Text(
            'Your challenge progress, rewards, and coupons for this challenge will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (shouldExit != true || !mounted) return;

    final result = await context.read<BrandChallengeCubit>().exitChallenge(widget.challengeId);
    if (!mounted) return;

    final success = result['success'] == true;
    final message = (result['message'] as String?)?.trim();
    final error = (result['error'] as String?)?.trim();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You exited this challenge.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message?.isNotEmpty == true
              ? message!
              : error?.isNotEmpty == true
              ? error!
              : 'Could not exit challenge right now.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutChallengeSheet(
    BuildContext context,
    ChallengeHeaderModel header,
    BrandThemeData theme,
    double s,
  ) {
    final segmentText = header.descriptionSegments.map((seg) => seg.text).join().trim();
    final fullText = segmentText.isNotEmpty
        ? segmentText
        : (header.challengeDescription?.trim().isNotEmpty == true
            ? header.challengeDescription!.trim()
            : 'No description available yet.');
    final website = header.brand.websiteUrl?.trim();
    final hasWebsite = website != null && website.isNotEmpty;
    final t = theme.typography;
    final c = theme.colors;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20 * s, 14 * s, 20 * s, 20 * s + MediaQuery.paddingOf(sheetCtx).bottom),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20 * s)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38 * s,
                  height: 4 * s,
                  decoration: BoxDecoration(
                    color: c.border.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: 14 * s),
              buildSectionLabel('ABOUT THIS CHALLENGE', s),
              SizedBox(height: 10 * s),
              Text(
                fullText,
                style: t.bodyStyle(
                  size: 13 * s,
                  weight: FontWeight.w500,
                  color: AppTheme.onBackground.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
              if (hasWebsite) ...[
                SizedBox(height: 14 * s),
                GestureDetector(
                  onTap: () async {
                    final raw = website;
                    final normalized = raw.startsWith('http://') || raw.startsWith('https://')
                        ? raw
                        : 'https://$raw';
                    final uri = Uri.tryParse(normalized);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 16 * s,
                        color: theme.colors.primary,
                      ),
                      SizedBox(width: 7 * s),
                      Expanded(
                        child: Text(
                          website,
                          style: t.bodyStyle(
                            size: 12.5 * s,
                            weight: FontWeight.w700,
                            color: theme.colors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
