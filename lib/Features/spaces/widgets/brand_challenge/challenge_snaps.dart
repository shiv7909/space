// ════════════════════════════════════════════════════════════════════
// challenge_snaps.dart — Community snaps story ring section
// ════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_snap_model.dart';
import '../../../../models/brand_theme_data.dart';
import '../../../../models/snap_tray_model.dart';
import '../../../../services/profile_service.dart';
import '../../../snaps/widgets/snap_story_ring.dart';
import '../../../snaps/widgets/snap_stories_screen.dart';
import '../../../snaps/widgets/snap_capture_screen.dart';
import '../../../snaps/cubit/snap_cubit.dart';
import '../../cubits/brand_challenge_cubit.dart';
import 'challenge_helpers.dart';

class ChallengeSnapsSection extends StatelessWidget {
  final String challengeId;
  final ChallengeStoriesResponse stories;
  final ChallengeEnergy energy;
  final BrandThemeData theme;
  final double s;
  final bool isSendingSnap;
  final bool isEnrolled;
  final int activeUsersToday;
  final String enrolledCountLabel;

  const ChallengeSnapsSection({
    super.key,
    required this.challengeId,
    required this.stories,
    required this.energy,
    required this.theme,
    required this.s,
    required this.isSendingSnap,
    required this.isEnrolled,
    required this.activeUsersToday,
    required this.enrolledCountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackActive = activeUsersToday > 0 ? activeUsersToday : stories.totalStories;
    final activeLabel = fallbackActive > 0 ? '$fallbackActive active today' : '$enrolledCountLabel enrolled';
    final crushedTodayLabel = '${energy.completionsToday} crushed it today';

    final trayItems = stories.stories.map((story) => SnapTrayItem(
      senderId: story.senderId, senderName: story.senderName,
      avatarKey: story.avatarKey, photoKey: story.photoKey,
      totalSnaps: story.snapCount, unseenCount: story.unseenCount,
      previewStoragePath: story.previewStoragePath,
      storageBucket: story.storageBucket,
      isMine: story.isMine,
      hasNew: story.hasUnseen, postedToday: story.isMine && stories.postedToday,
      sortKey: story.hasUnseen ? 0 : 100, latestAt: story.latestSnapAt,
    )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('COMMUNITY', s),
        SizedBox(height: 10 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: theme.colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colors.primary.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: theme.colors.primary, size: 13 * s),
              SizedBox(width: 6 * s),
              Text(
                crushedTodayLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5 * s,
                  fontWeight: FontWeight.w800,
                  color: theme.colors.primary,
                ),
              ),
              SizedBox(width: 8 * s),
              Container(
                width: 4 * s,
                height: 4 * s,
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                activeLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5 * s,
                  fontWeight: FontWeight.w700,
                  color: theme.colors.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14 * s),
        if (!isEnrolled)
          _LockedCommunitySnapsPreview(theme: theme, s: s, activeLabel: activeLabel)
        else
          SnapStoryRing(
            tray: trayItems,
            iPostedToday: stories.postedToday,
            isSending: isSendingSnap,
            onAddSnap: () => _showSourcePicker(context),
            onEndReached: () => context.read<BrandChallengeCubit>().loadMoreStories(challengeId),
            onViewSnap: (item) {
              final startIndex = trayItems.indexWhere((t) => t.senderId == item.senderId);
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => SnapStoriesScreen(
                    challengeId: challengeId, tray: trayItems,
                    startIndex: startIndex >= 0 ? startIndex : 0,
                    currentUserId: context.read<SnapCubit>().userId,
                    snapCubit: context.read<SnapCubit>(),
                  ),
                  transitionsBuilder: (_, animation, __, child) => FadeTransition(
                    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ).then((_) {
                if (context.mounted) context.read<BrandChallengeCubit>().silentRefreshStories(challengeId);
              });
            },
          ),
      ],
    );
  }

  // ── Snap source picker bottom sheet ──
  void _showSourcePicker(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(sheetCtx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2))),
            Text('Post Challenge Snap', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onBackground, letterSpacing: -0.3)),
            const SizedBox(height: 20),
            _SourcePickerTile(
              icon: Icons.camera_alt_rounded, label: 'Take Photo', subtitle: 'Open camera to capture a moment',
              gradientColors: const [Color(0xFF5C4AE4), Color(0xFF9D8FFF)],
              onTap: () { Navigator.pop(sheetCtx); _openCaptureForChallenge(context, ImageSource.camera); },
            ),
            const SizedBox(height: 12),
            _SourcePickerTile(
              icon: Icons.photo_library_rounded, label: 'Choose from Gallery', subtitle: 'Pick an existing photo',
              gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
              onTap: () { Navigator.pop(sheetCtx); _openCaptureForChallenge(context, ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  void _openCaptureForChallenge(BuildContext context, ImageSource source) {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => SnapCaptureScreen(habits: const [], spaceId: 'brand_challenge', initialSource: source)),
    ).then((result) async {
      if (result == null || !context.mounted) return;
      final image = result['image'] as File;
      final caption = result['caption'] as String?;

      showDialog(context: context, barrierDismissible: false, builder: (_) => const _NsfwScanOverlay());

      try {
        final detector = await NsfwDetector.load(threshold: 0.55);
        final bytes = await image.readAsBytes();
        final nsfwResult = await detector.detectNSFWFromBytes(bytes);
        detector.close();
        if (context.mounted) Navigator.pop(context);
        if (nsfwResult == null) { if (context.mounted) _showNsfwDetectorErrorAlert(context); return; }
        if (nsfwResult.isNsfw) { if (context.mounted) _showGenZNsfwAlert(context); return; }
      } catch (e) {
        debugPrint('NSFW Detector failed: $e');
        if (context.mounted) { Navigator.pop(context); _showNsfwDetectorErrorAlert(context); }
        return;
      }

      if (context.mounted) {
        final errorMsg = await context.read<BrandChallengeCubit>().sendSnap(challengeId: challengeId, imageFile: image, caption: caption);
        if (errorMsg == null && context.mounted) {
          context.read<SnapCubit>().clearSenderSnapsCache(
            challengeId: challengeId,
            senderId: context.read<SnapCubit>().userId,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg ?? 'Snap posted successfully! 📸', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            backgroundColor: errorMsg == null ? AppTheme.accentGreen : AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    });
  }
}

class _LockedCommunitySnapsPreview extends StatelessWidget {
  final BrandThemeData theme;
  final double s;
  final String activeLabel;

  const _LockedCommunitySnapsPreview({
    required this.theme,
    required this.s,
    required this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colors.primary.withValues(alpha: 0.07),
            theme.colors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(4, (i) {
                final isLast = i == 3;
                return Transform.translate(
                  offset: Offset((-10 * s) * i, 0),
                  child: Container(
                    width: 34 * s,
                    height: 34 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: isLast
                          ? theme.colors.primary.withValues(alpha: 0.14)
                          : theme.colors.surface,
                    ),
                    child: isLast
                        ? Icon(Icons.lock_rounded, size: 14 * s, color: theme.colors.primary)
                        : Icon(Icons.person_rounded, size: 14 * s, color: AppTheme.onSurfaceVariant),
                  ),
                );
              }),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5 * s,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          Text(
            'Live challenge stories are waiting',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14 * s,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            'Join this challenge to unlock the full community feed and see new story drops in real time.',
            style: GoogleFonts.inter(
              fontSize: 12 * s,
              color: AppTheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourcePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _SourcePickerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NsfwScanOverlay extends StatelessWidget {
  const _NsfwScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Checking your snap...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Making sure everything is safe for the community',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showGenZNsfwAlert(BuildContext context) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.block_rounded,
                  size: 28,
                  color: AppTheme.accentRed,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Content Not Allowed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your snap appears to contain explicit content. To keep our community safe and welcoming, this is not allowed.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.accentRed,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showNsfwDetectorErrorAlert(BuildContext context) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 28,
                  color: AppTheme.accentAmber,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Verify Image',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t verify this image meets guidelines. For safety, this upload was blocked. Please try again.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.accentAmber,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Got It',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// BrandSnapViewer — Lightweight fullscreen pager
// ═══════════════════════════════════════════════════════════════════

class BrandSnapViewer extends StatefulWidget {
  final List<BrandSnapModel> snaps;
  final int initialIndex;
  const BrandSnapViewer({super.key, required this.snaps, required this.initialIndex});
  @override
  State<BrandSnapViewer> createState() => _BrandSnapViewerState();
}

class _BrandSnapViewerState extends State<BrandSnapViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemCount: widget.snaps.length,
          itemBuilder: (context, i) {
            final snap = widget.snaps[i];
            if (snap.signedUrl == null) return const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64));
            return CachedNetworkImage(
              imageUrl: snap.signedUrl!, fit: BoxFit.contain,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64)),
            );
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16,
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Sender avatar
            _SnapSenderAvatar(
              name: widget.snaps[_currentIndex].senderName,
              avatarId: null,
              avatarKey: widget.snaps[_currentIndex].senderAvatarKey,
              photoKey: widget.snaps[_currentIndex].senderPhotoKey,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(
              widget.snaps[_currentIndex].senderName,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)]),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        if (widget.snaps[_currentIndex].caption != null && widget.snaps[_currentIndex].caption!.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
              child: Text(widget.snaps[_currentIndex].caption!, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.4), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SNAP SENDER AVATAR — Profile image or preset avatar
// ════════════════════════════════════════════════════════════════════
class _SnapSenderAvatar extends StatelessWidget {
  final String name;
  final String? avatarId;
  final String? avatarKey;
  final String? photoKey;

  const _SnapSenderAvatar({
    required this.name,
    this.avatarId,
    this.avatarKey,
    this.photoKey,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Prefer real profile photo if backend provided photo_key.
    if (photoKey != null && photoKey!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: context.read<ProfileService>().getProfilePhotoUrl(photoKey!),
            fit: BoxFit.cover,
            placeholder: (_, __) => _fallback(name),
            errorWidget: (_, __, ___) => _fallback(name),
          ),
        ),
      );
    }

    // 2) Then use avatar_key directly if available.
    if (avatarKey != null && avatarKey!.isNotEmpty) {
      return FutureBuilder<String>(
        future: context.read<ProfileService>().getAvatarUrl(avatarKey!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _fallback(name),
                  errorWidget: (_, __, ___) => _fallback(name),
                ),
              ),
            );
          }
          return _fallback(name);
        },
      );
    }

    // 3) Fallback for older payloads: resolve avatar by avatar_id.
    if (avatarId != null && avatarId!.isNotEmpty) {
      return FutureBuilder<String?>(
        future: context.read<ProfileService>().getAvatarUrlById(avatarId!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _fallback(name),
                  errorWidget: (_, __, ___) => _fallback(name),
                ),
              ),
            );
          }
          return _fallback(name);
        },
      );
    }

    // Fallback: initials avatar
    return _fallback(name);
  }

  Widget _fallback(String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.7),
            const Color(0xFFFF6B6B).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}
