import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../models/brand_challenge_models.dart';
import '../../../models/home_brand_section_model.dart';
import '../../../services/brand_challenge_service.dart';
import '../../home/widgets/home_brand_section.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../../shared/sticky_action_buttons.dart';
import 'brand_challenge_screen.dart';
import 'dart:math';

class BrandDiscoveryScreen extends StatefulWidget {
  const BrandDiscoveryScreen({super.key});

  @override
  State<BrandDiscoveryScreen> createState() => _BrandDiscoveryScreenState();
}

class _BrandDiscoveryScreenState extends State<BrandDiscoveryScreen>
    with TickerProviderStateMixin {
  late final BrandChallengeService _service;
  final ScrollController _scrollCtrl = ScrollController();

  List<DiscoveryChallengeModel> _allChallenges = [];
  List<DiscoveryChallengeModel> _filteredChallenges = [];
  List<HomeBrandCardModel> _myActiveChallengesList = [];
  List<BrandModel> _uniqueBrands = [];
  bool _isLoading = true;
  bool _isFilterLoading = false;
  String _activeFilter = 'all';

  static const _filters = [
    _FilterTab('my_active', 'My Active'),
    _FilterTab('all', 'All'),
    _FilterTab('fitness', 'Fitness'),
    _FilterTab('wellness', 'Wellness'),
    _FilterTab('growth', 'Growth'),
    _FilterTab('social', 'Social'),
  ];

  late AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _service = BrandChallengeService(supabaseClient: Supabase.instance.client);

    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    
    try {
      final responses = await Future.wait([
        _service.getActiveChallenges(),
        _service.getMyActiveChallenges(),
      ]);
      
      final results = responses[0] as List<DiscoveryChallengeModel>;
      final myChallenges = responses[1] as List<HomeBrandCardModel>;
      
      if (mounted) {
        final brands = <String, BrandModel>{};
        for (var c in results) {
          if (!brands.containsKey(c.brand.id)) {
            brands[c.brand.id] = c.brand;
          }
        }
  
        setState(() {
          _allChallenges = results;
          _filteredChallenges = results;
          _myActiveChallengesList = myChallenges;
          _uniqueBrands = brands.values.toList();
          _isLoading = false;
        });
        _heroAnim.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String key) {
    HapticFeedback.selectionClick();
    if (key == 'my_active') {
      setState(() => _activeFilter = key);
      return;
    }
    setState(() {
      _activeFilter = key;
      if (key == 'all') {
        _filteredChallenges = _allChallenges;
      } else {
        _filteredChallenges =
            _allChallenges.where((c) {
              final tagStr = c.tags.join(' ').toLowerCase();
              final searchableText =
                  '${c.title} ${c.brand.name} $tagStr'.toLowerCase();
              return searchableText.contains(key);
            }).toList();
      }
    });
  }


  String? _challengeIdForBrand(String brandId) {
    for (final challenge in _allChallenges) {
      if (challenge.brand.id == brandId) return challenge.id;
    }
    return null;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.background;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile =
            profileState is ProfileLoaded ? profileState.profile : null;
        final avatarUrl =
            profileState is ProfileLoaded ? profileState.displayUrl : null;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                if (profile != null)
                  StickyActionButtons(
                    spaceType: SpaceType.solo,
                    profile: profile,
                    displayUrl: avatarUrl,
                    scrollController: _scrollCtrl,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadChallenges,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    child: CustomScrollView(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        // ── Filter Chips ─────────────────────────────────────────
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _FilterHeaderDelegate(
                            child: _buildFilterRow(bgColor),
                            activeFilter: _activeFilter,
                          ),
                        ),

                        // ── Brands Strip ───────────────────────────────────────
                        if (_uniqueBrands.isNotEmpty && _activeFilter != 'my_active')
                          SliverToBoxAdapter(child: _buildBrandStrip()),

                        // ── Masonry Grid ────────────────────────────────────────
                        if (_isLoading || _isFilterLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          )
                        else if (_activeFilter == 'my_active' &&
                            _myActiveChallengesList.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState())
                        else if (_activeFilter != 'my_active' &&
                            _filteredChallenges.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState())
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            sliver: SliverList.builder(
                              itemCount:
                                  _activeFilter == 'my_active'
                                      ? _myActiveChallengesList.length
                                      : _filteredChallenges.length,
                              itemBuilder: (context, index) {
                                if (_activeFilter == 'my_active') {
                                  final card = _myActiveChallengesList[index];
                                  return RepaintBoundary(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: HomeBrandCard(
                                        card: card,
                                        snapLimit: 3, 
                                        isEnrolled: true,
                                        enrolledActionLabel: 'Go for it 🔥',
                                        onOpen: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BrandChallengeScreen(challengeId: card.challengeId),
                                            ),
                                          );
                                        },
                                      )
                                    ),
                                  );
                                } else {
                                  final challenge = _filteredChallenges[index];
                                  final int enrolledIdx = _myActiveChallengesList.indexWhere((m) => m.challengeId == challenge.id);
                                  final enrolledCard = enrolledIdx >= 0 ? _myActiveChallengesList[enrolledIdx] : null;

                                  if (enrolledCard != null) {
                                    return RepaintBoundary(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 24),
                                        child: HomeBrandCard(
                                          card: enrolledCard,
                                          snapLimit: 3,
                                          isEnrolled: true,
                                          enrolledActionLabel: 'Go for it 🔥',
                                          onOpen: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => BrandChallengeScreen(challengeId: enrolledCard.challengeId),
                                              ),
                                            );
                                          },
                                        )
                                      ),
                                    );
                                  } else {
                                    return RepaintBoundary(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 24),
                                        child: _BrandFeedCard(
                                          challenge: challenge,
                                          index: index,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Filter Row (High-End Neon Pills) ──────────────────────────────────
  Widget _buildFilterRow(Color bgColor) {
    if (_filters.isEmpty) return const SizedBox.shrink();
    // "My Active" is pinned left alongside the divider, rest scroll
    final myActiveFilter = _filters.first; // 'my_active'
    final allFilter = _filters[1]; // 'all'
    final otherFilters = _filters.sublist(2);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildFilterPill(
              myActiveFilter,
              _activeFilter == myActiveFilter.key,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(width: 7),
            _buildFilterPill(allFilter, _activeFilter == allFilter.key),

            // Subtle vertical divider to separate fixed vs scrolling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 1,
                height: 14,
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),

            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: otherFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filter = otherFilters[i];
                  return _buildFilterPill(filter, _activeFilter == filter.key);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    _FilterTab filter,
    bool isSelected, {
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () => _applyFilter(filter.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : Colors.black45,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              filter.label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Brands Scroll Strip (Glowing Story Rings) ──────────────────────────
  Widget _buildBrandStrip() {
    final s = Responsive.scale(context);
    return Container(
      height: 90 * s,
      margin: EdgeInsets.only(top: 8 * s, bottom: 8 * s),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        itemCount: _uniqueBrands.length,
        itemBuilder: (context, i) {
          final brand = _uniqueBrands[i];
          final hasLogo = brand.logoUrl != null && brand.logoUrl!.isNotEmpty;
          final challengeId = _challengeIdForBrand(brand.id);
          return Padding(
            padding: EdgeInsets.only(right: 18 * s),
            child: GestureDetector(
              onTap:
                  challengeId == null
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BrandChallengeScreen(
                                  challengeId: challengeId,
                                ),
                          ),
                        );
                      },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54 * s,
                    height: 54 * s,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C0C0F), // Dark base so text stands out
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        hasLogo
                            ? Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(8 * s),
                              child: CachedNetworkImage(
                                imageUrl: brand.logoUrl!,
                                fit: BoxFit.contain,
                                errorWidget:
                                    (_, __, ___) => Container(
                                      color: const Color(0xFF0C0C0F),
                                      child: _buildTextLogo(brand.name, s),
                                    ),
                              ),
                            )
                            : _buildTextLogo(brand.name, s),
                  ),
                  SizedBox(height: 10 * s),
                  SizedBox(
                    width: 64 * s,
                    child: Text(
                      brand.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9 * s,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextLogo(String name, double s) {
    return Center(
      child: Text(
        name.substring(0, min(2, name.length)).toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18 * s,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isMyActive = _activeFilter == 'my_active';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMyActive ? Icons.bolt_rounded : Icons.auto_awesome_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isMyActive ? 'No active challenges' : 'No challenges found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMyActive
                ? 'Join a challenge below to get started!'
                : 'Check back later or try a different filter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models & Delegates ─────────────────────────────────────────────────
class _FilterTab {
  final String key;
  final String label;
  const _FilterTab(this.key, this.label);
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final String activeFilter;
  static const double _height = 60.0;

  const _FilterHeaderDelegate({
    required this.child,
    required this.activeFilter,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => _height;
  @override
  double get minExtent => _height;
  @override
  bool shouldRebuild(_FilterHeaderDelegate old) =>
      activeFilter != old.activeFilter;
}

// ═══════════════════════════════════════════════════════════════════════════════
// BRAND FEED CARD — Gen Z Editorial Immersive Design
// ═══════════════════════════════════════════════════════════════════════════════
class _BrandFeedCard extends StatefulWidget {
  final DiscoveryChallengeModel challenge;
  final int index;

  const _BrandFeedCard({required this.challenge, required this.index});

  @override
  State<_BrandFeedCard> createState() => _BrandFeedCardState();
}

class _BrandFeedCardState extends State<_BrandFeedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeSlide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeSlide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: 70 * widget.index.clamp(0, 5)), () {
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
    final challenge = widget.challenge;
    final brandTheme = challenge.brand.parsedTheme;
    Color rawAccent = brandTheme.colors.accent;

    // Ensure the accent color is dark enough to be highly legible on light cards
    if (rawAccent.computeLuminance() > 0.7) {
      final hsl = HSLColor.fromColor(rawAccent);
      rawAccent =
          hsl.withLightness((hsl.lightness - 0.3).clamp(0.2, 1.0)).toColor();
    }

    // Billion-dollar apps never use pure primary/accent if it crashes contrast.
    final accentColor = rawAccent;

    // Determine title rendering logic: dynamic via segments, or fallback static split
    List<InlineSpan> titleSpans = [];
    if (challenge.titleSegments.isNotEmpty) {
      for (final segment in challenge.titleSegments) {
        titleSpans.add(
          TextSpan(
            text: segment.text,
            style: TextStyle(
              color: segment.highlight ? accentColor : const Color(0xFF111111),
            ),
          ),
        );
      }
    } else {
      // Fallback: Split title, last word gets accent color
      final titleWords = challenge.title.trim().split(' ');
      final titleBody =
          titleWords.length > 1
              ? titleWords.sublist(0, titleWords.length - 1).join(' ')
              : '';
      final titleAccent = titleWords.last;

      if (titleBody.isNotEmpty) {
        titleSpans.add(TextSpan(text: '$titleBody '));
      }
      titleSpans.add(
        TextSpan(text: titleAccent, style: TextStyle(color: accentColor)),
      );
    }

    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        BrandChallengeScreen(challengeId: challenge.id),
              ),
            );
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.975 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: challenge.brand.parsedTheme.colors.primary
                        .withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ══════════════════════════════════════════════
                    // HERO BANNER
                    // ══════════════════════════════════════════════
                    if (challenge.bannerUrl != null &&
                        challenge.bannerUrl!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 160 * s,
                        child: CachedNetworkImage(
                          imageUrl: challenge.bannerUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),

                    // ══════════════════════════════════════════════
                    // TYPOGRAPHY HEADER
                    // ══════════════════════════════════════════════
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top badges row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Live indicator
                              Row(
                                children: [
                                  Container(
                                    width: 6 * s,
                                    height: 6 * s,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 5 * s),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9 * s,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF111111),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Category badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * s,
                                  vertical: 4 * s,
                                ),
                                decoration: BoxDecoration(
                                  color: challenge
                                      .brand
                                      .parsedTheme
                                      .colors
                                      .primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${challenge.durationDays}D CHALLENGE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9 * s,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        challenge
                                            .brand
                                            .parsedTheme
                                            .colors
                                            .primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16 * s),
                          // Brand name row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (challenge.brand.logoUrl != null &&
                                  challenge.brand.logoUrl!.isNotEmpty) ...[
                                Container(
                                  width: 14 * s,
                                  height: 14 * s,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    imageUrl: challenge.brand.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorWidget:
                                        (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                                SizedBox(width: 5 * s),
                              ],
                              Flexible(
                                child: Text(
                                  challenge.brand.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: 1.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (challenge.brand.isVerified) ...[
                                SizedBox(width: 4 * s),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 11 * s,
                                  color: const Color(
                                    0xFF007AFF,
                                  ), // Apple official verified blue
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4 * s),
                          // Challenge title
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20 * s,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF111111),
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                              children: titleSpans,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ══════════════════════════════════════════════
                    // BODY — reward pills + footer
                    // ══════════════════════════════════════════════
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 12 * s,
                            color: Colors.black45,
                          ),
                          SizedBox(width: 5 * s),
                          Text(
                            challenge.formattedEnrolledCount.isNotEmpty
                                ? '${challenge.formattedEnrolledCount} joined'
                                : 'Be first to join',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10 * s,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10 * s),

                    // Reward pills scroll
                    SizedBox(
                      height: 36 * s,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16 * s),
                        clipBehavior: Clip.none,
                        children:
                            challenge.featuredRewards.isNotEmpty
                                ? challenge.featuredRewards.asMap().entries.map(
                                  (entry) {
                                    final idx = entry.key;
                                    final reward = entry.value;
                                    final isHighlighted =
                                        idx ==
                                        challenge.featuredRewards.length - 1;
                                    return Padding(
                                      padding: EdgeInsets.only(right: 8 * s),
                                      child: _buildCompactRewardPill(
                                        s,
                                        reward.milestoneLabel.isNotEmpty
                                            ? reward.milestoneLabel
                                            : 'Day ${(idx + 1) * 7}',
                                        reward.title,
                                        isHighlighted,
                                        accentColor,
                                        imageUrl: reward.imageUrl,
                                      ),
                                    );
                                  },
                                ).toList()
                                : [
                                  _buildCompactRewardPill(
                                    s,
                                    'Day 7',
                                    'Starter Gift',
                                    false,
                                    accentColor,
                                  ),
                                  SizedBox(width: 8 * s),
                                  _buildCompactRewardPill(
                                    s,
                                    'Day 14',
                                    'Epic Drop',
                                    true,
                                    accentColor,
                                  ),
                                  SizedBox(width: 8 * s),
                                  _buildCompactRewardPill(
                                    s,
                                    'Day 21+',
                                    'Legend Prize',
                                    false,
                                    accentColor,
                                  ),
                                ],
                      ),
                    ),

                    SizedBox(height: 14 * s),

                    // ══════════════════════════════════════════════
                    // FOOTER — reward pool + gradient launch strip
                    // ══════════════════════════════════════════════
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
                      child: Row(
                        children: [
                          // Reward pool chip (Unified with Brand Accent)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * s,
                                vertical: 8 * s,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12 * s),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12 * s,
                                    color: accentColor,
                                  ),
                                  SizedBox(width: 6 * s),
                                  Flexible(
                                    child: Text(
                                      challenge.rewardPoolText.isNotEmpty
                                          ? challenge.rewardPoolText
                                          : '10K+ Pool',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11 * s,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
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

                          // Ultra-premium simple button (Gen-Z minimal)
                          Container(
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * s,
                              vertical: 9 * s,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12 * s,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6 * s),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 13 * s,
                                ),
                              ],
                            ),
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

  Widget _buildCompactRewardPill(
    double s,
    String label,
    String reward,
    bool active,
    Color accentColor, {
    String? imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color:
            active
                ? accentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              active
                  ? accentColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              width: 14 * s,
              height: 14 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Text(
              active ? '✦' : '✧',
              style: TextStyle(
                fontSize: 10 * s,
                color: active ? accentColor : Colors.black45,
              ),
            ),
          SizedBox(width: 5 * s),
          Text(
            reward,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5 * s,
              fontWeight: FontWeight.w700,
              color: active ? accentColor : Colors.black87,
            ),
          ),
          SizedBox(width: 6 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color:
                  active
                      ? accentColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5 * s,
                fontWeight: FontWeight.w800,
                color: active ? accentColor : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
