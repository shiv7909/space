import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../models/snap_tray_model.dart';
import '../../../services/profile_service.dart';

/// 📸 SNAP STORY RING — Instagram-tier horizontal scrollable story row.
///
/// Each circle = one sender who has active snaps (from the tray RPC).
/// Animated gradient ring = unseen snap. Subtle grey ring = already viewed.
/// First item = "+" add-snap button with pulsing gradient border.
class SnapStoryRing extends StatefulWidget {
  final List<SnapTrayItem> tray;
  final bool iPostedToday;
  final void Function(SnapTrayItem item) onViewSnap;
  final VoidCallback? onAddSnap;
  final VoidCallback? onSettings;
  final VoidCallback? onEndReached;
  final bool isSending;

  const SnapStoryRing({
    super.key,
    required this.tray,
    required this.iPostedToday,
    required this.onViewSnap,
    this.onAddSnap,
    this.onSettings,
    this.onEndReached,
    this.isSending = false,
  });

  @override
  State<SnapStoryRing> createState() => _SnapStoryRingState();
}

class _SnapStoryRingState extends State<SnapStoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringAnimController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (widget.onEndReached != null &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        widget.onEndReached!();
      }
    });
  }

  @override
  void dispose() {
    _ringAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tray.isEmpty && !widget.isSending && widget.onAddSnap == null) {
      return const SizedBox.shrink();
    }

    // Tray is already sorted by backend (unseen-first)
    final tray = widget.tray;
    final hasOwnStory = tray.any((t) => t.isMine);
    final showOnlyAddButton = tray.isEmpty && !widget.isSending;
    final s = Responsive.scale(context);
    final double carouselHeight = (showOnlyAddButton ? 65.0 * s : 92.0 * s) + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section label ──
        if (widget.isSending)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                _SendingIndicator(),
                const Spacer(),
              ],
            ),
          ),
        // ── Story circles ──
        SizedBox(
          height: carouselHeight,
          child: ClipRect(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 8),
              itemCount: tray.length + (widget.onAddSnap != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (widget.onAddSnap != null && index == 0) {
                  return _AddStoryItem(
                    hasOwnStory: hasOwnStory,
                    isSending: widget.isSending,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onAddSnap?.call();
                    },
                  );
                }

                final adjustedIndex =
                    widget.onAddSnap != null ? index - 1 : index;
                final item = tray[adjustedIndex];

                return _StoryItem(
                  item: item,
                  ringController: _ringAnimController,
                  profileService: context.read<ProfileService>(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onViewSnap(item);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SENDING INDICATOR — tiny animated dots
// ═══════════════════════════════════════════════════════════════════════════
class _SendingIndicator extends StatefulWidget {
  @override
  State<_SendingIndicator> createState() => _SendingIndicatorState();
}

class _SendingIndicatorState extends State<_SendingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
              final opacity = (math.sin(t * math.pi)).clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ADD STORY ITEM — simple "+" circle
// ═══════════════════════════════════════════════════════════════════════════
class _AddStoryItem extends StatelessWidget {
  final bool hasOwnStory;
  final bool isSending;
  final VoidCallback onTap;

  const _AddStoryItem({
    required this.hasOwnStory,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final ringSize = 62.0 * s;
    final iconSize = 26.0 * s;

    return Padding(
      padding: EdgeInsets.only(right: 14 * s, bottom: 3),
      child: GestureDetector(
        onTap: isSending ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceVariant,
                border: Border.all(color: AppTheme.outline, width: 1.5),
              ),
              child:
                  isSending
                      ? Padding(
                        padding: EdgeInsets.all(18 * s),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      )
                      : Icon(
                        Icons.add_rounded,
                        color: AppTheme.primaryColor,
                        size: iconSize,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STORY ITEM — shows user AVATAR from tray item
// ═══════════════════════════════════════════════════════════════════════════
class _StoryItem extends StatefulWidget {
  final SnapTrayItem item;
  final AnimationController ringController;
  final ProfileService profileService;
  final VoidCallback onTap;

  const _StoryItem({
    required this.item,
    required this.ringController,
    required this.profileService,
    required this.onTap,
  });

  @override
  State<_StoryItem> createState() => _StoryItemState();
}

class _StoryItemState extends State<_StoryItem> {
  Future<String?>? _avatarFuture;
  Future<String?>? _previewFuture;

  /// Resolves the best image URL for this sender:
  /// 1. Real profile photo (public URL — synchronous)
  /// 2. Preset avatar (signed URL — async)
  Future<String?>? _resolveImage(SnapTrayItem item) {
    // Priority 1: real photo
    final photoKey = item.photoKey;
    if (photoKey != null && photoKey.isNotEmpty) {
      return Future.value(widget.profileService.getProfilePhotoUrl(photoKey));
    }
    // Priority 2: preset avatar
    final avatarKey = item.avatarKey;
    if (avatarKey != null && avatarKey.isNotEmpty) {
      return widget.profileService.getAvatarUrl(avatarKey);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _avatarFuture = _resolveImage(widget.item);
    _previewFuture = _resolvePreview(widget.item);
  }

  @override
  void didUpdateWidget(_StoryItem old) {
    super.didUpdateWidget(old);
    if (old.item.photoKey != widget.item.photoKey ||
        old.item.avatarKey != widget.item.avatarKey) {
      _avatarFuture = _resolveImage(widget.item);
    }
    if (old.item.previewStoragePath != widget.item.previewStoragePath ||
        old.item.storageBucket != widget.item.storageBucket ||
        old.item.previewSignedUrl != widget.item.previewSignedUrl) {
      _previewFuture = _resolvePreview(widget.item);
    }
  }

  Future<String?>? _resolvePreview(SnapTrayItem item) {
    if (item.previewSignedUrl != null && item.previewSignedUrl!.isNotEmpty) {
      return Future.value(item.previewSignedUrl);
    }

    final path = item.previewStoragePath;
    if (path == null || path.isEmpty) return null;

    return () async {
      try {
        final url = await Supabase.instance.client.storage
            .from(item.storageBucket)
            .createSignedUrl(path, 3600);
        item.previewSignedUrl = url;
        return url;
      } catch (_) {
        return null;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isOwn = item.isMine;
    final hasUnseen = item.hasNew && !isOwn;
    final name = isOwn ? 'Your story' : item.senderName.split(' ').first;
    final s = Responsive.scale(context);
    final ringSize = 66.0 * s;
    final avatarSize = 56.0 * s;
    final labelWidth = 66.0 * s;
    final fontSize = 10.5 * s;
    final hasPreviewPath =
      item.previewStoragePath != null && item.previewStoragePath!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(right: 14 * s),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Animated gradient ring for unseen ──
                  if (hasUnseen)
                    AnimatedBuilder(
                      animation: widget.ringController,
                      builder: (_, __) => CustomPaint(
                        size: Size(ringSize, ringSize),
                        painter: _GradientRingPainter(
                          rotation:
                              widget.ringController.value * 2 * math.pi,
                          strokeWidth: 2.5 * s,
                          colors: const [
                            Color(0xFF5C4AE4),
                            Color(0xFFE040FB),
                            Color(0xFFFF6B6B),
                            Color(0xFFFFA726),
                            Color(0xFF5C4AE4),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: ringSize,
                      height: ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOwn
                              ? AppTheme.primaryColor.withValues(alpha: 0.25)
                              : AppTheme.outline,
                          width: 2,
                        ),
                      ),
                    ),

                  // ── Inner circle ──
                  if (hasPreviewPath)
                    // Snap thumbnail — fills the circle cleanly, no avatar chip
                    ClipOval(
                      child: SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: FutureBuilder<String?>(
                          future: _previewFuture,
                          builder: (context, snapshot) {
                            final previewUrl = snapshot.data;
                            if (previewUrl != null && previewUrl.isNotEmpty) {
                              return CachedNetworkImage(
                                imageUrl: previewUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppTheme.surfaceVariant,
                                ),
                                errorWidget: (_, __, ___) => _InitialAvatar(
                                  name: item.senderName,
                                  isOwn: isOwn,
                                ),
                              );
                            }
                            return _InitialAvatar(
                              name: item.senderName,
                              isOwn: isOwn,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    // No preview — plain profile avatar
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: hasUnseen
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _avatarFuture != null
                            ? FutureBuilder<String?>(
                                future: _avatarFuture,
                                builder: (context, snapshot) {
                                  final url = snapshot.data;
                                  if (url != null && url.isNotEmpty) {
                                    return CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => _InitialAvatar(
                                        name: item.senderName,
                                        isOwn: isOwn,
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          _InitialAvatar(
                                        name: item.senderName,
                                        isOwn: isOwn,
                                      ),
                                    );
                                  }
                                  return _InitialAvatar(
                                    name: item.senderName,
                                    isOwn: isOwn,
                                  );
                                },
                              )
                            : _InitialAvatar(
                                name: item.senderName,
                                isOwn: isOwn,
                              ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 6 * s),
            SizedBox(
              width: labelWidth,
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: hasUnseen ? FontWeight.w700 : FontWeight.w500,
                  color: hasUnseen
                      ? AppTheme.onBackground
                      : AppTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Fallback initial-letter avatar used when no image URL is available
class _InitialAvatar extends StatelessWidget {
  final String name;
  final bool isOwn;
  const _InitialAvatar({required this.name, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final initialFontSize = Responsive.sp(context, 20);
    return Container(
      color:
          isOwn
              ? const Color(0xFF5C4AE4).withValues(alpha: 0.15)
              : AppTheme.outline.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: initialFontSize,
            fontWeight: FontWeight.w800,
            color: isOwn ? const Color(0xFF5C4AE4) : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRADIENT RING PAINTER — rotating rainbow gradient ring for unseen snaps
// ═══════════════════════════════════════════════════════════════════════════
class _GradientRingPainter extends CustomPainter {
  final double rotation;
  final double strokeWidth;
  final List<Color> colors;

  _GradientRingPainter({
    required this.rotation,
    required this.strokeWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final gradient = SweepGradient(
      startAngle: rotation,
      endAngle: rotation + 2 * math.pi,
      colors: colors,
      tileMode: TileMode.clamp,
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
