import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/solo_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';

/// ✨ Premium Challenge Result Card
/// Shown when a challenge has ended — distinct success & failure states.
/// Handles solo, couple, and group space types from [EndedHabit.spaceType].
class ChallengeResultCard extends StatefulWidget {
  final EndedHabit habit;
  final VoidCallback onDismiss;

  const ChallengeResultCard({
    super.key,
    required this.habit,
    required this.onDismiss,
  });

  @override
  State<ChallengeResultCard> createState() => _ChallengeResultCardState();
}

class _ChallengeResultCardState extends State<ChallengeResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _scaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.habit.isCompleted;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: Transform.scale(
            scale: _scaleIn.value,
            child: Opacity(opacity: _fadeIn.value, child: child),
          ),
        );
      },
      child:
          isCompleted
              ? _SuccessResultCard(
                habit: widget.habit,
                onDismiss: widget.onDismiss,
              )
              : _FailureResultCard(
                habit: widget.habit,
                onDismiss: widget.onDismiss,
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏆 SUCCESS CARD — Futuristic gradient, confetti Lottie on celebrate
// ═══════════════════════════════════════════════════════════════════════════
class _SuccessResultCard extends StatefulWidget {
  final EndedHabit habit;
  final VoidCallback onDismiss;

  const _SuccessResultCard({required this.habit, required this.onDismiss});

  @override
  State<_SuccessResultCard> createState() => _SuccessResultCardState();
}

class _SuccessResultCardState extends State<_SuccessResultCard>
    with TickerProviderStateMixin {
  bool _showLottie = false;
  bool _dismissed = false;
  late AnimationController _lottieOpacity;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _lottieOpacity = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _lottieOpacity.dispose();
    super.dispose();
  }

  void _onCelebrate() {
    if (_dismissed) return;
    setState(() {
      _showLottie = true;
      _dismissed = true;
    });
    _lottieOpacity.forward();

    // After 3 seconds: fade out the Lottie, then dismiss
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _lottieOpacity.reverse().then((_) {
        if (mounted) {
          widget.onDismiss();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final pct = habit.completionPct.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.rs(context)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.rs(context)),
        child: Stack(
          children: [
            // ── Main Card ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.rs(context)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D9F6E),
                    Color(0xFF059669),
                    Color(0xFF047857),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.30),
                    blurRadius: 28.rs(context),
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    blurRadius: 56.rs(context),
                    offset: const Offset(0, 20),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ── Confetti-style decorative dots ──
                  ..._buildConfettiDots(habit),

                  // ── Subtle radial glow ──
                  Positioned(
                    top: -50,
                    right: -40,
                    child: Container(
                      width: 160.rs(context),
                      height: 160.rs(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.14),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom-left glow accent ──
                  Positioned(
                    bottom: -30,
                    left: -20,
                    child: Container(
                      width: 100.rs(context),
                      height: 100.rs(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Content ──
                  Padding(
                    padding: EdgeInsets.all(22.rs(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top: Badge + Emoji ──
                        Row(
                          children: [
                            // Trophy container with glass effect
                            Container(
                              width: 52.rs(context),
                              height: 52.rs(context),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                  18.rs(context),
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.2.rs(context),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  habit.emoji,
                                  style: TextStyle(fontSize: 26.rs(context)),
                                ),
                              ),
                            ),
                            SizedBox(width: 14.rs(context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18.rs(context),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                      height: 1.2.rs(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6.rs(context)),
                                  Row(
                                    children: [
                                      _buildGlassPill(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '🏆',
                                              style: TextStyle(
                                                fontSize: 11.rs(context),
                                              ),
                                            ),
                                            SizedBox(width: 4.rs(context)),
                                            Text(
                                              'Challenge Complete!',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.rs(context),
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 6.rs(context)),
                                      _buildSpaceTag(context, habit),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.rs(context)),

                        // ── Stats row — glass morphism style ──
                        Container(
                          padding: EdgeInsets.all(14.rs(context)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18.rs(context)),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.rs(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              _SuccessStatItem(
                                value: '${habit.daysCompleted}',
                                label: 'Days Done',
                                icon: Icons.check_circle_rounded,
                              ),
                              _buildVerticalDivider(context),
                              _SuccessStatItem(
                                value: '${habit.daysMissed}',
                                label: 'Missed',
                                icon: Icons.remove_circle_outline_rounded,
                              ),
                              _buildVerticalDivider(context),
                              _SuccessStatItem(
                                value: '${habit.bestStreak}',
                                label: 'Best Streak',
                                icon: Icons.local_fire_department_rounded,
                              ),
                            ],
                          ),
                        ),

                        // ── Couple partner comparison ──
                        if ((habit.isCouple || habit.isGroup) &&
                            (habit.partnerDaysCompleted != null ||
                                habit.partnerCompletionPct != null))
                          Padding(
                            padding: EdgeInsets.only(top: 12.rs(context)),
                            child: _SuccessPartnerComparison(habit: habit),
                          ),

                        SizedBox(height: 14.rs(context)),

                        // ── Completion bar ──
                        _SuccessProgressBar(
                          pct: pct,
                          label:
                              (habit.isCouple || habit.isGroup) ? 'Your Completion' : 'Completion',
                        ),

                        // ── Partner progress bar (couple only) ──
                        if ((habit.isCouple || habit.isGroup) &&
                            habit.partnerCompletionPct != null) ...[
                          SizedBox(height: 10.rs(context)),
                          _SuccessProgressBar(
                            pct: habit.partnerCompletionPct!.clamp(0, 100),
                            label: habit.isGroup ? "Group's Completion" : "Partner's Completion",
                            isPartner: true,
                          ),
                        ],

                        SizedBox(height: 18.rs(context)),

                        // ── Celebrate button ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _dismissed ? null : _onCelebrate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF059669),
                              disabledBackgroundColor: Colors.white.withValues(
                                alpha: 0.7,
                              ),
                              disabledForegroundColor: const Color(
                                0xFF059669,
                              ).withValues(alpha: 0.5),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: 15.rs(context),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16.rs(context),
                                ),
                              ),
                            ),
                            child: Text(
                              _dismissed ? '🎊 Celebrating...' : 'Celebrate 🎉',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.rs(context),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 🎊 Lottie Confetti Overlay — plays 3s then fades ──
            if (_showLottie)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _lottieOpacity,
                  child: IgnorePointer(
                    child: DotLottieLoader.fromAsset(
                      'assets/LottieAnimations/Confetti.lottie',
                      frameBuilder: (ctx, dotlottie) {
                        if (dotlottie != null) {
                          return Lottie.memory(
                            dotlottie.animations.values.single,
                            fit: BoxFit.cover,
                            repeat: true,
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPill({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.rs(context),
        vertical: 4.rs(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.rs(context)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5.rs(context),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSpaceTag(BuildContext context, EndedHabit habit) {
    String label = ' Solo';
    if (habit.isCouple) {
      label = ' Duo';
    } else if (habit.isGroup) {
      label = ' Squad';
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.rs(context),
        vertical: 4.rs(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.rs(context)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.rs(context),
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      width: 1.rs(context),
      height: 32.rs(context),
      margin: EdgeInsets.symmetric(horizontal: 2.rs(context)),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  List<Widget> _buildConfettiDots(EndedHabit habit) {
    final rng = Random(habit.id.hashCode);
    final dots = <Widget>[];
    const colors = [
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
      Color(0xFF60A5FA),
      Color(0xFF34D399),
      Color(0xFFA78BFA),
      Color(0xFFFB923C),
    ];

    for (int i = 0; i < 14; i++) {
      final size = 4.0 + rng.nextDouble() * 5;
      final isCircle = rng.nextBool();
      dots.add(
        Positioned(
          top: rng.nextDouble() * 280,
          left: rng.nextDouble() * 400,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors[rng.nextInt(colors.length)].withValues(
                alpha: 0.25 + rng.nextDouble() * 0.15,
              ),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius:
                  isCircle ? null : BorderRadius.circular(2.rs(context)),
            ),
          ),
        ),
      );
    }
    return dots;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 😔 FAILURE CARD — Muted, clean, respectful, futuristic
// ═══════════════════════════════════════════════════════════════════════════
class _FailureResultCard extends StatelessWidget {
  final EndedHabit habit;
  final VoidCallback onDismiss;

  const _FailureResultCard({required this.habit, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final pct = habit.completionPct.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.rs(context)),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28.rs(context)),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.6),
          width: 1.rs(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20.rs(context),
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top section with subtle warm gradient ──
          Container(
            padding: EdgeInsets.all(22.rs(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                  const Color(0xFFFFF7ED).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(27),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top: Icon + Name ──
                Row(
                  children: [
                    Container(
                      width: 52.rs(context),
                      height: 52.rs(context),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18.rs(context)),
                        border: Border.all(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          width: 1.rs(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          habit.emoji,
                          style: TextStyle(fontSize: 26.rs(context)),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.rs(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.rs(context),
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onBackground,
                              letterSpacing: -0.3,
                              height: 1.2.rs(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.rs(context)),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.rs(context),
                                  vertical: 4.rs(context),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                    20.rs(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '⏰',
                                      style: TextStyle(
                                        fontSize: 11.rs(context),
                                      ),
                                    ),
                                    SizedBox(width: 4.rs(context)),
                                    Text(
                                      'Challenge Ended',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.rs(context),
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6.rs(context)),
                              _buildFailureSpaceTag(context, habit),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.rs(context)),

                // ── Motivational message ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.rs(context),
                    vertical: 12.rs(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.onBackground.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14.rs(context)),
                    border: Border.all(
                      color: AppTheme.onBackground.withValues(alpha: 0.04),
                      width: 0.5.rs(context),
                    ),
                  ),
                  child: Text(
                    pct >= 50
                        ? '💪 You gave it a real shot — ${pct.toStringAsFixed(0)}% is solid progress!'
                        : '🌱 Every attempt plants a seed. You\'ll crush it next time.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.rs(context),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4.rs(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Stats section ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              22.rs(context),
              4.rs(context),
              22.rs(context),
              0.rs(context),
            ),
            child: Row(
              children: [
                _FailureStatItem(
                  value: '${habit.daysCompleted}',
                  label: 'Done',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_rounded,
                ),
                SizedBox(width: 8.rs(context)),
                _FailureStatItem(
                  value: '${habit.daysMissed}',
                  label: 'Missed',
                  color: const Color(0xFFEF4444),
                  icon: Icons.close_rounded,
                ),
                SizedBox(width: 8.rs(context)),
                _FailureStatItem(
                  value: '${habit.bestStreak}',
                  label: 'Best Streak',
                  color: const Color(0xFFF97316),
                  icon: Icons.local_fire_department_rounded,
                ),
              ],
            ),
          ),

          // ── Couple partner comparison ──
          if ((habit.isCouple || habit.isGroup) &&
              (habit.partnerDaysCompleted != null ||
                  habit.partnerCompletionPct != null))
            Padding(
              padding: EdgeInsets.fromLTRB(
                22.rs(context),
                12.rs(context),
                22.rs(context),
                0.rs(context),
              ),
              child: _FailurePartnerComparison(habit: habit),
            ),

          // ── Completion bar ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              22.rs(context),
              14.rs(context),
              22.rs(context),
              0.rs(context),
            ),
            child: _FailureProgressBar(
              pct: pct,
              label: (habit.isCouple || habit.isGroup) ? 'Your Completion' : 'Completion',
            ),
          ),

          // ── Partner progress bar (couple only) ──
          if ((habit.isCouple || habit.isGroup) && habit.partnerCompletionPct != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                22.rs(context),
                10.rs(context),
                22.rs(context),
                0.rs(context),
              ),
              child: _FailureProgressBar(
                pct: habit.partnerCompletionPct!.clamp(0, 100),
                label: habit.isGroup ? "Group's Completion" : "Partner's Completion",
                color: const Color(0xFF6B6BE0),
              ),
            ),

          // ── Dismiss button ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              22.rs(context),
              18.rs(context),
              22.rs(context),
              22.rs(context),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onBackground,
                  padding: EdgeInsets.symmetric(vertical: 15.rs(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.rs(context)),
                  ),
                  side: BorderSide(
                    color: AppTheme.outline.withValues(alpha: 0.5),
                    width: 1.2.rs(context),
                  ),
                ),
                child: Text(
                  'Got it 👍',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.rs(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureSpaceTag(BuildContext context, EndedHabit habit) {
    String label = ' Solo';
    if (habit.isCouple) {
      label = ' Duo';
    } else if (habit.isGroup) {
      label = ' Squad';
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.rs(context),
        vertical: 4.rs(context),
      ),
      decoration: BoxDecoration(
        color: AppTheme.onBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.rs(context)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.rs(context),
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SUBWIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Single stat item for success card (white on green)
class _SuccessStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SuccessStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16.rs(context),
            color: Colors.white.withValues(alpha: 0.70),
          ),
          SizedBox(height: 4.rs(context)),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.rs(context),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1.rs(context),
            ),
          ),
          SizedBox(height: 2.rs(context)),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.rs(context),
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single stat item for failure card (muted colors)
class _FailureStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _FailureStatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12.rs(context),
          horizontal: 8.rs(context),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.rs(context)),
          border: Border.all(
            color: color.withValues(alpha: 0.08),
            width: 1.rs(context),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 15.rs(context),
              color: color.withValues(alpha: 0.6),
            ),
            SizedBox(height: 4.rs(context)),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.rs(context),
                fontWeight: FontWeight.w900,
                color: AppTheme.onBackground,
                height: 1.1.rs(context),
              ),
            ),
            SizedBox(height: 2.rs(context)),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.rs(context),
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success card progress bar
class _SuccessProgressBar extends StatelessWidget {
  final double pct;
  final String label;
  final bool isPartner;

  const _SuccessProgressBar({
    required this.pct,
    required this.label,
    this.isPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    final barColor =
        isPartner ? Colors.white.withValues(alpha: 0.60) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.rs(context),
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.rs(context),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.rs(context)),
        Container(
          height: 6.rs(context),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6.rs(context)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (pct / 100.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6.rs(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Failure card progress bar
class _FailureProgressBar extends StatelessWidget {
  final double pct;
  final String label;
  final Color color;

  const _FailureProgressBar({
    required this.pct,
    required this.label,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.rs(context),
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.rs(context),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.rs(context)),
        Container(
          height: 6.rs(context),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6.rs(context)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (pct / 100.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6.rs(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Partner comparison row for SUCCESS card (white-on-green)
class _SuccessPartnerComparison extends StatelessWidget {
  final EndedHabit habit;
  const _SuccessPartnerComparison({required this.habit});

  @override
  Widget build(BuildContext context) {
    String partnerLabel = 'Partner';
    if (habit.isGroup) {
      partnerLabel = 'Group';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.rs(context),
        vertical: 12.rs(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16.rs(context)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.rs(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ComparisonSide(
              label: 'You',
              value: '${habit.daysCompleted}d',
              valueColor: Colors.white,
              labelColor: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.rs(context),
              vertical: 4.rs(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.rs(context)),
            ),
            child: Text(
              'VS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.rs(context),
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.80),
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: _ComparisonSide(
              label: partnerLabel,
              value: '${habit.partnerDaysCompleted ?? 0}d',
              valueColor: Colors.white.withValues(alpha: 0.85),
              labelColor: Colors.white.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }
}

/// Partner comparison row for FAILURE card
class _FailurePartnerComparison extends StatelessWidget {
  final EndedHabit habit;
  const _FailurePartnerComparison({required this.habit});

  @override
  Widget build(BuildContext context) {
    String partnerLabel = 'Partner';
    if (habit.isGroup) {
      partnerLabel = 'Group';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.rs(context),
        vertical: 12.rs(context),
      ),
      decoration: BoxDecoration(
        color: AppTheme.onBackground.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.rs(context)),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.4),
          width: 1.rs(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ComparisonSide(
              label: 'You',
              value: '${habit.daysCompleted}d',
              valueColor: const Color(0xFFF59E0B),
              labelColor: AppTheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.rs(context),
              vertical: 4.rs(context),
            ),
            decoration: BoxDecoration(
              color: AppTheme.onBackground.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.rs(context)),
            ),
            child: Text(
              'VS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.rs(context),
                fontWeight: FontWeight.w900,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: _ComparisonSide(
              label: partnerLabel,
              value: '${habit.partnerDaysCompleted ?? 0}d',
              valueColor: const Color(0xFF6B6BE0),
              labelColor: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared comparison side widget
class _ComparisonSide extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;

  const _ComparisonSide({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.rs(context),
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 3.rs(context)),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19.rs(context),
            fontWeight: FontWeight.w900,
            color: valueColor,
            height: 1.1.rs(context),
          ),
        ),
        Text(
          'completed',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.rs(context),
            fontWeight: FontWeight.w600,
            color: labelColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
