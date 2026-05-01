import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

// ─── TEXT STYLES ──────────────────────────────────────
class AppText {
  static TextStyle hero(double size, FontWeight w, Color c) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: size > 20 ? -0.8 : 0,
      );

  static TextStyle body(
    double size,
    Color c, {
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c);
}

// ─── HERO HEADER ──────────────────────────────────────
class HeroProgressBanner extends StatelessWidget {
  final int scheduled;
  final int done;
  final int remaining;
  final double topContentInset;

  const HeroProgressBanner({
    super.key,
    required this.scheduled,
    required this.done,
    required this.remaining,
    this.topContentInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        scheduled == 0 ? 0.0 : (done / scheduled).clamp(0.0, 1.0);

    // ── Layered Stack: gradient → ambient glow → matte overlay → content ──
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Layer 1: premium gradient base ──
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF130A2A),
                  const Color(0xFF24133F).withOpacity(0.92),
                  const Color(0xFF07030F),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // ── Layer 2: vibrant ambient glow orbs ──
        Positioned(
          top: 30,
          left: -90,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.midnightPrimary.withOpacity(0.65),
                  AppColors.midnightPrimary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -50,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.midnightFire.withOpacity(0.35),
                  AppColors.midnightFire.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.midnightPrimaryPale.withOpacity(0.25),
                  AppColors.midnightPrimaryPale.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // ── Layer 3: matte atmospheric overlay (no blur / no glass) ──
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x14000000), Color(0x3A000000)],
              ),
            ),
          ),
        ),

        // ── Layer 4: content (progress card) ──
        Padding(
          padding: EdgeInsets.fromLTRB(18, 10 + topContentInset, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress card: enhanced inner glass with better visibility ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF18112A).withValues(alpha: 0.94),
                  border: Border.all(
                    color: AppColors.midnightPrimaryPale.withValues(
                      alpha: 0.22,
                    ),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Title + arc
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TODAY'S PROGRESS",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.midnightPrimaryPale
                                      .withValues(alpha: 0.82),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$done',
                                      style: AppText.hero(
                                        28,
                                        FontWeight.w700,
                                        AppColors.midnightPrimaryPale,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' done',
                                      style: AppText.hero(
                                        28,
                                        FontWeight.w700,
                                        Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scheduled == 0
                                    ? 'no habits assigned today'
                                    : remaining > 0
                                    ? '$remaining more to crush today'
                                    : 'all habits done! 🎉',
                                style: AppText.body(
                                  13,
                                  Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ArcProgress(progress: progress),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress bar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder:
                          (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: v.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.midnightPrimary,
                                        AppColors.midnightPrimaryPale,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.midnightPrimary
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(99),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),

                    const SizedBox(height: 16),

                    // 3 stats
                    Row(
                      children: [
                        _StatBlock(
                          value: '$scheduled',
                          label: 'scheduled',
                          valueColor: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _StatBlock(
                          value: '$done',
                          label: 'done',
                          valueColor: const Color(0xFF6FCF97),
                        ),
                        const SizedBox(width: 8),
                        _StatBlock(
                          value: '$remaining',
                          label: 'left',
                          valueColor: const Color(0xFFFF9F47),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ARC PROGRESS ─────────────────────────────────────
class _ArcProgress extends StatelessWidget {
  final double progress;
  const _ArcProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final percentFontSize = pct >= 100 ? 14.0 : 16.0;
    return SizedBox(
      width: 68,
      height: 68,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder:
            (_, v, __) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(68, 68),
                  painter: _ArcPainter(progress: v),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$pct%',
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: percentFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'done',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 28.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = AppColors.midnightPrimaryLight
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── HERO ACTION BUTTON ───────────────────────────────
class _HeroActionBtn extends StatelessWidget {
  final IconData icon;
  const _HeroActionBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.5),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
    );
  }
}

// ─── STAT BLOCK ───────────────────────────────────────
class _StatBlock extends StatelessWidget {
  final String value, label;
  final Color valueColor;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
