// ════════════════════════════════════════════════════════════════════
// challenge_pulse.dart — Brand Pulse media post + reactions
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import '../../cubits/brand_challenge_cubit.dart';
import 'challenge_helpers.dart';

class ChallengePulseSection extends StatelessWidget {
  final PulsePostModel post;
  final BrandModel brand;
  final BrandThemeData theme;
  final double s;

  const ChallengePulseSection({
    super.key,
    required this.post,
    required this.brand,
    required this.theme,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('BRAND PULSE', s),
        SizedBox(height: 10 * s),
        Container(
          height: 260 * s,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media area
              if ((post.isVideo || post.isReel) && post.mediaUrl != null)
                CachedPulseVideo(videoUrl: post.mediaUrl!, thumbnailUrl: post.thumbnailUrl)
              else if (post.thumbnailUrl != null || (post.mediaUrl?.isNotEmpty == true))
                CachedNetworkImage(
                  imageUrl: (post.thumbnailUrl?.isNotEmpty == true) ? post.thumbnailUrl! : post.mediaUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [accent.withValues(alpha: 0.5), const Color(0xFF0D0D0D)]),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [accent.withValues(alpha: 0.5), const Color(0xFF0D0D0D)]),
                  ),
                ),

              // Bottom shadow
              Positioned(
                bottom: 0, left: 0, right: 0, height: 120 * s,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),

              // Duration badge
              if ((post.isVideo || post.isReel) && post.durationSeconds != null)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '0:${post.durationSeconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),

              // Caption + reactions
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          AnimatedReactionPill(
                            emoji: '🔥', count: post.reactions.fire, active: post.reactedFire, accent: accent,
                            onTap: () { HapticFeedback.lightImpact(); context.read<BrandChallengeCubit>().reactToPulse(post.id, 'fire', post.myReaction); },
                          ),
                          const SizedBox(width: 8),
                          AnimatedReactionPill(
                            emoji: '💪', count: post.reactions.flex, active: post.reactedFlex, accent: accent,
                            onTap: () { HapticFeedback.lightImpact(); context.read<BrandChallengeCubit>().reactToPulse(post.id, 'flex', post.myReaction); },
                          ),
                          const SizedBox(width: 8),
                          AnimatedReactionPill(
                            emoji: '❤️', count: post.reactions.heart, active: post.reactedHeart, accent: accent,
                            onTap: () { HapticFeedback.lightImpact(); context.read<BrandChallengeCubit>().reactToPulse(post.id, 'heart', post.myReaction); },
                          ),
                          if (post.productUrl != null) ...[
                            const Spacer(),
                            SizedBox(
                              height: 24,
                              child: ElevatedButton.icon(
                                onPressed: () => launchUrl(Uri.parse(post.productUrl!), mode: LaunchMode.externalApplication),
                                icon: const Icon(Icons.shopping_bag_rounded, size: 12),
                                label: Text('Shop', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent, foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CachedPulseVideo — Handles proper video caching + muted autoplay
// ═══════════════════════════════════════════════════════════════════

class CachedPulseVideo extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  const CachedPulseVideo({Key? key, required this.videoUrl, this.thumbnailUrl}) : super(key: key);
  @override
  State<CachedPulseVideo> createState() => _CachedPulseVideoState();
}

class _CachedPulseVideoState extends State<CachedPulseVideo> {
  VideoPlayerController? _controller;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      if (!mounted) return;
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      if (!mounted) return;
      await _controller!.setLooping(true);
      await _controller!.setVolume(0.0);
      setState(() {});
      _controller!.play();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.thumbnailUrl != null
          ? CachedNetworkImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
          : Container(color: Colors.black12);
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Stack(fit: StackFit.expand, children: [
        if (widget.thumbnailUrl != null) CachedNetworkImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover),
        const Center(child: CupertinoActivityIndicator(color: Colors.white)),
      ]);
    }
    return Stack(fit: StackFit.expand, children: [
      FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width, height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
      Positioned(
        bottom: 12, left: 12,
        child: GestureDetector(
          onTap: _toggleMute,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
            child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 16),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// AnimatedReactionPill — Tap-to-react emoji pill
// ═══════════════════════════════════════════════════════════════════

class AnimatedReactionPill extends StatefulWidget {
  final String emoji;
  final int count;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const AnimatedReactionPill({
    super.key,
    required this.emoji, required this.count, required this.active,
    required this.accent, required this.onTap,
  });

  @override
  State<AnimatedReactionPill> createState() => _AnimatedReactionPillState();
}

class _AnimatedReactionPillState extends State<AnimatedReactionPill> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedReactionPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _ctrl.forward().then((_) => _ctrl.reverse());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.active ? widget.accent.withOpacity(0.15) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active ? widget.accent : Colors.white.withOpacity(0.08), width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: widget.active ? FontWeight.w900 : FontWeight.w700,
                  color: widget.active ? widget.accent : Colors.white.withOpacity(0.8),
                ),
                child: Text(widget.count >= 1000 ? '${(widget.count / 1000).toStringAsFixed(1)}K' : '${widget.count}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
