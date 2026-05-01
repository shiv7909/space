import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../../shared/habit_shape_widget.dart';
import '../constants/solo_constants.dart';

/// 🎨 SOLO HABIT CARD — Flat, borderless layout. No card wrapper.
class SoloHabitCard extends StatefulWidget {
  final DashboardHabit habit;
  final VoidCallback onTap;
  final Future<bool> Function() onMarkDone; // returns true on success
  final int index;
  final bool isLast;
  final bool initiallyExpanded;

  const SoloHabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onMarkDone,
    this.index = 0,
    this.isLast = false,
    this.initiallyExpanded = false,
  });

  @override
  State<SoloHabitCard> createState() => _SoloHabitCardState();
}

class _SoloHabitCardState extends State<SoloHabitCard>
    with SingleTickerProviderStateMixin {
  bool _checkAnimating = false;
  bool _pressing = false;
  late final AnimationController _checkController;
  late bool _calendarExpanded;

  // ✅ Cache month days — computed once, never on every build frame
  late final List<DateTime?> _monthDays;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // ✅ Initially expanded based on parameter
    _calendarExpanded = widget.initiallyExpanded;
    // ✅ Pre-compute month grid once
    _monthDays = _computeMonthDays();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  // ✅ NEW: Reset animation when habit changes to prevent controller leaks
  @override
  void didUpdateWidget(SoloHabitCard oldWidget) {
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
    // Play forward animation immediately for responsive feel
    await _checkController.forward();
    // Call the cubit — if it fails, reverse animation
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
            // ── Main content ──
            Container(
              margin: EdgeInsets.only(
                bottom: widget.isLast ? 0 : 14.rs(context),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 10.rs(context),
                horizontal: 10.rs(context),
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(15.rs(context)),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Emoji + Name + Mark done (right) ──
                  _buildHeader(isDone, isScheduled),
                  SizedBox(height: 12.rs(context)),
                  // ── Row 2: Stats + calendar toggle ──
                  _buildStatsRow(),
                  // ── Collapsible Calendar ──
                  _buildCalendarSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDone, bool isScheduled) {
    final h = widget.habit;
    final showCheck = isScheduled && !isDone;
    return Row(
      children: [
        // Emoji — visual anchor, sized up for identity
        HabitShapeWidget(emoji: h.emoji, size: 28.rs(context)),
        SizedBox(width: 12.rs(context)),
        // Name + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.rs(context),
                  fontWeight: FontWeight.w600,
                  color:
                      isDone
                          ? AppTheme.onBackground.withValues(alpha: 0.55)
                          : AppTheme.onBackground,
                  decoration: TextDecoration.none,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2.rs(context)),
              Text(
                _subtitle(),
                style: GoogleFonts.inter(
                  fontSize: 11.5.rs(context),
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.rs(context)),
        // ── Right side: streak badge → then action ──
        if (!isScheduled) _buildRestDayTag(),
        if (isScheduled && h.currentStreak > 0 && !isDone) ...[
          _buildStreakBadge(),
          SizedBox(width: 8.rs(context)),
        ],
        if (isDone) _buildDoneCheck(),
        if (showCheck) _buildInlineMarkDone(),
      ],
    );
  }

  String _subtitle() {
    final h = widget.habit;
    if (h.mode == 'challenge' && h.targetDays != null) {
      return 'Challenge · ${((h.currentStreak / h.targetDays!) * 100).clamp(0, 100).round()}%';
    }
    if (h.isDoneToday) return 'Done for today';
    if (!h.isScheduledToday) return 'Rest day';
    if (h.currentStreak > 0) return 'Ongoing · ${h.currentStreak}d streak';
    return h.mode == 'infinite' ? 'Ongoing' : '';
  }

  Widget _buildRestDayTag() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.nightlight_round_outlined,
          size: 12.rs(context),
          color: AppTheme.onSurfaceVariant,
        ),
        SizedBox(width: 4.rs(context)),
        Text(
          'Rest',
          style: GoogleFonts.inter(
            fontSize: 11.rs(context),
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🔥', style: TextStyle(fontSize: 13.rs(context))),
        SizedBox(width: 3.rs(context)),
        Text(
          '${widget.habit.currentStreak}',
          style: GoogleFonts.inter(
            fontSize: 13.rs(context),
            fontWeight: FontWeight.w600,
            color: AppTheme.onBackground,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ── DONE CHECK (minimal completed indicator)
  // ═══════════════════════════════════════════════
  Widget _buildDoneCheck() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.rs(context)),
      child: Icon(
        Icons.check_circle_rounded,
        size: 28.rs(context),
        color: const Color(0xFF2DA44E),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── INLINE MARK DONE (right side of header)
  // ═══════════════════════════════════════════════
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
                  backgroundColor: const Color(0xFF2DA44E),
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
            padding: EdgeInsets.all(4.rs(context)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isTriggered ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isTriggered),
                size: 28.rs(context),
                color: isTriggered ? const Color(0xFF2DA44E) : const Color(0xFFD5D5DA),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ── STATS ROW
  // ═══════════════════════════════════════════════
  Widget _buildStatsRow() {
    final h = widget.habit;

    // All actual calendar days this month (no null padding)
    final monthDays = _monthDays.whereType<DateTime>().toList();

    // Effective start: date-only, defaults to month start if not set
    final now = DateTime.now();
    final effectiveStart =
        h.startDate != null
            ? DateTime(h.startDate!.year, h.startDate!.month, h.startDate!.day)
            : DateTime(now.year, now.month, 1);

    // Denominator: ALL scheduled days in this month on/after startDate
    // (includes future days — this is the full month target)
    final totalScheduledThisMonth =
        monthDays.where((d) {
          final day = DateTime(d.year, d.month, d.day);
          if (day.isBefore(effectiveStart))
            return false; // before habit started
          if (!_isScheduled(d)) return false; // not a scheduled weekday
          return true;
        }).length;

    // Numerator: completed days that were scheduled (on/after effectiveStart)
    // No need to guard against future — myCalendar only contains real past completions
    final completedScheduledDays =
        monthDays.where((d) {
          final day = DateTime(d.year, d.month, d.day);
          if (day.isBefore(effectiveStart)) return false;
          if (!_isScheduled(d)) return false;
          return _isCompleted(d);
        }).length;

    final rate =
        totalScheduledThisMonth > 0
            ? ((completedScheduledDays / totalScheduledThisMonth) * 100).round()
            : 0;

    // Entire stats row is tappable to toggle calendar — larger hit area
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _calendarExpanded = !_calendarExpanded);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _statItem('${h.currentStreak}d', 'streak'),
          _dot(),
          _statItem('${h.bestStreak}d', 'best'),
          _dot(),
          _statItem('$rate%', 'month'),
          const Spacer(),
          AnimatedRotation(
            turns: _calendarExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.rs(context),
              color:
                  _calendarExpanded
                      ? AppTheme.onBackground
                      : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.rs(context),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D3D4E),
          ),
        ),
        SizedBox(width: 3.rs(context)),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.rs(context),
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _dot() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 6.rs(context)),
    child: Text(
      '·',
      style: TextStyle(
        fontSize: 14.rs(context),
        color: AppTheme.onSurfaceVariant,
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  // ── CALENDAR SECTION
  // ═══════════════════════════════════════════════
  Widget _buildCalendarSection() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _buildMonthCalendar(),
      ),
      crossFadeState:
          _calendarExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      sizeCurve: Curves.easeOutQuint,
    );
  }

  Widget _buildMonthCalendar() {
    final monthDays = _monthDays;
    return Column(
      children: [
        // Day-of-week labels — no legend needed, colors are self-evident
        Row(
          children:
              ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 10.rs(context),
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4),
        // Grid
        ...List.generate((monthDays.length / 7).ceil(), (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: List.generate(7, (dayIdx) {
                final idx = week * 7 + dayIdx;
                if (idx >= monthDays.length || monthDays[idx] == null) {
                  return const Expanded(child: SizedBox(height: 20));
                }
                return Expanded(
                  child: Center(child: _buildDayCell(monthDays[idx]!)),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  // Legend removed — colors are self-evident (green=done, red=missed, grey=rest)

  Widget _buildDayCell(DateTime day) {
    final state = _dayState(day);
    final isToday = _isToday(day);
    Color bgColor;
    Border? cellBorder;

    switch (state) {
      case _DotState.done:
        bgColor = AppTheme.accentGreen;
        break;
      case _DotState.missed:
        bgColor = AppTheme.accentRed.withValues(alpha: 0.2);
        break;
      case _DotState.rest:
        bgColor = const Color(0xFFE4E4EA);
        cellBorder = Border.all(color: const Color(0xFFD5D5DA), width: 0.5);
        break;
      case _DotState.future:
        bgColor = const Color(0xFFEAEAEF);
        cellBorder = Border.all(color: const Color(0xFFDDDDE3), width: 0.5);
        break;
    }

    if (isToday)
      cellBorder = Border.all(color: AppTheme.onBackground, width: 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = (constraints.maxWidth * 0.45).clamp(12.0, 15.0);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: cellBorder,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // ── HELPERS
  // ═══════════════════════════════════════════════
  List<DateTime?> _computeMonthDays() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final List<DateTime?> days = [];
    for (int i = 0; i < first.weekday % 7; i++) {
      days.add(null);
    }
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(now.year, now.month, d));
    }
    return days;
  }

  bool _isCompleted(DateTime day) => widget.habit.myCalendar.any(
    (c) => c.year == day.year && c.month == day.month && c.day == day.day,
  );

  bool _isScheduled(DateTime day) =>
      widget.habit.scheduledDays.contains(day.weekday);

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  _DotState _dayState(DateTime day) {
    if (widget.habit.startDate != null) {
      final start = DateTime(
        widget.habit.startDate!.year,
        widget.habit.startDate!.month,
        widget.habit.startDate!.day,
      );
      if (DateTime(day.year, day.month, day.day).isBefore(start)) {
        return _DotState.future;
      }
    }
    if (_isFuture(day)) return _DotState.future;
    if (_isCompleted(day)) return _DotState.done;
    if (!_isScheduled(day)) return _DotState.rest;
    return _DotState.missed;
  }
}

enum _DotState { done, missed, rest, future }
