import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../../../models/snap_tray_model.dart';
import '../../../services/profile_service.dart';
import '../cubit/snap_cubit.dart';
import '../cubit/snap_state.dart';
import 'snap_story_ring.dart';
import 'snap_capture_screen.dart';
import 'snap_stories_screen.dart';
import 'snap_space_picker_sheet.dart';

/// 📸 SNAP FEED WIDGET
class SnapFeedWidget extends StatelessWidget {
  final String spaceId;
  final String currentUserId;
  final List<DashboardHabit> habits;
  final bool isHomeContext;
  final bool hasSpaces;

  const SnapFeedWidget({
    super.key,
    required this.spaceId,
    required this.currentUserId,
    required this.habits,
    this.isHomeContext = false,
    this.hasSpaces = true,
  });

  static void openCaptureForHabit(
    BuildContext context, {
    required String spaceId,
    required List<DashboardHabit> habits,
    String? preSelectedHabitId,
    ImageSource? source,
  }) {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => SnapCaptureScreen(
              habits: habits,
              spaceId: spaceId,
              preSelectedHabitId: preSelectedHabitId,
              initialSource: source,
            ),
      ),
    ).then((result) async {
      if (result == null || !context.mounted) return;
      final image = result['image'] as File;
      final habitId = result['habitId'] as String?;
      final caption = result['caption'] as String?;

      // Show checking UI
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _NsfwScanOverlay(),
      );

      try {
        final detector = await NsfwDetector.load(threshold: 0.55);
        final bytes = await image.readAsBytes();
        final nsfwResult = await detector.detectNSFWFromBytes(bytes);
        detector.close();

        if (context.mounted) Navigator.pop(context); // Close scanning UI

        if (nsfwResult == null) {
          if (context.mounted) _showNsfwDetectorErrorAlert(context);
          return;
        }

        if (nsfwResult.isNsfw) {
          if (context.mounted) _showGenZNsfwAlert(context);
          return;
        }
      } catch (e) {
        debugPrint('NSFW Detector failed: $e');
        if (context.mounted) {
          Navigator.pop(context);
          _showNsfwDetectorErrorAlert(context);
        }
        return;
      }

      if (context.mounted) {
        context.read<SnapCubit>().sendSnap(
          spaceId: spaceId,
          imageFile: image,
          habitId: habitId,
          caption: caption,
        );
      }
    });
  }

  void _openCapture(BuildContext context) {
    HapticFeedback.selectionClick();
    _showSourcePicker(context);
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (sheetCtx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(sheetCtx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add to Story',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
                _SourcePickerTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  subtitle: 'Open camera to capture a moment',
                  gradientColors: const [Color(0xFF5C4AE4), Color(0xFF9D8FFF)],
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    
                    String? targetSpaceId = spaceId;
                    if (isHomeContext) {
                      targetSpaceId = await showSnapSpacePicker(context);
                      if (targetSpaceId == null) return; // User cancelled
                    }

                    if (context.mounted) {
                      openCaptureForHabit(
                        context,
                        spaceId: targetSpaceId,
                        habits: habits,
                        source: ImageSource.camera,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _SourcePickerTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from Gallery',
                  subtitle: 'Pick an existing photo',
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                  onTap: () async {
                    Navigator.pop(sheetCtx);

                    String? targetSpaceId = spaceId;
                    if (isHomeContext) {
                      targetSpaceId = await showSnapSpacePicker(context);
                      if (targetSpaceId == null) return; // User cancelled
                    }

                    if (context.mounted) {
                      openCaptureForHabit(
                        context,
                        spaceId: targetSpaceId,
                        habits: habits,
                        source: ImageSource.gallery,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Opens the stories viewer at the given tray index.
  void _openViewer(BuildContext context, SnapTrayItem item, List<SnapTrayItem> tray) {
    final startIndex = tray.indexWhere((t) => t.senderId == item.senderId);

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => SnapStoriesScreen(
              spaceId: isHomeContext ? null : spaceId,
              tray: tray,
              startIndex: startIndex >= 0 ? startIndex : 0,
              currentUserId: currentUserId,
              snapCubit: context.read<SnapCubit>(),
            ),
        transitionsBuilder:
            (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    ).then((_) {
      if (context.mounted) context.read<SnapCubit>().refreshSnaps();
    });
  }

  /// Shows the snap settings sheet (manage blocked users).
  void _openSettings(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _SnapSettingsSheet(
            snapCubit: context.read<SnapCubit>(),
            profileService: context.read<ProfileService>(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SnapCubit, SnapState>(
      listener: (context, state) {
        if (state is SnapSent) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('📸', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    state.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.onBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is SnapError && state.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        final tray = state is SnapTrayLoaded
            ? state.tray
            : (state is SnapError && state.previousTray != null)
                ? state.previousTray!.tray
                : <SnapTrayItem>[];
        final iPostedToday = state is SnapTrayLoaded
            ? state.iPostedToday
            : (state is SnapError && state.previousTray != null)
                ? state.previousTray!.iPostedToday
                : false;
        final isSending = state is SnapSending;
        final isEmpty = tray.isEmpty && !isSending;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder:
              (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
          child:
              isEmpty
                  ? (hasSpaces
                      ? _SnapEmptyState(
                          key: const ValueKey('empty'),
                          onTap: () => _openCapture(context),
                          onSettings: () => _openSettings(context),
                        )
                      : const SizedBox.shrink())
                  : SnapStoryRing(
                    key: const ValueKey('feed'),
                    tray: tray,
                    iPostedToday: iPostedToday,
                    isSending: isSending,
                    onViewSnap: (item) => _openViewer(context, item, tray),
                    onAddSnap: () => _openCapture(context),
                    onSettings: () => _openSettings(context),
                  ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SNAP SETTINGS SHEET — manage blocked users
// ══════════════════════════════════════════════════════════════════
class _SnapSettingsSheet extends StatefulWidget {
  final SnapCubit snapCubit;
  final ProfileService profileService;
  const _SnapSettingsSheet({
    required this.snapCubit,
    required this.profileService,
  });

  @override
  State<_SnapSettingsSheet> createState() => _SnapSettingsSheetState();
}

class _SnapSettingsSheetState extends State<_SnapSettingsSheet> {
  List<Map<String, dynamic>> _blocks = [];
  bool _loading = true;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _fetchBlocks();
  }

  Future<void> _fetchBlocks() async {
    setState(() => _loading = true);
    final blocks = await widget.snapCubit.getMyBlocks();
    if (!mounted) return;
    setState(() {
      _blocks = blocks;
      _loading = false;
    });
  }

  Future<void> _unblock(String blockedId, String displayName) async {
    setState(() => _unblocking.add(blockedId));
    final success = await widget.snapCubit.unblockUser(blockedId);
    if (!mounted) return;
    setState(() {
      _unblocking.remove(blockedId);
      if (success) _blocks.removeWhere((b) => b['blocked_id'] == blockedId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ $displayName unblocked'
              : 'Failed to unblock $displayName',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppTheme.onBackground : AppTheme.accentRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmUnblock(String blockedId, String displayName) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Unblock $displayName?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'You will start seeing their snaps again.',
              style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _unblock(blockedId, displayName);
                },
                child: Text(
                  'Unblock',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _formatBlockedAt(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, botPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Snap Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage blocked users. Blocked users can\'t see your snaps and you won\'t see theirs.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No blocked users',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _blocks.length,
                itemBuilder: (context, i) {
                  final b = _blocks[i];
                  final blockedId = b['blocked_id'] as String;
                  final displayName =
                      b['display_name'] as String? ?? 'Unknown User';
                  final avatarId = b['avatar_id'] as String?;
                  final blockedAt =
                      b['blocked_at'] != null
                          ? DateTime.tryParse(b['blocked_at'].toString())
                          : null;
                  final isUnblocking = _unblocking.contains(blockedId);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceVariant,
                          ),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              if (blockedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Blocked ${_formatBlockedAt(blockedAt)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap:
                              isUnblocking
                                  ? null
                                  : () =>
                                      _confirmUnblock(blockedId, displayName),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUnblocking
                                      ? AppTheme.outline
                                      : AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                isUnblocking
                                    ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                    : Text(
                                      'Unblock',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  EMPTY STATE — ultra-minimal, compressed, billion-dollar aesthetic
// ══════════════════════════════════════════════════════════════════
class _SnapEmptyState extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onSettings;
  const _SnapEmptyState({
    super.key,
    required this.onTap,
    required this.onSettings,
  });

  @override
  State<_SnapEmptyState> createState() => _SnapEmptyStateState();
}

class _SnapEmptyStateState extends State<_SnapEmptyState> {
  @override
  Widget build(BuildContext context) {
    return SnapStoryRing(
      tray: const [],
      iPostedToday: false,
      isSending: false,
      onViewSnap: (_) {},
      onAddSnap: widget.onTap,
      onSettings: widget.onSettings,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
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
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  NSFW SCAN OVERLAY
// ══════════════════════════════════════════════════════════════════
class _NsfwScanOverlay extends StatelessWidget {
  const _NsfwScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Checking image…',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Making sure everything looks good',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGenZNsfwAlert(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🫣', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Not Allowed',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'This image was flagged as inappropriate and can\'t be posted. '
            'Please choose a different photo.',
            style: GoogleFonts.inter(
              height: 1.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
  );
}

void _showNsfwDetectorErrorAlert(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Safety Check Failed',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'We couldn\'t verify this image is safe to share. '
            'Please try again or choose a different photo.',
            style: GoogleFonts.inter(
              height: 1.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
  );
}
