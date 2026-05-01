import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../../shared/user_avatar_widget.dart';

import '../models/discover_models.dart';

/// A card showing a person in the Active People list.
class PersonCard extends StatelessWidget {
  final DiscoverPerson person;
  final bool isPremiumUser;
  final VoidCallback onTap;

  const PersonCard({
    super.key,
    required this.person,
    required this.isPremiumUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Avatar — photo takes priority; fall back to resolved avatar URL
            _DiscoverAvatar(
              photoKey: person.photoKey,
              avatarKey: person.avatarKey,
              name: person.displayName,
              size: 48,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row with premium badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          person.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Space badge — only if in a public space
                  if (person.hasPublicSpace) ...[
                    const SizedBox(height: 3),
                    _SpaceBadge(
                      type: person.spaceType!,
                      category: person.spaceCategory,
                      emoji: person.spaceCategoryEmoji,
                    ),
                  ],

                  // Social proof — streak OR days on app
                  const SizedBox(height: 3),
                  if (person.hasStreak)
                    Text(
                      '🔥 ${person.bestCurrentStreak} day streak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    )
                  else if (person.daysOnApp != null)
                    Text(
                      'Member for ${person.daysOnApp} days',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small badge showing the space type + category (smart tag from backend)
class _SpaceBadge extends StatelessWidget {
  final String? type;
  final String? category;
  final String? emoji;

  const _SpaceBadge({this.type, this.category, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type == 'group' ? ' Group' : ' Couple',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (category != null) ...[
                Text(
                  ' · ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '${emoji ?? ''} $category'.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Resolves photo vs avatar correctly for a DiscoverPerson.
///
/// - [photoKey] → passed directly to UserAvatarWidget (public bucket, sync URL)
/// - [avatarKey] → requires a signed URL from ProfileService (async)
///
/// When photoKey is present, renders immediately.
/// When only avatarKey is present, resolves the signed URL then renders.
class _DiscoverAvatar extends StatefulWidget {
  final String? photoKey;
  final String? avatarKey;
  final String name;
  final double size;

  const _DiscoverAvatar({
    this.photoKey,
    this.avatarKey,
    required this.name,
    required this.size,
  });

  @override
  State<_DiscoverAvatar> createState() => _DiscoverAvatarState();
}

class _DiscoverAvatarState extends State<_DiscoverAvatar> {
  String? _resolvedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _resolveAvatar();
  }

  @override
  void didUpdateWidget(covariant _DiscoverAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarKey != widget.avatarKey ||
        oldWidget.photoKey != widget.photoKey) {
      _resolveAvatar();
    }
  }

  Future<void> _resolveAvatar() async {
    // If there's a real photo, UserAvatarWidget handles it via photoKey directly
    if (widget.photoKey != null) return;

    // Resolve avatar signed URL if we have an avatarKey
    if (widget.avatarKey != null) {
      final profileService = context.read<ProfileService>();
      final url = await profileService.getAvatarUrl(widget.avatarKey!);
      if (mounted) setState(() => _resolvedAvatarUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatarWidget(
      photoKey: widget.photoKey,
      avatarUrl: _resolvedAvatarUrl,
      name: widget.name,
      size: widget.size,

    );
  }
}
