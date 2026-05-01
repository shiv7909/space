import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_helpers.dart';
import '../../../models/dashboard_model.dart';

/// 🚀 ADVANCED SPACE HABIT CARD
///
/// Features:
/// - Mini calendar heatmap (last 7 days)
/// - Weekly contribution arc
/// - Streak visualization with flame
/// - Member progress indicators
/// - Real-time completion status
/// - Smart color coding
/// - Micro-interactions
/// - Challenge mode countdown
class AdvancedSpaceHabitCard extends StatefulWidget {
  final DashboardHabit habit;
  final VoidCallback onTap;
  final VoidCallback onActionTap;
  final bool isInSpace; // true for couple/group spaces
  final int? targetDays; // For challenge mode
  final String? mode; // 'infinite' or 'challenge'

  const AdvancedSpaceHabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onActionTap,
    this.isInSpace = true,
    this.targetDays,
    this.mode = 'infinite',
  });

  @override
  State<AdvancedSpaceHabitCard> createState() => _AdvancedSpaceHabitCardState();
}

class _AdvancedSpaceHabitCardState extends State<AdvancedSpaceHabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getSpaceColor() {
    switch (widget.habit.spaceType) {
      case DashboardSpaceType.couple:
        return const Color(0xFFFF6B6B);
      case DashboardSpaceType.group:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B6BE0);
    }
  }

  Color _getStatusColor() {
    if (widget.habit.isDoneToday) return const Color(0xFF10B981);
    if (widget.habit.streakStatus == DashboardStreakStatus.broken) {
      return const Color(0xFFEF4444);
    }
    if (widget.habit.streakStatus == DashboardStreakStatus.inactive) {
      return const Color(0xFF9CA3AF); // Gray for inactive
    }
    if (widget.habit.currentStreak == 0) return const Color(0xFF71717A);
    return const Color(0xFFF59E0B);
  }

  String _getSpaceIcon() {
    switch (widget.habit.spaceType) {
      case DashboardSpaceType.couple:
        return '🤝';
      case DashboardSpaceType.group:
        return '👥';
      default:
        return '⭐';
    }
  }

  List<DateTime> _getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
  }

  bool _isCompletedOnDay(DateTime day) {
    return widget.habit.myCalendar.any(
      (completedDate) =>
          completedDate.year == day.year &&
          completedDate.month == day.month &&
          completedDate.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spaceColor = _getSpaceColor();
    final statusColor = _getStatusColor();
    final last7Days = _getLast7Days();
    final completionPercentage =
        widget.habit.totalMembers > 0
            ? (widget.habit.doneCount / widget.habit.totalMembers)
            : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isHovered ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  widget.habit.isDoneToday
                      ? const Color.fromRGBO(16, 185, 129, 0.3)
                      : const Color.fromRGBO(156, 163, 175, 0.1),
              width: widget.habit.isDoneToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  spaceColor.red,
                  spaceColor.green,
                  spaceColor.blue,
                  0.08,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                if (widget.habit.isDoneToday)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(
                              statusColor.red,
                              statusColor.green,
                              statusColor.blue,
                              0.05,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(16 * Responsive.scale(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    !widget.habit.isDoneToday
                                        ? _pulseAnimation.value
                                        : 1.0,
                                child: Container(
                                  width: 48 * Responsive.scale(context),
                                  height: 48 * Responsive.scale(context),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                      statusColor.red,
                                      statusColor.green,
                                      statusColor.blue,
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color.fromRGBO(
                                        statusColor.red,
                                        statusColor.green,
                                        statusColor.blue,
                                        0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.habit.emoji,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize:
                                            22 * Responsive.scale(context),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.habit.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize:
                                              15 * Responsive.scale(context),
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF18181B),
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (widget.isInSpace)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(
                                            spaceColor.red,
                                            spaceColor.green,
                                            spaceColor.blue,
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _getSpaceIcon(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildStreakIndicator(statusColor),
                              ],
                            ),
                          ),
                          _buildActionButton(statusColor, spaceColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatsRow(spaceColor)),
                          const SizedBox(width: 16),
                          _buildMiniCalendar(last7Days, statusColor),
                        ],
                      ),
                      if (widget.isInSpace &&
                          widget.habit.spaceType !=
                              DashboardSpaceType.solo) ...[
                        const SizedBox(height: 16),
                        _buildMemberProgress(
                          completionPercentage,
                          spaceColor,
                          statusColor,
                        ),
                      ],
                      if (widget.mode == 'challenge' &&
                          widget.targetDays != null) ...[
                        const SizedBox(height: 16),
                        _buildChallengeProgress(spaceColor),
                      ],
                      if (widget.habit.whyReason != null &&
                          widget.habit.whyReason!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildWhyReason(),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailsHint(spaceColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(Color statusColor) {
    return Row(
      children: [
        Icon(Icons.local_fire_department_rounded, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          '${widget.habit.currentStreak} day streak',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: statusColor,
            letterSpacing: -0.3,
          ),
        ),
        if (widget.habit.bestStreak > widget.habit.currentStreak) ...[
          const SizedBox(width: 8),
          Text(
            '🏆 ${widget.habit.bestStreak}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(Color statusColor, Color spaceColor) {
    final bool isSoloHabit = widget.habit.spaceType == DashboardSpaceType.solo;
    return GestureDetector(
      onTap: widget.habit.isDoneToday ? null : widget.onActionTap,
      child: Container(
        width: 48 * Responsive.scale(context),
        height: 48 * Responsive.scale(context),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              widget.habit.isDoneToday
                  ? statusColor
                  : (isSoloHabit
                      ? spaceColor
                      : Color.fromRGBO(
                        spaceColor.red,
                        spaceColor.green,
                        spaceColor.blue,
                        0.1,
                      )),
          border: Border.all(
            color:
                widget.habit.isDoneToday
                    ? Colors.transparent
                    : Color.fromRGBO(
                      spaceColor.red,
                      spaceColor.green,
                      spaceColor.blue,
                      0.3,
                    ),
            width: 2,
          ),
          boxShadow:
              widget.habit.isDoneToday
                  ? [
                    BoxShadow(
                      color: Color.fromRGBO(
                        statusColor.red,
                        statusColor.green,
                        statusColor.blue,
                        0.3,
                      ),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Icon(
          widget.habit.isDoneToday
              ? Icons.check_rounded
              : (isSoloHabit
                  ? Icons.check_circle_outline_rounded
                  : Icons.camera_alt_rounded),
          color:
              widget.habit.isDoneToday
                  ? Colors.white
                  : (isSoloHabit ? Colors.white : spaceColor),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStatsRow(Color spaceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildStatItem(
          icon: Icons.calendar_today_rounded,
          value: '${widget.habit.myCalendar.length}',
          label: 'Total',
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.trending_up_rounded,
          value: '${widget.habit.bestStreak}',
          label: 'Best',
          color: const Color(0xFFF59E0B),
        ),
        if (widget.habit.spaceType != DashboardSpaceType.solo) ...[
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.people_rounded,
            value: '${widget.habit.doneCount}/${widget.habit.totalMembers}',
            label: 'Done',
            color: spaceColor,
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCalendar(List<DateTime> days, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Last 7 Days',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children:
              days.map((day) {
                final isCompleted = _isCompletedOnDay(day);
                final isToday =
                    DateTime.now().day == day.day &&
                    DateTime.now().month == day.month &&
                    DateTime.now().year == day.year;
                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 24 * Responsive.scale(context),
                    height: 32 * Responsive.scale(context),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? Color.fromRGBO(
                                statusColor.red,
                                statusColor.green,
                                statusColor.blue,
                                0.9,
                              )
                              : const Color.fromRGBO(156, 163, 175, 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          isToday
                              ? Border.all(color: statusColor, width: 2)
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day)[0],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color:
                                isCompleted ? Colors.white : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color:
                                isCompleted ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMemberProgress(
    double percentage,
    Color spaceColor,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  widget.habit.spaceType == DashboardSpaceType.couple
                      ? Icons.favorite_rounded
                      : Icons.groups_rounded,
                  size: 16,
                  color: spaceColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Team Progress',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: percentage == 1.0 ? statusColor : spaceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        percentage == 1.0
                            ? [statusColor, statusColor]
                            : [
                              spaceColor,
                              Color.fromRGBO(
                                spaceColor.red,
                                spaceColor.green,
                                spaceColor.blue,
                                0.6,
                              ),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(
                        (percentage == 1.0 ? statusColor : spaceColor).red,
                        (percentage == 1.0 ? statusColor : spaceColor).green,
                        (percentage == 1.0 ? statusColor : spaceColor).blue,
                        0.3,
                      ),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (percentage == 1.0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                statusColor.red,
                statusColor.green,
                statusColor.blue,
                0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  'Everyone completed!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChallengeProgress(Color spaceColor) {
    final daysCompleted = widget.habit.currentStreak;
    final targetDays = widget.targetDays ?? 30;
    final progress = (daysCompleted / targetDays).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 16, color: spaceColor),
                const SizedBox(width: 6),
                Text(
                  'Challenge Mode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
            Text(
              '$daysCompleted / $targetDays days',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: spaceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      spaceColor,
                      Color.fromRGBO(
                        spaceColor.red,
                        spaceColor.green,
                        spaceColor.blue,
                        0.7,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhyReason() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.habit.whyReason!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF52525B),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsHint(Color spaceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 16, color: spaceColor),
        const SizedBox(width: 4),
        Text(
          'Tap to view details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: spaceColor,
          ),
        ),
      ],
    );
  }
}
