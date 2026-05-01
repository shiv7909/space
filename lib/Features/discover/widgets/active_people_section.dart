// filepath: d:\habitz\lib\Features\discover\widgets\active_people_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../services/image_cache_service.dart';
import '../cubit/active_people_cubit.dart';
import '../cubit/active_people_state.dart';
import '../models/discover_models.dart';
import 'person_bottom_sheet.dart';

// ── Constants ──────────────────────────────────────────────────────────────
const _kSupabaseUrl = 'https://xsclsoatsdadwtmjbffb.supabase.co';
const _kAvatarBase = '$_kSupabaseUrl/storage/v1/object/public/Avatars';
const _kPhotoBase = '$_kSupabaseUrl/storage/v1/object/public/profile-photos';

// ── Build public image URL (no signing needed — both buckets are public) ───
String? buildPersonImageUrl(String? photoKey, String? avatarKey) {
  if (photoKey != null && photoKey.isNotEmpty) {
    return '$_kPhotoBase/$photoKey';
  }
  if (avatarKey != null && avatarKey.isNotEmpty) {
    return '$_kAvatarBase/$avatarKey';
  }
  return null;
}

class ActivePeopleSection extends StatelessWidget {
  const ActivePeopleSection({super.key});

  void _showPersonSheet(BuildContext context, DiscoverPerson person) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (_) => PersonBottomSheet(
            person: person,
            cubit: context.read<ActivePeopleCubit>(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivePeopleCubit, ActivePeopleState>(
      builder: (context, state) {
        if (state.isLoading) return const _PeopleShimmer();

        if (state.error != null) {
          return _PeopleError(
            message: state.error!,
            onRetry: () => context.read<ActivePeopleCubit>().load(),
          );
        }

        if (state.people.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                'People You May Know',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15 * Responsive.scale(context),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.1,
                ),
              ),
            ),

            // ── Horizontal list ───────────────────────────────────────
            SizedBox(
              height: 172 * Responsive.scale(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 16, right: 8),
                // +1 slot for the loader card when hasMore is true
                itemCount: state.people.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  // ── Loader card (last slot) ────────────────────────
                  if (i == state.people.length) {
                    return _LoaderCard(
                      // ✅ KEY = offset so Flutter creates a FRESH widget
                      // every time a new page loads (different offset = new key)
                      key: ValueKey('loader_${state.offset}'),
                      isLoadingMore: state.isLoadingMore,
                      onVisible:
                          () => context.read<ActivePeopleCubit>().loadMore(),
                    );
                  }

                  // ── Person card ────────────────────────────────────
                  final person = state.people[i];
                  return _PersonCard(
                    person: person,
                    onTap: () => _showPersonSheet(context, person),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

// ── Loader card ────────────────────────────────────────────────────────────
// ✅ Uses ValueKey(offset) so it is ALWAYS a fresh widget per page.
// initState fires exactly once per key — no loops possible.
class _LoaderCard extends StatefulWidget {
  final bool isLoadingMore;
  final VoidCallback onVisible;

  const _LoaderCard({
    super.key,
    required this.isLoadingMore,
    required this.onVisible,
  });

  @override
  State<_LoaderCard> createState() => _LoaderCardState();
}

class _LoaderCardState extends State<_LoaderCard> {
  @override
  void initState() {
    super.initState();
    print(
      '🔵 LoaderCard built — key=${widget.key}, isLoadingMore=${widget.isLoadingMore}',
    );
    if (!widget.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🟢 Calling loadMore()');
          widget.onVisible();
        }
      });
    } else {
      print('🔴 Skipped — already loading');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 10, bottom: 2),
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Person card ────────────────────────────────────────────────────────────
class _PersonCard extends StatelessWidget {
  final DiscoverPerson person;
  final VoidCallback onTap;

  const _PersonCard({
    required this.person,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = buildPersonImageUrl(person.photoKey, person.avatarKey);

    final s = Responsive.scale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120 * s,
        margin: const EdgeInsets.only(right: 10, bottom: 2),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar / Photo ───────────────────────────────────────
            const SizedBox(height: 14),
            Center(
              child: _PersonImage(
                imageUrl: imageUrl,
                name: person.displayName,
                size: 72 * s,
              ),
            ),
            const SizedBox(height: 9),

            // ── Name ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      person.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // ── Badge ─────────────────────────────────────────────────
            if (person.hasStreak)
              _SmallBadge(
                label: '🔥 ${person.bestCurrentStreak}d',
                color: const Color(0xFFFF6B35),
              )
            else if (person.hasPublicSpace)
              _SmallBadge(
                label: person.spaceType == 'couple' ? ' Couple' : ' Group',
                color: AppTheme.primaryColor,
              )
            else if (person.daysOnApp != null)
              _SmallBadge(
                label: '${person.daysOnApp}d member',
                color: AppTheme.onSurfaceVariant,
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Simple image widget — no async, no signing ─────────────────────────────
class _PersonImage extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const _PersonImage({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheManager: ImageCacheService().cacheManager,
          httpHeaders: const {'Accept': 'image/*', 'Connection': 'keep-alive'},
          placeholder: (context, url) => _Initials(name: name, size: size),
          errorWidget:
              (context, url, error) => _Initials(name: name, size: size),
        ),
      );
    }
    return _Initials(name: name, size: size);
  }
}

// ── Initials fallback ──────────────────────────────────────────────────────
class _Initials extends StatelessWidget {
  final String name;
  final double size;

  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Small badge ────────────────────────────────────────────────────────────
class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────
class _PeopleShimmer extends StatelessWidget {
  const _PeopleShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 13,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 172,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder:
                  (_, __) => Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────
class _PeopleError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PeopleError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
