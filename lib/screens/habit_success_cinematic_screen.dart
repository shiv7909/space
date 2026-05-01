import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cinematic_payload.dart';

export 'cinematic_payload.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class HabitSuccessCinematicScreen extends StatefulWidget {
  final CinematicPayload payload;

  const HabitSuccessCinematicScreen({super.key, required this.payload});

  /// Push with a smooth fade transition.
  static Route<void> route(CinematicPayload payload) {
    return PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      pageBuilder:
          (context, animation, _) => FadeTransition(
            opacity: animation,
            child: HabitSuccessCinematicScreen(payload: payload),
          ),
    );
  }

  @override
  State<HabitSuccessCinematicScreen> createState() =>
      _HabitSuccessCinematicScreenState();
}

class _HabitSuccessCinematicScreenState
    extends State<HabitSuccessCinematicScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const Curve _appleEase = Cubic(0.22, 0.68, 0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSwipeUp(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -200) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;

    // ── Route to error screen if the operation failed ──
    if (!p.success) {
      return _buildErrorScreen(context, p);
    }

    final habit = p.habit;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: _onSwipeUp,
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Main content column ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Phase 1 – The Hero emoji
                      _HeroShape(
                        emoji: habit.emoji,
                        success: p.success,
                        curve: _appleEase,
                      ),

                      const SizedBox(height: 28),

                      // Phase 2 – Habit name
                      _HabitNameWidget(name: habit.name, curve: _appleEase),

                      const SizedBox(height: 24),

                      // Phase 3 – Glass details card with why_reason + mode + schedule
                      _GlassDetailsCard(
                        whyReason: habit.whyReason ?? '',
                        mode: habit.mode,
                        scheduledDays: habit.scheduledDays,
                        targetDays: habit.targetDays,
                      ),

                      const SizedBox(height: 22),

                      // Phase 4 – Space vibe
                      _SpaceVibeText(spaceType: p.spaceType),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),

                // Phase 5 – Swipe‑up hint
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: _PulsingHint(controller: _pulseController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Error screen
  // ──────────────────────────────────────────────────────────────────────────────

  Widget _buildErrorScreen(BuildContext context, CinematicPayload p) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tiny banner at the top ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Text(
                p.errorMessage ?? 'Something went wrong. Try again.',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // ── Retry button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement retry logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69F0AE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 1 – Hero shape / emoji
// ──────────────────────────────────────────────────────────────────────────────

class _HeroShape extends StatelessWidget {
  final String emoji;
  final bool success;
  final Curve curve;

  const _HeroShape({
    required this.emoji,
    required this.success,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 120.0;

    final glowColor =
        success ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);

    return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.18),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Text(emoji, style: TextStyle(fontSize: size * 0.75)),
        )
        .animate()
        .fadeIn(duration: 800.ms, curve: curve)
        .scaleXY(begin: 0.15, end: 1.0, duration: 1100.ms, curve: curve)
        .then(delay: 200.ms)
        .shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.12),
        );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 2 – Habit name
// ──────────────────────────────────────────────────────────────────────────────

class _HabitNameWidget extends StatelessWidget {
  final String name;
  final Curve curve;

  const _HabitNameWidget({required this.name, required this.curve});

  @override
  Widget build(BuildContext context) {
    return Text(
          name.toLowerCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.1,
          ),
        )
        .animate(delay: 900.ms)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.35, end: 0, duration: 700.ms, curve: curve);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 3 – Glassmorphism details card
// ──────────────────────────────────────────────────────────────────────────────

class _GlassDetailsCard extends StatelessWidget {
  final String whyReason;
  final String mode;
  final List<int> scheduledDays;
  final int? targetDays;

  const _GlassDetailsCard({
    required this.whyReason,
    required this.mode,
    required this.scheduledDays,
    this.targetDays,
  });

  String _formatSchedule() {
    if (scheduledDays.length == 7) return 'Every day';
    if (scheduledDays.length == 5 &&
        !scheduledDays.contains(6) &&
        !scheduledDays.contains(7))
      return 'Weekdays';
    if (scheduledDays.length == 2 &&
        scheduledDays.contains(6) &&
        scheduledDays.contains(7))
      return 'Weekends';
    final labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return scheduledDays.map((d) => labels[d] ?? '').join(', ');
  }

  String _formatMode() {
    if (mode == 'challenge' && targetDays != null) {
      return '$targetDays-day challenge';
    }
    return mode == 'challenge' ? 'Challenge' : 'Forever';
  }

  @override
  Widget build(BuildContext context) {
    final hasWhy = whyReason.isNotEmpty;

    return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Why Reason — hero of the card ──
                  if (hasWhy) ...[
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFBBF24,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('💡', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'your why',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '"$whyReason"',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFBBF24),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Mode + Schedule row ──
                  Row(
                    children: [
                      Expanded(
                        child: _DetailChip(
                          icon: mode == 'challenge' ? '🎯' : '∞',
                          label: _formatMode(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailChip(
                          icon: '📅',
                          label: _formatSchedule(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: 1500.ms)
        .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 24, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }
}

class _DetailChip extends StatelessWidget {
  final String icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 4 – Space vibe text
// ──────────────────────────────────────────────────────────────────────────────

class _SpaceVibeText extends StatelessWidget {
  final String spaceType;

  const _SpaceVibeText({required this.spaceType});

  @override
  Widget build(BuildContext context) {
    final isSolo = spaceType.toLowerCase() == 'solo';
    final text =
        isSolo
            ? 'main character energy activated ✨\nsolo grind starts now.'
            : 'squad goals unlocked 🚀';

    return Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: -0.2,
          ),
        )
        .animate(delay: 2100.ms)
        .fadeIn(duration: 600.ms)
        .moveY(begin: 14, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 5 – Pulsing swipe‑up hint
// ──────────────────────────────────────────────────────────────────────────────

class _PulsingHint extends StatelessWidget {
  final AnimationController controller;

  const _PulsingHint({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final dy = Tween<double>(begin: 0, end: -8).evaluate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        );
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white.withValues(alpha: 0.4),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            'swipe up to begin',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate(delay: 2800.ms).fadeIn(duration: 600.ms);
  }
}
