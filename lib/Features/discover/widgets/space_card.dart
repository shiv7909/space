// filepath: d:\habitz\lib\Features\discover\widgets\space_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/image_cache_service.dart';
import '../models/discover_models.dart';

// ── Accent colours per space type ─────────────────────────────────────────
Color _accentFor(String spaceType) {
  if (spaceType == 'challenge') return const Color(0xFFFFB703);
  return spaceType == 'couple'
      ? const Color(0xFFFF6B6B)
      : const Color(0xFF6B6BE0);
}

class SpaceCard extends StatelessWidget {
  final DiscoverSpace space;
  final VoidCallback onRequest;

  const SpaceCard({super.key, required this.space, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme & Colors
    final accent = _accentFor(space.spaceType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF27272A) : Colors.white;

    // 🔗 Owner Avatar URL — Use the model's computed getter
    final avatarUrl = space.ownerProfilePhotoUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4D4D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP SECTION: Category & Badges ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Category Tag
                Flexible(
                  child:
                      space.categoryTag != null
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              space.categoryTag!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              space.spaceType.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          ),
                ),

                const Spacer(),

                // Distance Badge (if nearby)
                if (space.distanceKm != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${space.distanceKm!.toStringAsFixed(1)} km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── MIDDLE SECTION: Title & Description ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.spaceName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                    letterSpacing: -0.5,
                  ),
                ),
                if (space.description != null &&
                    space.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    space.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── OWNER ROW ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                avatarUrl != null
                    ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          cacheKey: avatarUrl,
                          cacheManager: ImageCacheService().cacheManager,
                          memCacheHeight: 150,
                          memCacheWidth: 150,
                          fit: BoxFit.cover,
                          httpHeaders: {
                            'Accept': 'image/*',
                            'Connection': 'keep-alive',
                          },
                          placeholder:
                              (context, url) => Container(
                                color: AppTheme.background,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppTheme.surfaceVariant,
                                child: Center(
                                  child: Text(
                                    space.ownerName.isEmpty
                                        ? '?'
                                        : space.ownerName[0],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    )
                    : CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.surfaceVariant,
                      child: Text(
                        space.ownerName.isEmpty ? '?' : space.ownerName[0],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.ownerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── HABIT PREVIEWS (Chips) ───────────────────────────────────
          if (space.habitPreviews.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children:
                    space.habitPreviews.take(4).map((habit) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (habit.emoji != null) ...[
                              Text(
                                habit.emoji!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              habit.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.surfaceVariant,
          ),

          // ── FOOTER STATS ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                // Members
                _FooterStat(
                  icon: Icons.people_outline_rounded,
                  text: '${space.memberCount}/${space.memberLimit}',
                ),
                const SizedBox(width: 16),

                // Avg Streak
                Flexible(
                  child: _FooterStat(
                    icon: Icons.local_fire_department_rounded,
                    text: space.avgStreakLabel,
                    iconColor: const Color(0xFFFF6B35),
                  ),
                ),

                const Spacer(),

                // Spots Left (Emergency)
                if (space.spotsLeft <= 2 && !space.isFull)
                  Text(
                    '${space.spotsLeft} spots left!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentRed,
                    ),
                  ),

                const SizedBox(width: 12),

                // Join Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onRequest();
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            space.iRequested
                                ? AppTheme.surfaceVariant
                                : space.isFull
                                ? AppTheme.surfaceVariant
                                : AppTheme.onBackground,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        space.iRequested
                            ? 'Requested'
                            : space.isFull
                            ? 'Full'
                            : 'Join',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              (space.iRequested || space.isFull)
                                  ? AppTheme.onSurfaceVariant
                                  : Colors.white,
                        ),
                      ),
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
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _FooterStat({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppTheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Generic Stat Chip ──────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
