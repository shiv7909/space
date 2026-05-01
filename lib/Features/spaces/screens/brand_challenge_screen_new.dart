// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/utils/responsive_helpers.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../models/brand_challenge_models.dart';
// import '../../../models/brand_theme_data.dart';
// import '../../snaps/cubit/snap_cubit.dart';
// import '../../../services/brand_challenge_service.dart';
// import '../../../services/snap_service.dart';
// import '../cubits/brand_challenge_cubit.dart';
// import '../cubits/brand_challenge_state.dart';

// // Import extracted components
// import '../widgets/brand_challenge/challenge_app_bar.dart';
// import '../widgets/brand_challenge/challenge_hero.dart';
// import '../widgets/brand_challenge/challenge_stats.dart';
// import '../widgets/brand_challenge/challenge_pulse.dart';
// import '../widgets/brand_challenge/challenge_snaps.dart';
// import '../widgets/brand_challenge/challenge_journey.dart';
// import '../widgets/brand_challenge/challenge_product.dart';
// import '../widgets/brand_challenge/challenge_rewards.dart';
// import '../widgets/brand_challenge/challenge_join_cta.dart';
// import '../widgets/brand_challenge/challenge_helpers.dart';

// class BrandChallengeScreen extends StatelessWidget {
//   final String challengeId;
//   const BrandChallengeScreen({super.key, required this.challengeId});

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create: (_) => BrandChallengeCubit(BrandChallengeService(supabaseClient: Supabase.instance.client))..loadChallenge(challengeId),
//         ),
//         BlocProvider(
//           create: (_) => SnapCubit(SnapService(supabaseClient: Supabase.instance.client), userId: currentUserId),
//         ),
//       ],
//       child: _BrandChallengeView(challengeId: challengeId),
//     );
//   }
// }

// class _BrandChallengeView extends StatefulWidget {
//   final String challengeId;
//   const _BrandChallengeView({required this.challengeId});

//   @override
//   State<_BrandChallengeView> createState() => _BrandChallengeViewState();
// }

// class _BrandChallengeViewState extends State<_BrandChallengeView> {
//   late final ScrollController _scrollController;
//   final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     _scrollController.addListener(() {
//       _scrollOffset.value = _scrollController.offset;
//     });
//   }

//   @override
//   void dispose() {
//     _scrollOffset.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<BrandChallengeCubit, BrandChallengeState>(
//       builder: (context, state) {
//         if (state is BrandChallengeLoading || state is BrandChallengeInitial) return _buildLoading();
//         if (state is BrandChallengeError) return _buildError(state.message);
        
//         if (state is BrandChallengeAboveFoldLoaded) {
//           return _buildScreen(context, header: state.header, journey: state.journey, pulse: null, stories: ChallengeStoriesResponse.empty, products: [], coupons: [], isLoadingBelowFold: true);
//         }

//         if (state is BrandChallengeFullyLoaded) {
//           return _buildScreen(context, header: state.header, journey: state.journey, pulse: state.pulse, stories: state.stories, products: state.products, coupons: state.coupons, isLoadingBelowFold: false, isSendingSnap: state.isSendingSnap);
//         }

//         return _buildLoading();
//       },
//     );
//   }

//   Widget _buildLoading() => Scaffold(backgroundColor: AppTheme.background, body: const Center(child: CupertinoActivityIndicator()));

//   Widget _buildError(String message) {
//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.onSurfaceVariant),
//               const SizedBox(height: 16),
//               Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onBackground)),
//               const SizedBox(height: 20),
//               ElevatedButton(onPressed: () => context.read<BrandChallengeCubit>().loadChallenge(widget.challengeId), child: const Text('Retry')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildScreen(BuildContext context, {required ChallengeHeaderModel header, required ChallengeJourneyModel journey, required PulsePostModel? pulse, required ChallengeStoriesResponse stories, required List<BrandProductModel> products, required List<ChallengeCouponModel> coupons, required bool isLoadingBelowFold, bool isSendingSnap = false}) {
//     final s = Responsive.scale(context);
//     final theme = header.brand.parsedTheme;
//     final brandTyp = theme.typography;
//     final brandC = theme.colors;

//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       body: Stack(
//         children: [
//           RefreshIndicator(
//             onRefresh: () => context.read<BrandChallengeCubit>().refresh(widget.challengeId),
//             color: brandC.primary,
//             child: CustomScrollView(
//               controller: _scrollController,
//               physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
//               slivers: [
//                 ChallengeAppBar(header: header, theme: theme, brandTyp: brandTyp, s: s, scrollOffset: _scrollOffset),
//                 SliverToBoxAdapter(child: ChallengeHeroSection(header: header, theme: theme, s: s, topOffset: (64 * s) + MediaQuery.paddingOf(context).top)),
                
//                 // Expandable Description below Hero (Above Stats)
//                 if (header.descriptionSegments.isNotEmpty)
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(18 * s, 22 * s, 18 * s, 0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           buildSectionLabel('ABOUT THIS CHALLENGE', s),
//                           SizedBox(height: 12 * s),
//                           GlobalExpandableDescription(segments: header.descriptionSegments, theme: theme, scale: s),
//                           SizedBox(height: 24 * s),
//                         ],
//                       ),
//                     ),
//                   ),

//                 SliverToBoxAdapter(child: ChallengeStatsStrip(stats: header.stats, theme: theme, s: s)),
                
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: EdgeInsets.fromLTRB(18 * s, 22 * s, 18 * s, 0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (pulse != null) ...[ChallengePulseSection(post: pulse, brand: header.brand, theme: theme, s: s), SizedBox(height: 24 * s)],
//                         ChallengeSnapsSection(stories: stories, theme: theme, s: s, isSendingSnap: isSendingSnap, challengeId: widget.challengeId),
//                         SizedBox(height: 24 * s),
//                         ChallengeEnergyBar(energy: journey.energy, theme: theme, s: s),
//                         SizedBox(height: 24 * s),
//                         ChallengeJourneySection(challengeId: widget.challengeId, journey: journey, theme: theme, s: s),
//                         SizedBox(height: 24 * s),
//                         if (products.isNotEmpty) ...[ChallengeProductCard(product: products.first, theme: theme, s: s), SizedBox(height: 24 * s)],
//                         ChallengeRewardsRow(milestones: journey.milestones, theme: theme, s: s),
//                         SizedBox(height: 24 * s),
//                         if (coupons.isNotEmpty) ...[ChallengeEarnedCoupons(coupons: coupons, theme: theme, s: s), SizedBox(height: 24 * s)],
//                         if (isLoadingBelowFold) ...[const Center(child: CupertinoActivityIndicator()), SizedBox(height: 24 * s)],
//                         SizedBox(height: header.isEnrolled ? 32 * s : 140 * s),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (!header.isEnrolled) JoinCtaPanel(accent: brandC.accent, enrolled: header.stats.formattedEnrolled, daysLeft: header.stats.daysLeft, s: s, onJoin: () => context.read<BrandChallengeCubit>().enrollInChallenge(widget.challengeId)),
//         ],
//       ),
//     );
//   }
// }

// // Relocating the newly requested custom ExpandableDescription with shadowed cutoff.
// class GlobalExpandableDescription extends StatefulWidget {
//   final List<TextSegment> segments;
//   final BrandThemeData theme;
//   final double scale;

//   const GlobalExpandableDescription({super.key, required this.segments, required this.theme, required this.scale});

//   @override
//   State<GlobalExpandableDescription> createState() => _GlobalExpandableDescriptionState();
// }

// class _GlobalExpandableDescriptionState extends State<GlobalExpandableDescription> {
//   bool _isExpanded = false;

//   @override
//   Widget build(BuildContext context) {
//     final c = widget.theme.colors;
//     final t = widget.theme.typography;
//     final s = widget.scale;
//     final fullText = widget.segments.map((seg) => seg.text).join();
//     final halfLength = (fullText.length / 2).round();
//     final displayText = _isExpanded ? fullText : fullText.substring(0, halfLength);
//     final textSpans = <TextSpan>[];
//     int currentIndex = 0;

//     for (final seg in widget.segments) {
//       if (currentIndex >= displayText.length) break;
//       final segText = seg.text;
//       final remainingLength = displayText.length - currentIndex;
//       final visibleSegText = segText.length <= remainingLength ? segText : segText.substring(0, remainingLength);

//       if (visibleSegText.isNotEmpty) {
//         textSpans.add(TextSpan(text: visibleSegText, style: TextStyle(color: seg.highlight ? c.accent : c.textSecondary)));
//       }
//       currentIndex += segText.length;
//       if (currentIndex >= displayText.length) break;
//     }

//     if (!_isExpanded && fullText.length > halfLength) {
//       textSpans.add(const TextSpan(text: '...'));
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             boxShadow: [
//               BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4 * s, offset: Offset(0, 2 * s)),
//             ],
//           ),
//           child: RichText(
//             text: TextSpan(
//               style: t.bodyStyle(size: 14 * s, weight: FontWeight.w500, color: c.textSecondary, height: 1.5),
//               children: textSpans,
//             ),
//           ),
//         ),
//         if (fullText.length > halfLength) ...[
//           SizedBox(height: 8 * s),
//           GestureDetector(
//             onTap: () => setState(() => _isExpanded = !_isExpanded),
//             child: Text(_isExpanded ? 'Show less' : 'Show more', style: t.bodyStyle(size: 12 * s, weight: FontWeight.w700, color: c.accent)),
//           ),
//         ],
//       ],
//     );
//   }
// }
