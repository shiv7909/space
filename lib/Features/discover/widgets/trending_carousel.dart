// filepath: d:\habitz\lib\Features\discover\widgets\trending_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../models/discover_models.dart';
import '../../shared/premium_badge.dart';

class TrendingCarousel extends StatelessWidget {
  final List<DiscoverSpace> spaces;
  final ValueChanged<DiscoverSpace> onRequest;

  const TrendingCarousel({
    super.key,
    required this.spaces,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (spaces.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            24,
            16,
            12,
          ), // Increased top padding to separate from above content
          child: Row(
            children: [
              Text(
                'Trending Spaces',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18 * Responsive.scale(context),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.show_chart_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 186 * Responsive.scale(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: spaces.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder:
                (context, index) => RepaintBoundary(
                  child: _TrendingCard(
                    space: spaces[index],
                    onRequest: () => onRequest(spaces[index]),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Trending card ──────────────────────────────────────────────────────────
class _TrendingCard extends StatelessWidget {
  final DiscoverSpace space;
  final VoidCallback onRequest;

  const _TrendingCard({required this.space, required this.onRequest});

  // Gradient based on type
  LinearGradient get _gradient {
    if (space.spaceType == 'couple') {
      return const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF5C4AE4), Color(0xFF4834D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Container(
      width: 220 * s,
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (space.spaceType == 'couple'
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF5C4AE4))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Type & Category ───────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      space.spaceType == 'couple'
                          ? Icons.favorite_rounded
                          : Icons.groups_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      space.spaceType == 'couple' ? 'Couple' : 'Group',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (space.isTrending)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),

          const Spacer(),

          // ── Content: Name & Stats ─────────────────────────────────────
          Text(
            space.spaceName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Members
              Icon(
                Icons.person_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${space.memberCount}/${space.memberLimit}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              // Habits
              Icon(
                Icons.task_alt_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${space.habitCount} habits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Join Button ───────────────────────────────────────────────
          _GlassButton(
            onTap: onRequest,
            iRequested: space.iRequested,
            isFull: space.isFull,
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool iRequested;
  final bool isFull;

  const _GlassButton({
    required this.onTap,
    required this.iRequested,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    // Logic for button label and state
    String label = 'Join Space';
    bool isDisabled = false;

    if (iRequested) {
      label = 'Requested ✓';
      isDisabled = true;
    } else if (isFull) {
      label = 'Full';
      isDisabled = true;
    }

    return GestureDetector(
      onTap:
          isDisabled
              ? null
              : () {
                HapticFeedback.lightImpact();
                onTap();
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? Colors.white.withValues(
                    alpha: 0.3,
                  ) // More transparent when disabled
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color:
                isDisabled
                    ? Colors.white.withOpacity(0.9)
                    : (isFull && !iRequested)
                    ? Colors.grey
                    : const Color(0xFF5C4AE4),
          ),
        ),
      ),
    );
  }
}
