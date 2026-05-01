import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import 'package:space/core/models/shape_model.dart';
import '../../../services/shape_service.dart';

/// Discover tab — billion-dollar social discovery experience.
class DiscoverPlaceholder extends StatefulWidget {
  final bool isPremium;
  const DiscoverPlaceholder({super.key, required this.isPremium});
  @override
  State<DiscoverPlaceholder> createState() => _DiscoverPlaceholderState();
}

class _DiscoverPlaceholderState extends State<DiscoverPlaceholder> {
  List<ShapeModel> _shapes = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  // Key to find the upsell card and scroll to it (non-premium only)
  final GlobalKey _upsellKey = GlobalKey();

  void _scrollToUpsell() {
    final ctx = _upsellKey.currentContext;
    if (ctx == null) return;
    HapticFeedback.mediumImpact();
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  /// Premium users — tap anything interactive → "Coming Soon" popup
  void _showComingSoon(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coming soon! This feature is on its way.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadShapes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShapes() async {
    try {
      final shapeService = context.read<ShapeService>();
      final shapes = await shapeService.getShapes();
      if (mounted) {
        setState(() {
          _shapes = shapes;
          _loading = false;
        });
        shapeService.preloadShapes(shapes);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The action when tapping interactive elements:
    // - Premium: show "Coming Soon" snackbar
    // - Non-premium: scroll to upsell card
    final onInteractiveTap = widget.isPremium
        ? () => _showComingSoon(context)
        : _scrollToUpsell;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // 1 ── Search + Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _DiscoverSearchBar(
                  controller: _searchController,
                  onTap: onInteractiveTap,
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(
                activeFilter: _activeFilter,
                onFilterChanged: (v) => setState(() => _activeFilter = v),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

        const SizedBox(height: 22),

        // 2 ── Horizontal chip filters
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _FilterChip(label: 'All', active: _activeFilter == 'All', onTap: () => setState(() => _activeFilter = 'All')),
              _FilterChip(label: '📍 Nearby', active: _activeFilter == 'Nearby', onTap: onInteractiveTap),
              _FilterChip(label: '🔥 Trending', active: _activeFilter == 'Trending', onTap: onInteractiveTap),
              _FilterChip(label: '👥 Crews', active: _activeFilter == 'Crews', onTap: onInteractiveTap),
              _FilterChip(label: '🏆 Challenges', active: _activeFilter == 'Challenges', onTap: onInteractiveTap),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

        const SizedBox(height: 26),

        // 3 ── Active people (story-style ring avatars)
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 14),
          child: Text(
            'active right now',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kActiveUsers.length,
            itemBuilder: (context, i) {
              final u = _kActiveUsers[i];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: onInteractiveTap,
                  child: _ActiveUserAvatar(emoji: u.emoji, name: u.name, isLive: u.isLive),
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 30),

        // 4 ── Trending habits section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'trending habits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onInteractiveTap,
                child: Text(
                  'see all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 350.ms),

        const SizedBox(height: 14),

        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kTrendingHabits.length,
            itemBuilder: (context, i) {
              final h = _kTrendingHabits[i];
              return _TrendingHabitCard(
                emoji: h.emoji,
                name: h.name,
                participants: h.participants,
                color: h.color,
                index: i,
                onTap: onInteractiveTap,
              );
            },
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

        const SizedBox(height: 30),

        // 5 ── Shapes marquee
        if (!_loading && _shapes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 14),
            child: Text(
              'communities',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 350.ms),
          SizedBox(height: 120, child: _InfiniteShapeMarquee(shapes: _shapes))
              .animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 30),
        ] else if (_loading) ...[
          SizedBox(height: 100, child: _buildLoadingPlaceholders()),
          const SizedBox(height: 30),
        ],

        // 6 ── Premium upsell card — ONLY for non-premium users
        if (!widget.isPremium)
          Padding(
            key: _upsellKey,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const _PremiumUpsellCard(),
          ).animate().fadeIn(delay: 450.ms, duration: 500.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPremiumComingSoon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outline, width: 1),
            ),
            child: const Icon(Icons.explore_outlined, size: 28, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(
            'Coming Soon',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.onBackground, letterSpacing: -0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover is on its way.\nCheck back soon.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholders() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppTheme.outline.withValues(alpha: 0.3)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOCK DATA — replace with real API later
// ═════════════════════════════════════════════════════════════════════════════

class _ActiveUser {
  final String emoji;
  final String name;
  final bool isLive;
  const _ActiveUser(this.emoji, this.name, {this.isLive = false});
}

const _kActiveUsers = [
  _ActiveUser('🧑‍💻', 'You', isLive: true),
  _ActiveUser('👩‍🎤', 'Aria'),
  _ActiveUser('🧔', 'Dev'),
  _ActiveUser('👱‍♀️', 'Mia', isLive: true),
  _ActiveUser('🧑‍🚀', 'Kai'),
  _ActiveUser('👩‍🔬', 'Zoe'),
  _ActiveUser('🧑‍🎨', 'Leo'),
  _ActiveUser('👨‍🍳', 'Sam'),
];

class _TrendingHabitData {
  final String emoji;
  final String name;
  final String participants;
  final Color color;
  const _TrendingHabitData(this.emoji, this.name, this.participants, this.color);
}

const _kTrendingHabits = [
  _TrendingHabitData('🏃', 'Morning Run', '2.4k', Color(0xFF5C4AE4)),
  _TrendingHabitData('📖', 'Read 30min', '1.8k', Color(0xFF2DA44E)),
  _TrendingHabitData('🧘', 'Meditate', '3.1k', Color(0xFFD4870B)),
  _TrendingHabitData('💪', 'Gym', '5.2k', Color(0xFFD1242F)),
  _TrendingHabitData('💧', 'Hydrate', '4.0k', Color(0xFF0EA5E9)),
];

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH BAR — accepts onTap to scroll to upsell
// ═════════════════════════════════════════════════════════════════════════════

class _DiscoverSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  const _DiscoverSearchBar({required this.controller, required this.onTap});

  @override
  State<_DiscoverSearchBar> createState() => _DiscoverSearchBarState();
}

class _DiscoverSearchBarState extends State<_DiscoverSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 48,
      decoration: BoxDecoration(
        color: _focused ? AppTheme.surface : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.transparent,
          width: _focused ? 1.5 : 0,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        readOnly: true, // not real search yet — tap scrolls to upsell
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onBackground),
        decoration: InputDecoration(
          hintText: 'search people, habits, crews…',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.65)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: _focused ? AppTheme.primaryColor : AppTheme.onSurfaceVariant),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          _focusNode.unfocus();
          widget.onTap();
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTER BUTTON (compact icon, blue dot when active)
// ═════════════════════════════════════════════════════════════════════════════

class _FilterButton extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  const _FilterButton({required this.activeFilter, required this.onFilterChanged});

  bool get _isFiltered => activeFilter != 'All';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _FilterBottomSheet(
            currentFilter: activeFilter,
            onFilterSelected: (f) { onFilterChanged(f); Navigator.of(context).pop(); },
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isFiltered ? AppTheme.primaryColor.withValues(alpha: 0.08) : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFiltered ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                width: _isFiltered ? 1.5 : 0,
              ),
            ),
            child: Icon(Icons.tune_rounded, size: 19, color: _isFiltered ? AppTheme.primaryColor : AppTheme.onSurfaceVariant),
          ),
          if (_isFiltered)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceVariant, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HORIZONTAL FILTER CHIPS
// ═════════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.onBackground : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ACTIVE USER AVATAR (Instagram-style ring)
// ═════════════════════════════════════════════════════════════════════════════

class _ActiveUserAvatar extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isLive;
  const _ActiveUserAvatar({required this.emoji, required this.name, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isLive
                ? const LinearGradient(colors: [Color(0xFF5C4AE4), Color(0xFFFF6B6B)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isLive ? null : AppTheme.outline,
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceVariant,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRENDING HABIT CARD — accepts onTap
// ═════════════════════════════════════════════════════════════════════════════

class _TrendingHabitCard extends StatefulWidget {
  final String emoji;
  final String name;
  final String participants;
  final Color color;
  final int index;
  final VoidCallback onTap;
  const _TrendingHabitCard({
    required this.emoji,
    required this.name,
    required this.participants,
    required this.color,
    required this.index,
    required this.onTap,
  });

  @override
  State<_TrendingHabitCard> createState() => _TrendingHabitCardState();
}

class _TrendingHabitCardState extends State<_TrendingHabitCard> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressing ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.12), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const Spacer(),
              Text(widget.name,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onBackground, letterSpacing: -0.3),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('${widget.participants} people',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTER BOTTOM SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _FilterBottomSheet extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterSelected;
  const _FilterBottomSheet({required this.currentFilter, required this.onFilterSelected});

  static const _filters = [
    ('All', Icons.grid_view_rounded, 'everything'),
    ('Nearby', Icons.near_me_rounded, 'people around you'),
    ('Trending', Icons.trending_up_rounded, 'what\'s hot rn'),
    ('Crews', Icons.people_alt_rounded, 'your squads'),
    ('Challenges', Icons.emoji_events_rounded, 'compete & win'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            'Filter',
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.onBackground),
          ),
          const SizedBox(height: 20),
          ..._filters.map((f) {
            final selected = currentFilter == f.$1;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); onFilterSelected(f.$1); },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor.withValues(alpha: 0.07) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(f.$2, size: 20, color: selected ? AppTheme.primaryColor : AppTheme.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$1, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? AppTheme.primaryColor : AppTheme.onBackground)),
                          Text(f.$3, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (selected) Icon(Icons.check_circle_rounded, size: 20, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM UPSELL CARD — clean, no shimmer, editorial feel
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumUpsellCard extends StatefulWidget {
  const _PremiumUpsellCard();
  @override
  State<_PremiumUpsellCard> createState() => _PremiumUpsellCardState();
}

class _PremiumUpsellCardState extends State<_PremiumUpsellCard> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _pressing = true); },
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        // TODO: navigate to premium
      },
      child: AnimatedScale(
        scale: _pressing ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F0F1A), Color(0xFF1A1035)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Subtle ambient circles — no animation, just depth
                Positioned(
                  top: -30,
                  right: -25,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF5C4AE4).withValues(alpha: 0.18),
                          const Color(0xFF5C4AE4).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF6B6B).withValues(alpha: 0.10),
                          const Color(0xFFFF6B6B).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 11, color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Headline
                      Text(
                        'find your people. 🌍',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: -0.8),
                      ),

                      const SizedBox(height: 10),

                      // Sub
                      Text(
                        'near you or across the planet — find people doing the same habits and go harder together.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5), height: 1.5),
                      ),

                      const SizedBox(height: 22),

                      // Stats row
                      Row(
                        children: [
                          _PremiumStat(value: '12k+', label: 'members'),
                          const SizedBox(width: 24),
                          _PremiumStat(value: '340', label: 'crews'),
                          const SizedBox(width: 24),
                          _PremiumStat(value: '89%', label: 'stick rate'),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // CTA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            'unlock premium',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.onBackground, letterSpacing: -0.2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'no commitments · cancel anytime',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.28)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
  }
}

class _PremiumStat extends StatelessWidget {
  final String value;
  final String label;
  const _PremiumStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFINITE SHAPE MARQUEE
// ═════════════════════════════════════════════════════════════════════════════

class _InfiniteShapeMarquee extends StatefulWidget {
  final List<ShapeModel> shapes;
  const _InfiniteShapeMarquee({required this.shapes});

  @override
  State<_InfiniteShapeMarquee> createState() => _InfiniteShapeMarqueeState();
}

class _InfiniteShapeMarqueeState extends State<_InfiniteShapeMarquee>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final scheduler.Ticker _ticker;
  bool _isUserInteraction = false;
  Duration? _lastElapsed;
  static const double _speed = 28.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == null) { _lastElapsed = elapsed; return; }
    final dt = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (_isUserInteraction || !mounted || widget.shapes.isEmpty) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset + (_speed * dt));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _isUserInteraction = true,
      onPointerUp: (_) { _isUserInteraction = false; _lastElapsed = null; },
      onPointerCancel: (_) { _isUserInteraction = false; _lastElapsed = null; },
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final shape = widget.shapes[index % widget.shapes.length];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline.withValues(alpha: 0.25), width: 1),
            ),
            child: FutureBuilder<Uint8List>(
              future: context.read<ShapeService>().getShapeBytes(shape.shapeKey),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return SvgPicture.memory(snapshot.data!, fit: BoxFit.contain);
              },
            ),
          );
        },
      ),
    );
  }
}
