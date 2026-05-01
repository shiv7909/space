import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/home_analytics_model.dart';
import '../cubit/home_analytics_cubit.dart';
import '../cubit/home_analytics_state.dart';

/// Compact analytics card for home screen—glanceable overview without calendar.
class HomeAnalyticsCard extends StatelessWidget {
  final VoidCallback? onRefresh;

  const HomeAnalyticsCard({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeAnalyticsCubit, HomeAnalyticsState>(
      builder: (context, state) {
        if (state is HomeAnalyticsLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.outline),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              height: 200,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (state is HomeAnalyticsError) {
          return const SizedBox.shrink();
        }

        if (state is HomeAnalyticsLoaded) {
          return _buildCard(context, state.analytics);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCard(BuildContext context, HomeAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row with title + streak + counts ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Analytics',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (analytics.bestActiveStreak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD85A30).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${analytics.bestActiveStreak}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD85A30),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${analytics.totalActiveHabits} habits · ${analytics.totalSpaces} spaces',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── 3 stat pills ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatPill(
                    number: analytics.totalCompletions.toString(),
                    label: 'Total',
                    color: const Color(0xFF1D9E75),
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    number: analytics.doneTodayCount.toString(),
                    label: 'Today',
                    color: const Color(0xFF534AB7),
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    number: '${analytics.thisWeekPercentage.round()}%',
                    label: 'This week',
                    color: const Color(0xFFBA7517),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Today dots (habit pills) ──
            if (analytics.habits.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: analytics.habits.map((h) {
                        final done = h.doneTodayRaw;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? const Color(0xFF1D9E75).withValues(alpha: 0.1)
                                : AppTheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: done
                                      ? const Color(0xFF1D9E75)
                                      : AppTheme.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${h.emoji} ${h.name}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: done
                                      ? const Color(0xFF27500A)
                                      : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Habit consistency bars (sorted by consistency) ──
            if (analytics.habits.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habit Consistency',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...(() {
                      final sorted = List<HabitAnalytic>.from(analytics.habits);
                      sorted.sort((a, b) =>
                          (a.consistency ?? 0).compareTo(b.consistency ?? 0));
                      return sorted
                          .map((h) => _HabitBar(habit: h))
                          .toList();
                    })(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Space type cards ──
            if (analytics.spaceTypes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By Space Type',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: analytics.spaceTypes
                          .map((st) => Expanded(
                                child: _SpaceTypeCard(spaceType: st),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── This week bar chart ──
            if (analytics.weeklyData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'This Week',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                            letterSpacing: 0.05,
                          ),
                        ),
                        Text(
                          '${analytics.weeklyData.fold<int>(0, (sum, day) => sum + day.completionCount)} completions',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: analytics.weeklyData
                          .map((day) => _DayBar(day: day))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _StatPill({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitBar extends StatelessWidget {
  final HabitAnalytic habit;

  const _HabitBar({required this.habit});

  Color _getConsistencyColor() {
    final c = habit.consistency ?? 0;
    if (c >= 70) return const Color(0xFF1D9E75);
    if (c >= 40) return const Color(0xFFBA7517);
    return const Color(0xFFD85A30);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConsistencyColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${habit.emoji} ${habit.name}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onBackground,
                ),
              ),
              const Spacer(),
              if (habit.currentStreak > 0)
                Text(
                  '${habit.currentStreak}🔥',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              if (habit.currentStreak == 0)
                Text(
                  '0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (habit.consistency ?? 0) / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${(habit.consistency ?? 0).round()}% consistency',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTypeCard extends StatelessWidget {
  final SpaceTypeAnalytic spaceType;

  const _SpaceTypeCard({required this.spaceType});

  Color _getConsistencyColor() {
    final c = spaceType.avgConsistency;
    if (c >= 70) return const Color(0xFF1D9E75);
    if (c >= 40) return const Color(0xFFBA7517);
    return const Color(0xFFD85A30);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConsistencyColor();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${spaceType.displayEmoji} ${spaceType.displayLabel}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: spaceType.avgConsistency / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${spaceType.avgConsistency.round()}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DayCompletionCount day;

  const _DayBar({required this.day});

  @override
  Widget build(BuildContext context) {
    const maxHeight = 40.0;
    final maxCompletion = 10; // Assume max 10 habits per day for scaling
    final scaledHeight = (day.completionCount / maxCompletion * maxHeight)
        .clamp(0, maxHeight)
        .toDouble();

    return Column(
      children: [
        SizedBox(
          height: maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 16,
                height: scaledHeight > 2 ? scaledHeight : 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day.dayOfWeek.substring(0, 1),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
