import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/snap_model.dart';
import '../../../models/snap_tray_model.dart';
import '../../../models/snap_sender_response.dart';
import '../../../services/profile_service.dart';
import '../cubit/snap_cubit.dart';

/// 📸 SNAP STORIES SCREEN — Full tray-based Instagram stories viewer.
///
/// Flow:
///   1. Receives tray + startIndex from the feed
///   2. Loads sender snaps on demand via get_space_sender_snaps
///   3. Auto-advances through snaps, then to next sender
///   4. Fire-and-forget view tracking
///   5. Reaction bar for other's snaps, viewer sheet for own snaps
class SnapStoriesScreen extends StatefulWidget {
  final String? spaceId;
  final String? challengeId;
  final List<SnapTrayItem> tray;
  final int startIndex;
  final String currentUserId;
  final SnapCubit snapCubit;

  const SnapStoriesScreen({
    super.key,
    this.spaceId,
    this.challengeId,
    required this.tray,
    required this.startIndex,
    required this.currentUserId,
    required this.snapCubit,
  });

  @override
  State<SnapStoriesScreen> createState() => _SnapStoriesScreenState();
}

class _SnapStoriesScreenState extends State<SnapStoriesScreen>
    with TickerProviderStateMixin {
  late int _trayIndex;
  List<dynamic> _currentSnaps = [];
  SnapSenderInfo? _currentSender;
  int _snapIndex = 0;
  bool _isLoading = true;
  bool _isPaused = false;
  String? _currentImageUrl;
  SnapReaction? _selectedReaction;

  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Cache avatar futures per sender
  final Map<String, Future<String?>> _avatarFutures = {};

  static const _snapDuration = Duration(seconds: 5);
  Timer? _midnightTimer;
  Timer? _imageLoadTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _disableScreenCapture();

    _trayIndex = widget.startIndex.clamp(0, widget.tray.length - 1);
    _progressController = AnimationController(
      vsync: this,
      duration: _snapDuration,
    );
    _progressController.addStatusListener(_onProgressComplete);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scheduleMidnightClose();
    _loadSender(_trayIndex);
  }

  void _disableScreenCapture() {
    const secureChannel = MethodChannel('habitz/secure');
    try {
      secureChannel.invokeMethod('setSecureFlag', true);
    } catch (_) {}
  }

  void _scheduleMidnightClose() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final untilMidnight = midnight.difference(now);
    _midnightTimer = Timer(untilMidnight, () {
      widget.snapCubit.clearUrlCache();
      widget.snapCubit.refreshSnaps();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _imageLoadTimer?.cancel();
    const secureChannel = MethodChannel('habitz/secure');
    try {
      secureChannel.invokeMethod('setSecureFlag', false);
    } catch (_) {}
    _progressController.removeStatusListener(_onProgressComplete);
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goToNextSnap();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD SENDER — called for each sender in the tray
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadSender(int trayIdx) async {
    if (trayIdx < 0 || trayIdx >= widget.tray.length) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _trayIndex = trayIdx;
      _isLoading = true;
      _currentImageUrl = null;
      _currentSnaps = [];
      _snapIndex = 0;
    });
    _progressController.reset();
    _fadeController.reset();

    final trayItem = widget.tray[trayIdx];

    // Resolve spaceId: use widget.spaceId if set, otherwise pick from
    // the tray item's spaces array (home tray context).
    String? resolvedSpaceId = widget.spaceId;
    if (resolvedSpaceId == null && trayItem.spaces.isNotEmpty) {
      // Pick space with highest unseen_count, fallback to first
      final sorted = List<Map<String, dynamic>>.from(trayItem.spaces)
        ..sort((a, b) => ((b['unseen_count'] as num?)?.toInt() ?? 0)
            .compareTo((a['unseen_count'] as num?)?.toInt() ?? 0));
      resolvedSpaceId = sorted.first['space_id'] as String?;
    }

    if (resolvedSpaceId == null && widget.challengeId == null) {
      // Can't resolve space — skip this sender
      _goToNextSender();
      return;
    }

    final response = await widget.snapCubit.loadSenderSnaps(
      spaceId: resolvedSpaceId,
      challengeId: widget.challengeId,
      senderId: trayItem.senderId,
      knownSender: SnapSenderInfo(
        id: trayItem.senderId,
        displayName: trayItem.senderName,
        avatarKey: trayItem.avatarKey,
        photoKey: trayItem.photoKey,
      ),
    );

    if (!mounted) return;

    if (response == null || response.snaps.isEmpty) {
      // No snaps found — skip to next sender
      _goToNextSender();
      return;
    }

    // Normalize order for viewer logic: oldest -> newest.
    final orderedSnaps = List<dynamic>.from(response.snaps)
      ..sort((a, b) => (a.createdAt as DateTime).compareTo(b.createdAt as DateTime));

    // Find first unviewed snap (for non-own snaps)
    int startSnapIdx = 0;
    if (!trayItem.isMine) {
      // For challenge stories, tray unseen_count is the most reliable source.
      // Snaps are ordered oldest -> newest in story viewer, so first unseen is
      // at index (total - unseenCount).
      if (trayItem.unseenCount > 0 && trayItem.unseenCount <= orderedSnaps.length) {
        final idxFromTray = orderedSnaps.length - trayItem.unseenCount;
        startSnapIdx = idxFromTray.clamp(0, orderedSnaps.length - 1);
      } else {
        // Fallback if unseen_count is unavailable/inconsistent.
        final firstUnseen = orderedSnaps.indexWhere((s) => !s.iViewed);
        if (firstUnseen >= 0) {
          startSnapIdx = firstUnseen;
        }
      }
    }

    setState(() {
      _currentSnaps = orderedSnaps;
      _currentSender = response.sender;
      _snapIndex = startSnapIdx;
    });

    _loadCurrentSnap();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD CURRENT SNAP — fetch signed URL + fire view RPC
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadCurrentSnap() async {
    if (!mounted || _currentSnaps.isEmpty) return;
    final snap = _currentSnaps[_snapIndex];

    setState(() {
      _isLoading = true;
      _currentImageUrl = null;
      _selectedReaction = snap.myReaction != null
          ? SnapReactionExt.fromString(snap.myReaction!)
          : null;
    });
    _progressController.reset();
    _fadeController.reset();
    _imageLoadTimer?.cancel();

    final url = await widget.snapCubit.viewSnap(
      snapId: snap.id,
      storagePath: snap.storagePath,
      isMine: snap.isMine,
      isChallengeSnap: widget.challengeId != null,
    );

    if (!mounted) return;

    if (url != null) {
      setState(() {
        _currentImageUrl = url;
        _isLoading = false;
      });
      _imageLoadTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _currentImageUrl == url) _goToNextSnap();
      });
    } else {
      setState(() => _isLoading = false);
      _showToast('⏰ This snap has expired');
      Future.delayed(const Duration(milliseconds: 1200), _goToNextSnap);
    }
  }

  void _onImageLoaded() {
    if (!mounted || _isPaused) return;
    _imageLoadTimer?.cancel();
    _imageLoadTimer = null;
    _fadeController.forward();
    _progressController.forward();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════

  void _goToNextSnap() {
    if (!mounted) return;
    if (_snapIndex < _currentSnaps.length - 1) {
      setState(() => _snapIndex++);
      _loadCurrentSnap();
    } else {
      _goToNextSender();
    }
  }

  void _goToPrevSnap() {
    if (!mounted) return;
    if (_snapIndex > 0) {
      setState(() => _snapIndex--);
      _loadCurrentSnap();
    } else if (_trayIndex > 0) {
      _loadSender(_trayIndex - 1);
    } else {
      _progressController.reset();
      if (!_isPaused) _progressController.forward();
    }
  }

  void _goToNextSender() {
    if (_trayIndex < widget.tray.length - 1) {
      _loadSender(_trayIndex + 1);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      if (_currentImageUrl != null) _progressController.forward();
    }
  }

  void _onTapSide(TapUpDetails details, BoxConstraints constraints) {
    final tapX = details.localPosition.dx;
    HapticFeedback.selectionClick();
    if (tapX < constraints.maxWidth * 0.3) {
      _goToPrevSnap();
    } else {
      _goToNextSnap();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _react(SnapReaction reaction) {
    if (_currentSnaps.isEmpty) return;
    HapticFeedback.mediumImpact();
    final snap = _currentSnaps[_snapIndex];

    // Optimistic local update
    final oldReaction = snap.myReaction;
    final newReactionStr = reaction.value;

    int fireCount = snap.fireCount;
    int strongCount = snap is SpaceSenderSnap ? snap.strongCount : (snap as ChallengeSenderSnap).flexCount;
    int laughCount = snap is SpaceSenderSnap ? snap.laughCount : 0;
    int eyesCount = snap is SpaceSenderSnap ? snap.eyesCount : 0;
    int heartCount = snap.heartCount;

    // Remove old reaction
    if (oldReaction != null) {
      if (oldReaction == 'fire') fireCount--;
      if (oldReaction == 'strong' || oldReaction == 'flex') strongCount--;
      if (oldReaction == 'laugh') laughCount--;
      if (oldReaction == 'eyes') eyesCount--;
      if (oldReaction == 'heart') heartCount--;
    }

    String? finalReaction;
    if (oldReaction == newReactionStr) {
      finalReaction = null; // Toggle off
    } else {
      finalReaction = newReactionStr;
      if (newReactionStr == 'fire') fireCount++;
      if (newReactionStr == 'strong' || newReactionStr == 'flex') strongCount++;
      if (newReactionStr == 'laugh') laughCount++;
      if (newReactionStr == 'eyes') eyesCount++;
      if (newReactionStr == 'heart') heartCount++;
    }

    setState(() {
      if (snap is SpaceSenderSnap) {
        _currentSnaps[_snapIndex] = snap.copyWith(
          myReaction: finalReaction,
          clearReaction: finalReaction == null,
          fireCount: fireCount,
          strongCount: strongCount,
          laughCount: laughCount,
          eyesCount: eyesCount,
          heartCount: heartCount,
        );
      } else if (snap is ChallengeSenderSnap) {
        _currentSnaps[_snapIndex] = snap.copyWith(
          myReaction: finalReaction,
          clearReaction: finalReaction == null,
          fireCount: fireCount,
          flexCount: strongCount,
          heartCount: heartCount,
        );
      }
      
      _selectedReaction = finalReaction != null
          ? SnapReactionExt.fromString(finalReaction)
          : null;
    });

    // Fire actual RPC
    widget.snapCubit.reactToSnap(
      snap.id,
      reaction,
      isChallengeSnap: widget.challengeId != null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  OPTIONS / REPORT / DELETE / VIEWERS
  // ═══════════════════════════════════════════════════════════════════════

  void _showOptions() {
    if (_currentSnaps.isEmpty) return;
    _pause();
    final snap = _currentSnaps[_snapIndex];
    if (snap.isMine) {
      _showDeleteDialog(snap);
    } else {
      _showReportBlockSheet(snap);
    }
  }

  void _showReportBlockSheet(dynamic snap) {
    final senderName = _currentSender?.displayName ?? 'User';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Report option
                _OptionTile(
                  icon: Icons.flag_outlined,
                  iconColor: AppTheme.accentAmber,
                  label: 'Report this snap',
                  subtitle: 'Flag for review by our team',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await widget.snapCubit.reportSnap(
                      snapId: snap.id,
                      reason: 'inappropriate_content',
                    );
                    if (mounted) {
                      _showToast(success
                          ? '🚩 Report submitted — thanks for keeping it safe'
                          : 'Failed to submit report');
                    }
                    _resume();
                  },
                ),
                const SizedBox(height: 8),
                // Block option
                _OptionTile(
                  icon: Icons.block_rounded,
                  iconColor: AppTheme.accentRed,
                  label: 'Block $senderName',
                  subtitle: 'You won\'t see their snaps anymore',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await widget.snapCubit.blockUser(
                      _currentSender!.id,
                    );
                    if (mounted) {
                      if (success) {
                        _showToast('🚫 $senderName blocked');
                        Navigator.pop(context);
                      } else {
                        _resume();
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resume();
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(_resume);
  }

  void _showViewers() {
    if (_currentSnaps.isEmpty) return;
    _pause();
    final snap = _currentSnaps[_snapIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SnapViewersSheet(
        snapId: snap.id,
        snap: snap,
        snapCubit: widget.snapCubit,
        currentUserId: widget.currentUserId,
        isBrandSnap: widget.challengeId != null,
        onDelete: () async {
          Navigator.pop(ctx);
          final success = await widget.snapCubit.deleteSnap(
            snap.id,
            isChallengeSnap: widget.challengeId != null,
          );
          if (mounted && success) {
            Navigator.pop(context);
          } else {
            _resume();
          }
        },
      ),
    ).whenComplete(_resume);
  }

  void _showDeleteDialog(dynamic snap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.accentRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Snap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This snap will be permanently deleted for everyone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resume();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await widget.snapCubit.deleteSnap(
                snap.id,
                isChallengeSnap: widget.challengeId != null,
              );
              if (mounted && success) {
                Navigator.pop(context);
              } else {
                _resume();
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.accentRed,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _resume());
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.onBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 30) return 'Just now';
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  String _buildReactionSummary(dynamic snap) {
    final parts = <String>[];
    for (final r in SnapReaction.values) {
      final count = _reactionCount(snap, r.value);
      if (count > 0) parts.add('${r.emoji}$count');
    }
    return parts.take(3).join(' ');
  }

  int _reactionCount(dynamic snap, String type) {
    if (snap is SpaceSenderSnap) {
      return snap.reactionCount(type);
    }
    if (snap is ChallengeSenderSnap) {
      switch (type) {
        case 'fire':
          return snap.fireCount;
        case 'strong':
          return snap.flexCount;
        case 'heart':
          return snap.heartCount;
        default:
          return 0;
      }
    }
    return 0;
  }

  // ── HEADER AVATAR RESOLUTION ──
  Future<String?> _getAvatarFuture() {
    if (_currentSender == null) return Future.value(null);
    final sender = _currentSender!;
    final cacheKey =
        '${sender.id}|${sender.photoKey ?? ''}|${sender.avatarKey ?? ''}';
    return _avatarFutures.putIfAbsent(cacheKey, () {
      final photoKey = sender.photoKey;
      if (photoKey != null && photoKey.isNotEmpty) {
        return Future.value(
          context.read<ProfileService>().getProfilePhotoUrl(photoKey),
        );
      }
      final avatarKey = sender.avatarKey;
      if (avatarKey != null && avatarKey.isNotEmpty) {
        return context.read<ProfileService>().getAvatarUrl(avatarKey);
      }
      return Future.value(null);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final snap = _currentSnaps.isNotEmpty ? _currentSnaps[_snapIndex] : null;
    final isOwn = snap?.isMine ?? false;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (d) => _onTapSide(d, constraints),
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              onVerticalDragEnd:
                  isOwn
                      ? (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! < -300) {
                          _showViewers();
                        }
                      }
                      : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── IMAGE ──
                  if (_currentImageUrl != null)
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: CachedNetworkImage(
                        imageUrl: _currentImageUrl!,
                        fit: BoxFit.contain,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        imageBuilder: (ctx, imageProvider) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _onImageLoaded(),
                          );
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF111111),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white24,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── LOADING SHIMMER ──
                  if (_isLoading || _currentImageUrl == null)
                    _SnapLoadingShimmer(topPad: topPad),

                  // ── TOP GRADIENT ──
                  Positioned(
                    top: 0, left: 0, right: 0, height: 160,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── BOTTOM GRADIENT ──
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 220,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── PROGRESS BARS ──
                  if (!_isLoading && _currentImageUrl != null && _currentSnaps.isNotEmpty)
                    Positioned(
                      top: topPad + 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: List.generate(_currentSnaps.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < _currentSnaps.length - 1 ? 3 : 0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 2.5,
                                  child:
                                      i < _snapIndex
                                          ? Container(color: Colors.white)
                                          : i == _snapIndex
                                          ? AnimatedBuilder(
                                            animation: _progressController,
                                            builder: (_, __) =>
                                                LinearProgressIndicator(
                                                  value: _progressController.value,
                                                  backgroundColor:
                                                      Colors.white.withValues(alpha: 0.25),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(Colors.white),
                                                  minHeight: 2.5,
                                                ),
                                          )
                                          : Container(
                                            color: Colors.white.withValues(alpha: 0.25),
                                          ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // ── HEADER ──
                  if (!_isLoading && _currentImageUrl != null && snap != null)
                    _buildHeader(snap, isOwn, topPad),

                  // ── CAPTION ──
                  if (!_isLoading &&
                      _currentImageUrl != null &&
                      snap != null &&
                      snap.caption != null &&
                      snap.caption!.isNotEmpty)
                    Positioned(
                      bottom: botPad + (isOwn ? 72 : 104),
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          snap.caption!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                  // ── REACTION BAR (others) ──
                  if (!_isLoading && _currentImageUrl != null && !isOwn)
                    Positioned(
                      bottom: botPad + 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _ReactionBar(
                          selectedReaction: _selectedReaction,
                          isBrandSnap: widget.challengeId != null,
                          onReact: _react,
                        ),
                      ),
                    ),

                  // ── VIEWERS STRIP (own snap) ──
                  if (!_isLoading && _currentImageUrl != null && isOwn && snap != null)
                    Positioned(
                      bottom: botPad + 16,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showViewers,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.white70,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${snap.viewCount} ${snap.viewCount == 1 ? 'view' : 'views'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (snap.totalReactionCount > 0) ...[
                                    Container(
                                      width: 1,
                                      height: 12,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    Text(
                                      _buildReactionSummary(snap),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(dynamic snap, bool isOwn, double topPad) {
    final sender = _currentSender;
    final hasImage = sender != null &&
        ((sender.photoKey != null && sender.photoKey!.isNotEmpty) ||
         (sender.avatarKey != null && sender.avatarKey!.isNotEmpty));

    return Positioned(
      top: topPad + 22,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: ClipOval(
                child:
                    hasImage
                        ? FutureBuilder<String?>(
                          future: _getAvatarFuture(),
                          builder: (context, snapshot) {
                            final url = snapshot.data;
                            if (url != null && url.isNotEmpty) {
                              return CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _avatarFallback(
                                  sender.displayName,
                                ),
                                errorWidget: (_, __, ___) => _avatarFallback(
                                  sender.displayName,
                                ),
                              );
                            }
                            return _avatarFallback(sender.displayName);
                          },
                        )
                        : _avatarFallback(sender?.displayName ?? 'User'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOwn ? 'You' : (sender?.displayName ?? 'User'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    if (snap is SpaceSenderSnap && snap.habitName != null) ...[
                      Text(
                        snap.habitName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.white70,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: Colors.white38, fontSize: 11.5),
                      ),
                    ],
                    Text(
                      _timeAgo(snap.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _HeaderButton(icon: Icons.more_horiz_rounded, onTap: _showOptions),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  OPTION TILE (for report/block sheet)
// ══════════════════════════════════════════════════════════════════
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
            const Icon(
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
//  VIEWERS SHEET — Instagram-style "Seen by" with reactions
// ══════════════════════════════════════════════════════════════════
class _SnapViewersSheet extends StatefulWidget {
  final String snapId;
  final dynamic snap;
  final SnapCubit snapCubit;
  final String currentUserId;
  final VoidCallback onDelete;
  final bool isBrandSnap;

  const _SnapViewersSheet({
    required this.snapId,
    required this.snap,
    required this.snapCubit,
    required this.currentUserId,
    required this.onDelete,
    this.isBrandSnap = false,
  });

  @override
  State<_SnapViewersSheet> createState() => _SnapViewersSheetState();
}

class _SnapViewersSheetState extends State<_SnapViewersSheet> {
  List<Map<String, dynamic>> _viewers = [];
  int _totalCount = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _nextCursor;
  bool _hasMore = false;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic> response = await widget.snapCubit.getSnapViewers(
      widget.snapId,
      isBrandSnap: widget.isBrandSnap,
      limit: _pageSize,
    );

    if (mounted) {
      final viewers = (response['viewers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final filteredViewers =
          viewers.where((v) => v['viewer_id'] != widget.currentUserId).toList();

      setState(() {
        _viewers = filteredViewers;
        _totalCount = response['view_count'] as int? ?? 0;
        _nextCursor = response['next_cursor'] as String?;
        _hasMore = response['has_more'] as bool? ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;

    setState(() {
      _loadingMore = true;
    });

    final Map<String, dynamic> response = await widget.snapCubit.getSnapViewers(
      widget.snapId,
      isBrandSnap: widget.isBrandSnap,
      limit: _pageSize,
      afterViewedAt: _nextCursor,
    );

    if (mounted) {
      final newViewers = (response['viewers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final filteredNewViewers =
          newViewers.where((v) => v['viewer_id'] != widget.currentUserId).toList();

      setState(() {
        _viewers.addAll(filteredNewViewers);
        _nextCursor = response['next_cursor'] as String?;
        _hasMore = response['has_more'] as bool? ?? false;
        _loadingMore = false;
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 30) return 'Just now';
    if (d.inMinutes < 1) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final snap = widget.snap;
    final viewerCount = _loading ? null : _totalCount;

    // Reaction totals
    final reactionTotals = <SnapReaction, int>{};
    for (final r in SnapReaction.values) {
      final c = _reactionCount(snap, r.value);
      if (c > 0) reactionTotals[r] = c;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: botPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seen by',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    if (_loading)
                      Text(
                        'loading…',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        '$viewerCount ${viewerCount == 1 ? 'person' : 'people'} ${_viewers.isNotEmpty && _hasMore ? '(showing ${_viewers.length})' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (reactionTotals.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactionTotals.entries
                        .map(
                          (e) => Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.key.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${e.value}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentRed.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppTheme.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.accentRed,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.outline, height: 1),

          // Viewer list
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          else if (_viewers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Text('👀', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(
                    'No views yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be patient… 👻',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _viewers.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  // Load more button at the end
                  if (i == _viewers.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _loadingMore ? null : _loadMore,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: _loadingMore
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryColor,
                                        ),
                                      )
                                    : Text(
                                        'Load more',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onBackground,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final v = _viewers[i];
                  final name = v['viewer_name'] as String? ?? 'User';
                  final avatarKey = v['avatar_key'] as String?;
                  final photoKey = v['photo_key'] as String?;
                  final reaction = v['reaction'] as String?;
                  final viewedAt = v['viewed_at'] != null
                      ? DateTime.tryParse(v['viewed_at'].toString())
                      : null;
                  final emoji = reaction != null
                      ? SnapReactionExt.fromString(reaction).emoji
                      : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        _ViewerAvatar(
                          name: name,
                          avatarKey: avatarKey,
                          photoKey: photoKey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              if (viewedAt != null)
                                Text(
                                  _timeAgo(viewedAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (emoji != null)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surfaceVariant,
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          )
                        else
                          const SizedBox(width: 36),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _reactionCount(dynamic snap, String type) {
    if (snap is SpaceSenderSnap) {
      return snap.reactionCount(type);
    }
    if (snap is ChallengeSenderSnap) {
      switch (type) {
        case 'fire':
          return snap.fireCount;
        case 'strong':
          return snap.flexCount;
        case 'heart':
          return snap.heartCount;
        default:
          return 0;
      }
    }
    return 0;
  }
}

// ══════════════════════════════════════════════════════════════════
//  LOADING SHIMMER
// ══════════════════════════════════════════════════════════════════
class _SnapLoadingShimmer extends StatefulWidget {
  final double topPad;
  const _SnapLoadingShimmer({required this.topPad});

  @override
  State<_SnapLoadingShimmer> createState() => _SnapLoadingShimmerState();
}

class _SnapLoadingShimmerState extends State<_SnapLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final t = _shimmer.value;
        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.5 + t * 3, 0),
                      end: Alignment(-0.5 + t * 3, 0),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              const Center(child: Text('👻', style: TextStyle(fontSize: 40))),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HEADER BUTTON
// ══════════════════════════════════════════════════════════════════
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  REACTION BAR — space reactions: fire, strong, laugh, eyes, heart
// ══════════════════════════════════════════════════════════════════
class _ReactionBar extends StatelessWidget {
  final SnapReaction? selectedReaction;
  final bool isBrandSnap;
  final void Function(SnapReaction) onReact;

  const _ReactionBar({
    required this.selectedReaction,
    required this.isBrandSnap,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final reactions =
        isBrandSnap
            ? const <SnapReaction>[
              SnapReaction.fire,
              SnapReaction.strong,
              SnapReaction.heart,
            ]
            : SnapReaction.values;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions
            .map(
              (r) => _ReactionButton(
                reaction: r,
                isSelected: selectedReaction == r,
                onTap: () => onReact(r),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final SnapReaction reaction;
  final bool isSelected;
  final VoidCallback onTap;
  const _ReactionButton({
    required this.reaction,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.55, end: 0.82), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ReactionButton old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) _ctrl.forward(from: 0);
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: selected ? 52 : 44,
          height: selected ? 52 : 44,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.reaction.emoji,
              style: TextStyle(fontSize: selected ? 26 : 22),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  VIEWER AVATAR
// ══════════════════════════════════════════════════════════════════
class _ViewerAvatar extends StatelessWidget {
  final String name;
  final String? avatarKey;
  final String? photoKey;

  const _ViewerAvatar({required this.name, this.avatarKey, this.photoKey});

  @override
  Widget build(BuildContext context) {
    if (photoKey != null && photoKey!.isNotEmpty) {
      final url = context.read<ProfileService>().getProfilePhotoUrl(photoKey!);
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceVariant,
          border: Border.all(color: AppTheme.outline),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => _fallback(name),
            errorWidget: (_, __, ___) => _fallback(name),
          ),
        ),
      );
    }

    if (avatarKey != null && avatarKey!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceVariant,
          border: Border.all(color: AppTheme.outline),
        ),
        child: FutureBuilder<String?>(
          future: context.read<ProfileService>().getAvatarUrl(avatarKey!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null) {
              return _fallback(name);
            } else {
              return ClipOval(
                child: CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _fallback(name),
                  errorWidget: (_, __, ___) => _fallback(name),
                ),
              );
            }
          },
        ),
      );
    }

    return _fallback(name);
  }

  Widget _fallback(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceVariant,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.onBackground,
          ),
        ),
      ),
    );
  }
}
