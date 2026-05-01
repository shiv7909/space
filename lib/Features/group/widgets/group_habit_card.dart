import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../models/dashboard_model.dart';
import '../../shared/habit_shape_widget.dart';

/// 👥 GROUP HABIT CARD — 2-layer information hierarchy
/// Layer 1: Always visible (header, message pill, progress bar, stats)
/// Layer 2: Full detail screen via onTap callback
class GroupHabitCard extends StatefulWidget {
  final DashboardHabit habit;
  final VoidCallback onTap;
  final Future<bool> Function() onMarkDone;
  final int index;
  final bool isLast;

  const GroupHabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onMarkDone,
    this.index = 0,
    this.isLast = false,
  });

  @override
  State<GroupHabitCard> createState() => _GroupHabitCardState();
}

class _GroupHabitCardState extends State<GroupHabitCard>
    with SingleTickerProviderStateMixin {
  bool _checkAnimating = false;
  bool _pressing = false;
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  // ✅ NEW: Reset animation when habit changes to prevent controller leaks
  @override
  void didUpdateWidget(GroupHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.id != widget.habit.id) {
      // Habit changed — reset animation state
      if (_checkAnimating) {
        _checkController.reset();
        setState(() => _checkAnimating = false);
      }
    }
  }

  void _handleMarkDone() async {
    if (_checkAnimating) return;
    HapticFeedback.mediumImpact();
    setState(() => _checkAnimating = true);
    await _checkController.forward();
    final success = await widget.onMarkDone();
    if (!success && mounted) {
      await _checkController.reverse();
      setState(() => _checkAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final isDone = h.isDoneToday;
    final isScheduled = h.isScheduledToday;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressing ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 14 * Responsive.scale(context)),
              padding: EdgeInsets.symmetric(horizontal: 16 * Responsive.scale(context), vertical: 14 * Responsive.scale(context)),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20 * Responsive.scale(context)),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ LAYER 1 — Always visible ═══
                  // Row 1: Emoji + Name + streak badge + action
                  _buildHeader(isDone, isScheduled),
                  const SizedBox(height: 12),
                  // Row 2: Thin group progress bar
                  _buildGroupProgressBar(),
                  const SizedBox(height: 12),
                  // Row 4: Stats row
                  _buildStatsRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── LAYER 1: HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDone, bool isScheduled) {
    final h = widget.habit;
    final showCheck = isScheduled && !isDone;
    return Row(
      children: [
        HabitShapeWidget(emoji: h.emoji, size: 24 * Responsive.scale(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            h.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5 * Responsive.scale(context),
              fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
              decoration: TextDecoration.none,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Group streak badge ──
        if (h.groupStreak > 0 && isScheduled && !isDone) ...[
          _buildGroupStreakBadge(),
          const SizedBox(width: 8),
        ],
        if (!isScheduled) _buildRestDayTag(),
        if (isDone) _buildDonePill(),
        if (showCheck) _buildInlineMarkDone(),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── LAYER 1: GROUP PROGRESS BAR
  // ═══════════════════════════════════════════════
  Widget _buildGroupProgressBar() {
    final h = widget.habit;
    if (!h.isScheduledToday) return const SizedBox.shrink();

    final done = h.doneTodayCount;
    final total = h.totalMembers;
    final threshold = h.streakThreshold;
    final fraction = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final thresholdFraction =
        (threshold > 0 && total > 0) ? (threshold / total).clamp(0.0, 1.0) : 0.0;

    final bool goalMet = threshold > 0 ? done >= threshold : (done == total && total > 0);
    final bool nearGoal = !goalMet && threshold > 0 && done >= threshold - 1;

    final Color barColor;
    final Color barColorEnd;
    final Color countColor;

    if (goalMet) {
      barColor    = AppTheme.accentGreen;
      barColorEnd = AppTheme.accentGreen;
      countColor  = AppTheme.accentGreen;
    } else if (nearGoal) {
      barColor    = AppTheme.accentAmber;
      barColorEnd = AppTheme.accentAmber;
      countColor  = AppTheme.accentAmber;
    } else {
      barColor    = AppTheme.primaryColor.withValues(alpha: 0.6);
      barColorEnd = AppTheme.primaryColor;
      countColor  = AppTheme.onSurfaceVariant;
    }

    return Row(
      children: [
        // ── Bar ──
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 6,
                      color: barColor.withValues(alpha: 0.15),
                    ),
                  ),
                  // Fill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width: barWidth * fraction,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [barColor, barColorEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Threshold tick
                  if (thresholdFraction > 0 && thresholdFraction < 1)
                    Positioned(
                      left: barWidth * thresholdFraction - 1,
                      top: -2,
                      bottom: -2,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        // ── x/x label ──
        Text(
          '$done/$total',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: countColor,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── LAYER 1: STATS ROW
  // ═══════════════════════════════════════════════
  Widget _buildStatsRow() {
    final h = widget.habit;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // My streak
                _statItem('${h.currentStreak}', 'you', icon: '🔥'),
                _dot(),
                // Group streak
                _statItem('${h.groupStreak}', 'squad', icon: '⚡'),
                _dot(),
                // My rank
                if (h.myRank > 0) ...[
                  _statItem('${_ordinal(h.myRank)}', 'rank', icon: '🏆'),
                  _dot(),
                ],
                // Best streak
                _statItem('${h.bestStreak}d', 'best'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── SHARED STAT WIDGETS
  // ═══════════════════════════════════════════════
  Widget _statItem(String value, String label, {String? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (icon != null) ...[
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D3D4E),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  // ── ACTION WIDGETS
  // ═══════════════════════════════════════════════
  Widget _buildGroupStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '${widget.habit.groupStreak}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayTag() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.nightlight_round_outlined,
          size: 12,
          color: AppTheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Rest',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  Widget _buildDonePill() {
    final h = widget.habit;
    final allDone = h.doneTodayCount == h.totalMembers && h.totalMembers > 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allDone ? Icons.groups_rounded : Icons.check_circle_rounded,
            size: 24 * Responsive.scale(context),
            color: allDone ? AppTheme.primaryColor : AppTheme.accentGreen,
          ),
          SizedBox(width: 6 * Responsive.scale(context)),
          Text(
            allDone ? 'All done' : 'Done',
            style: GoogleFonts.inter(
              fontSize: 12 * Responsive.scale(context),
              fontWeight: FontWeight.w700,
              color: allDone ? AppTheme.primaryColor : AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMarkDone() {
    return GestureDetector(
      onTap: () async {
        if (_checkAnimating) return;
        HapticFeedback.lightImpact();
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              "Mark as Done?",
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onBackground),
            ),
            content: Text(
              "Did you complete '${widget.habit.name}' for today?",
              style: GoogleFonts.inter(fontSize: 15, color: AppTheme.onBackground.withValues(alpha: 0.8)),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes, Done!", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          _handleMarkDone();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _checkController,
        builder: (context, _) {
          final isTriggered = _checkController.value > 0.5;

          return Padding(
            padding: EdgeInsets.all(4 * Responsive.scale(context)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isTriggered ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isTriggered),
                size: 28 * Responsive.scale(context),
                color: isTriggered ? AppTheme.accentGreen : const Color(0xFFD5D5DA),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── HELPERS
  // ═══════════════════════════════════════════════

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
