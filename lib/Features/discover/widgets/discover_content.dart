import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../couple/cubit/spaces_cubit.dart';
import '../../couple/cubit/spaces_state.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../../shared/sticky_action_buttons.dart';
import '../cubit/discover_cubit.dart';
import '../cubit/discover_state.dart';
import '../models/discover_models.dart';
import 'discover_search_bar.dart';
import 'discover_filter_tabs.dart';

import 'feed_header.dart';
import 'space_card.dart';
import 'discover_empty_state.dart';

/// Embeddable Discover content widget — designed to live inside
/// a parent IndexedStack (HomeScreen). The cubit is owned by
/// HomeScreen so it survives tab switches — data loads once only.
class DiscoverContent extends StatefulWidget {
  final DiscoverCubit cubit;
  final Position? position;

  /// If true, returns a list of slivers (not wrapped in SliverMainAxisGroup)
  /// so they can be injected directly into parent CustomScrollView.
  /// This fixes the sticky header pinning bug.
  final bool isEmbedded;

  /// If false, hides Search, Filters, and the main Feed, showing only Trending & People.
  final bool showSearchAndFeed;

  const DiscoverContent({
    super.key,
    required this.cubit,
    required this.position,
    this.isEmbedded = false,
    this.showSearchAndFeed = true,
  });

  @override
  State<DiscoverContent> createState() => _DiscoverContentState();
}

class _DiscoverContentState extends State<DiscoverContent>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  late ScrollController _scrollController;

  // position is now passed in — no need to re-fetch
  Position? get _position => widget.position;

  late SpacesCubit spacesCubit;

  static const _filters = [
    FilterTabItem(key: 'all', label: 'All'),
    FilterTabItem(
      key: 'nearby',
      label: 'Nearby',
      icon: Icons.location_on_rounded,
    ),
    FilterTabItem(
      key: 'trending',
      label: 'Trending',
      icon: Icons.local_fire_department_rounded,
    ),
    FilterTabItem(key: 'crews', label: 'Crews', icon: Icons.groups_rounded),
    FilterTabItem(
      key: 'challenges',
      label: 'Challenges',
      icon: Icons.flag_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFilterChange(String filter) {
    // ✅ NO scroll save/restore — that was causing the flicker/jump
    widget.cubit.setFilter(filter, _position);
  }

  void _loadMoreIfNeeded() {
    final state = widget.cubit.state;
    if (!state.isLoadingMore && !state.isLoading && state.hasMore) {
      widget.cubit.fetchSpaces(pos: _position, loadMore: true);
    }
  }

  // ── Sticky header widget — built ONCE, never rebuilt on filter change ─────
  Widget _buildStickyHeader(String activeFilter) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          DiscoverSearchBar(
            controller: _searchCtrl,
            onChanged: (q) => widget.cubit.search(q, _position),
          ),
          const SizedBox(height: 6),
          // ✅ Use BlocSelector for ONLY the activeFilter field
          BlocSelector<DiscoverCubit, DiscoverState, String>(
            bloc: widget.cubit,
            selector: (state) => state.activeFilter,
            builder:
                (context, filter) => DiscoverFilterTabs(
                  filters: _filters,
                  active: filter,
                  onTap: _handleFilterChange,
                ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _handleJoinRequest(DiscoverSpace space) async {
    final spaceId = space.spaceId;

    // Check user's current spaces
    final spacesState = spacesCubit.state;
    if (spacesState is! SpacesLoaded) {
      // If spaces not loaded, proceed without warnings
      final result = await widget.cubit.requestToJoin(spaceId);
      _handleJoinResult(result);
      return;
    }

    final currentGroup =
        spacesState.groupSpaces.isNotEmpty
            ? spacesState.groupSpaces.first
            : null;
    final currentCouple =
        spacesState.coupleSpaces.isNotEmpty
            ? spacesState.coupleSpaces.first
            : null;

    List<_WarningItem> warnings = [];

    if (space.spaceType == 'group' && currentGroup != null) {
      final isOwner = currentGroup.createdBy == widget.cubit.userId;
      warnings.add(
        isOwner
            ? _WarningItem(
              icon: '⚠️',
              color: Colors.red,
              text:
                  'You own "${currentGroup.name}". Joining a new group will DELETE your space and remove all members permanently. This cannot be undone.',
            )
            : _WarningItem(
              icon: '👋',
              color: Colors.orange,
              text:
                  'You will be removed from "${currentGroup.name}" and all your habit data in that space will be lost.',
            ),
      );
    }
    if (space.spaceType == 'couple' && currentCouple != null) {
      final isOwner = currentCouple.createdBy == widget.cubit.userId;
      warnings.add(
        isOwner
            ? _WarningItem(
              icon: '⚠️',
              color: Colors.red,
              text:
                  'You own "${currentCouple.name}". Joining will DELETE your couple space and remove your partner permanently. This cannot be undone.',
            )
            : _WarningItem(
              icon: '💔',
              color: Colors.orange,
              text:
                  'You will leave "${currentCouple.name}" and all your shared habit history will be lost.',
            ),
      );
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinBottomSheet(space: space, warnings: warnings),
    );

    if (result?['proceed'] == true) {
      final joinResult = await widget.cubit.requestToJoin(spaceId);
      _handleJoinResult(joinResult);
    }
  }

  void _handleJoinResult(JoinResult result) {
    if (!mounted) return;
    switch (result) {
      case JoinSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request sent! 🙌'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case JoinError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    spacesCubit = context.read<SpacesCubit>();

    if (widget.isEmbedded) {
      return _buildEmbeddedContent();
    }

    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          final profile =
              profileState is ProfileLoaded ? profileState.profile : null;
          final avatarUrl =
              profileState is ProfileLoaded ? profileState.displayUrl : null;

          return Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: Column(
                children: [
                  // ── App bar — same as every other screen ──
                  if (profile != null)
                    StickyActionButtons(
                      spaceType: SpaceType.solo,
                      profile: profile,
                      displayUrl: avatarUrl,
                      scrollController: ScrollController(),
                    ),

                  // ── Content ──
                  Expanded(
                    child: BlocBuilder<DiscoverCubit, DiscoverState>(
                      builder: (context, state) {
                        if (state.error != null &&
                            state.spaces.isEmpty &&
                            !state.isLoading) {
                          return _DiscoverErrorView(
                            onRetry: () => widget.cubit.refresh(_position),
                          );
                        }
                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          controller: _scrollController,
                          slivers: [
                            ..._buildSlivers(state),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 20),
                            ),
                          ],
                        );
                      },
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

  /// ✅ Returns a list of slivers that can be injected directly into parent CustomScrollView
  /// This fixes the sticky header pinning bug by avoiding SliverMainAxisGroup nesting
  ///
  /// When isEmbedded is true, this builds the slivers as a list that HomeScreen can spread
  /// directly into its CustomScrollView slivers array
  Widget _buildEmbeddedContent() {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          // Return a SliverList that wraps all the discover slivers
          // The parent CustomScrollView will receive this single SliverList widget
          return _DiscoverSliverList(
            state: state,
            onJoinRequest: _handleJoinRequest,
            onLoadMore: _loadMoreIfNeeded,
            showSearchAndFeed: widget.showSearchAndFeed,
            buildStickyHeader: _buildStickyHeader,
            position: _position,
            cubit: widget.cubit,
          );
        },
      ),
    );
  }

  /// All slivers in one place — shared between embedded and standalone
  List<Widget> _buildSlivers(DiscoverState state) {
    return [
      // ── Search + Filter (STICKY) ──────────────────────────────────────────
      // ✅ Key fix: delegate uses a STABLE child widget reference
      // shouldRebuild only returns true when search/filter area actually changes
      if (widget.showSearchAndFeed)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StableHeaderDelegate(
            activeFilter: state.activeFilter,
            child: _buildStickyHeader(state.activeFilter),
          ),
        ),

      // ── Feed header ───────────────────────────────────────────────────────
      if (widget.showSearchAndFeed &&
          !state.isLoading &&
          state.spaces.isNotEmpty)
        SliverToBoxAdapter(
          child: FeedHeader(
            filter: state.activeFilter,
            totalResults: state.total,
          ),
        ),

      if (widget.showSearchAndFeed) ...[
        // ── Feed: loading skeleton ───────────────────
        if (state.isLoading && state.spaces.isEmpty)
          const SliverToBoxAdapter(child: _FeedShimmer()),

        // ── Feed: empty state ────────────────────────
        if (state.spaces.isEmpty && !state.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: DiscoverEmptyState(
                filter: state.activeFilter,
                searchQuery: state.searchQuery,
              ),
            ),
          ),

        // ── Feed: space cards ────────────────────────
        if (state.spaces.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => RepaintBoundary(
                key: ValueKey(state.spaces[index].spaceId),
                child: SpaceCard(
                  space: state.spaces[index],
                  onRequest: () => _handleJoinRequest(state.spaces[index]),
                ),
              ),
              childCount: state.spaces.length,
            ),
          ),

        // ── Load more / spinner ──────────────────────
        if (state.spaces.isNotEmpty)
          SliverToBoxAdapter(
            child:
                state.isLoadingMore
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    : state.hasMore
                    ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: GestureDetector(
                        onTap: _loadMoreIfNeeded,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Load more spaces',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}

// ── Stable header delegate ────────────────────────────────────────────────
// ✅ THE FIX: shouldRebuild only returns true when activeFilter changes
// Previously it always returned true (child != oldDelegate.child) because
// child was rebuilt inline on every BlocBuilder rebuild, causing the header
// to re-layout and visually jump/flicker when switching filters
class _StableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final String activeFilter; // only rebuild when filter changes
  static const double _height = 118.0;

  const _StableHeaderDelegate({
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
  bool shouldRebuild(_StableHeaderDelegate old) {
    // ✅ Only rebuild when the active filter actually changes
    // NOT on every spaces list update, loading state change, etc.
    return activeFilter != old.activeFilter;
  }
}

// ── Full-page error view ───────────────────────────────────────────────────
class _DiscoverErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _DiscoverErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed shimmer skeleton ──────────────────────────────────────────────────
class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: List.generate(3, (_) => _ShimmerCard())),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Opacity(
            opacity: _anim.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 130,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
    );
  }
}

// ── Premium paywall sheet ──────────────────────────────────────────────────
class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Premium Feature',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Premium to join spaces and connect with others.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C4AE4), Color(0xFF7B6EF6)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Upgrade to Premium',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Maybe later',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Warning item ────────────────────────────────────────────────────────────
class _WarningItem {
  final String icon;
  final Color color;
  final String text;
  _WarningItem({required this.icon, required this.color, required this.text});
}

// ── Join bottom sheet ────────────────────────────────────────────────────────
class _JoinBottomSheet extends StatelessWidget {
  final DiscoverSpace space;
  final List<_WarningItem> warnings;
  const _JoinBottomSheet({required this.space, required this.warnings});

  @override
  Widget build(BuildContext context) {
    final isCouple = space.spaceType == 'couple';
    final hasRedWarning = warnings.any((w) => w.color == Colors.red);
    final hasWarning = warnings.isNotEmpty;
    final buttonText =
        hasRedWarning
            ? 'I understand, Send Request'
            : hasWarning
            ? 'Yes, Send Request'
            : 'Send Request';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCouple ? Icons.favorite : Icons.groups_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.spaceName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCouple ? 'Couple Space' : 'Group Space',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${space.memberCount} / ${space.memberLimit} members · ${space.memberLimit - space.memberCount} spots left',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (space.habitPreviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Habits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final habit in space.habitPreviews)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              habit.emoji ?? '⚡',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                if (habit.isChallenge)
                                  Text(
                                    'Challenge Habit',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentAmber,
                                    ),
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
          ],

          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (var w in warnings)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(w.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context, {'proceed': true}),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: hasRedWarning ? Colors.red : null,
                gradient:
                    hasRedWarning
                        ? null
                        : const LinearGradient(
                          colors: [Color(0xFF5C4AE4), Color(0xFF7B6EF6)],
                        ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context, {'proceed': false}),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverList wrapper for Discover slivers — used when embedded in HomeScreen
class _DiscoverSliverList extends StatelessWidget {
  final DiscoverState state;
  final void Function(DiscoverSpace) onJoinRequest;
  final VoidCallback onLoadMore;
  final bool showSearchAndFeed;
  final Widget Function(String) buildStickyHeader;
  final Position? position;
  final DiscoverCubit cubit;

  const _DiscoverSliverList({
    required this.state,
    required this.onJoinRequest,
    required this.onLoadMore,
    required this.showSearchAndFeed,
    required this.buildStickyHeader,
    required this.position,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Return slivers directly using SliverMainAxisGroup (which is a sliver itself)
    // Do NOT wrap in SliverList — that causes the render error
    return SliverMainAxisGroup(
      slivers: [
        // ── Search + Filter (STICKY) ──────────────────────────────────────────
        // ✅ Key fix: delegate uses a STABLE child widget reference
        // shouldRebuild only returns true when search/filter area actually changes
        if (showSearchAndFeed)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StableHeaderDelegate(
              activeFilter: state.activeFilter,
              child: buildStickyHeader(state.activeFilter),
            ),
          ),

        // ── Feed header ───────────────────────────────────────────────────────
        if (showSearchAndFeed && !state.isLoading && state.spaces.isNotEmpty)
          SliverToBoxAdapter(
            child: FeedHeader(
              filter: state.activeFilter,
              totalResults: state.total,
            ),
          ),

        if (showSearchAndFeed) ...[
          // ── Feed: loading skeleton ───────────────────
          if (state.isLoading && state.spaces.isEmpty)
            const SliverToBoxAdapter(child: _FeedShimmer()),

          // ── Feed: empty state ────────────────────────
          if (state.spaces.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: DiscoverEmptyState(
                  filter: state.activeFilter,
                  searchQuery: state.searchQuery,
                ),
              ),
            ),

          // ── Feed: space cards ────────────────────────
          if (state.spaces.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SpaceCard(
                  space: state.spaces[index],
                  onRequest: () => onJoinRequest(state.spaces[index]),
                ),
                childCount: state.spaces.length,
              ),
            ),

          // ── Load more / spinner ──────────────────────
          if (state.spaces.isNotEmpty)
            SliverToBoxAdapter(
              child:
                  state.isLoadingMore
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      : state.hasMore
                      ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: GestureDetector(
                          onTap: onLoadMore,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Load more spaces',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}
