import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/error_helpers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../services/space_service.dart';
import 'solo_dashboard_state.dart';
import '../../../models/dashboard_model.dart';

/// 🎯 SOLO DASHBOARD CUBIT
///
/// Manages the state for the solo space dashboard
/// Fetches data from get_dashboard_solo() function
class SoloDashboardCubit extends Cubit<SoloDashboardState> {
  final SpaceService _spaceService;
  final String userId;

  /// The real UUID of the user's solo space — populated after the first load.
  String? activeSpaceId;

  SoloDashboardCubit(this._spaceService, {required this.userId})
    : super(SoloDashboardInitial());

  /// Initial load — shows spinner only on first load.
  Future<void> loadDashboard({String? focusHabitId}) async {
    // Only show full-screen spinner when there's no data yet.
    if (state is! SoloDashboardLoaded) {
      emit(SoloDashboardLoading());
    } else {
      // Already have data — refresh silently so the screen doesn't flash.
      emit(SoloDashboardRefreshing(data: (state as SoloDashboardLoaded).data));
    }

    try {
      // Resolve the real solo space ID once
      if (activeSpaceId == null) {
        final soloSpaces = await Supabase.instance.client
            .from('spaces')
            .select('id')
            .eq('created_by', userId)
            .eq('type', 'solo')
            .limit(1);
        if (soloSpaces.isNotEmpty) {
          activeSpaceId = soloSpaces.first['id'] as String;
        }
      }

      if (activeSpaceId == null) {
        // No solo space yet — return empty state
        if (!isClosed) {
          emit(
            SoloDashboardLoaded(
              data: DashboardData(habits: [], alerts: [], stickyHeader: null),
            ),
          );
        }
        return;
      }

      final response = await _spaceService.getSoloDashboard(
        spaceId: activeSpaceId!,
        userId: userId,
      );

      // ── Full raw response (chunked) ──
      AppLogger.verbose(
        'SoloDashboard',
        'RAW SOLO DASHBOARD RESPONSE',
        response,
      );

      // ── Per-habit breakdown ──
      final habits = response['habits'] as List? ?? [];
      AppLogger.info(
        'SoloDashboard',
        '📋 TOTAL HABITS RETURNED: ${habits.length}',
      );
      for (int i = 0; i < habits.length; i++) {
        AppLogger.verbose(
          'SoloDashboard',
          'HABIT [$i] ${habits[i]['name']}',
          habits[i],
        );
      }

      // ── Alerts ──
      final alerts = response['alerts'] as List? ?? [];
      AppLogger.info('SoloDashboard', '🔔 TOTAL ALERTS: ${alerts.length}');
      for (int i = 0; i < alerts.length; i++) {
        AppLogger.verbose('SoloDashboard', 'ALERT [$i]', alerts[i]);
      }

      // ── Sticky header ──
      AppLogger.verbose(
        'SoloDashboard',
        'STICKY HEADER',
        response['sticky_header'] ?? 'null',
      );

      // Parse the response into DashboardData
      final data = DashboardData.fromJson(response);

      // ── Progress debug ──
      AppLogger.info('SoloDashboard', '📊 PROGRESS DEBUG:');
      for (final h in data.habits) {
        AppLogger.info(
          'SoloDashboard',
          '  habit="${h.name}" isScheduledToday=${h.isScheduledToday} isDoneToday=${h.isDoneToday}',
        );
      }
      final scheduledCount =
          data.habits.where((h) => h.isScheduledToday).length;
      final completedCount =
          data.habits.where((h) => h.isScheduledToday && h.isDoneToday).length;
      AppLogger.info(
        'SoloDashboard',
        '  → scheduled=$scheduledCount completed=$completedCount pct=${scheduledCount > 0 ? (completedCount / scheduledCount * 100).round() : 0}%',
      );

      if (!isClosed) {
        emit(SoloDashboardLoaded(data: data, focusHabitId: focusHabitId));
      }
    } catch (e, stack) {
      AppLogger.error(
        'SoloDashboard',
        'loadDashboard ERROR',
        error: e,
        stack: stack,
      );
      if (!isClosed) {
        emit(SoloDashboardError(message: userMessage(e)));
      }
    }
  }

  /// Pull-to-refresh — never shows the full-screen spinner.
  Future<void> refreshDashboard() async {
    if (state is SoloDashboardLoaded) {
      emit(SoloDashboardRefreshing(data: (state as SoloDashboardLoaded).data));
    }
    try {
      if (activeSpaceId == null) return;
      final response = await _spaceService.getSoloDashboard(
        spaceId: activeSpaceId!,
        userId: userId,
      );
      final data = DashboardData.fromJson(response);
      if (!isClosed) emit(SoloDashboardLoaded(data: data));
    } catch (e) {
      if (!isClosed && state is! SoloDashboardLoaded) {
        emit(SoloDashboardError(message: userMessage(e)));
      }
    }
  }

  /// Dismiss an alert (local only).
  void dismissAlert(String alertId) {
    if (state is SoloDashboardLoaded) {
      final current = state as SoloDashboardLoaded;
      final updatedAlerts =
          current.data.alerts.where((a) => a.id != alertId).toList();

      // ✅ Only emit if alerts actually changed
      if (updatedAlerts.length != current.data.alerts.length) {
        emit(
          SoloDashboardLoaded(
            data: current.data.copyWith(
              alerts: updatedAlerts,
            ), // ✅ Use copyWith
          ),
        );
      }
    }
  }

  /// Dismiss a finished challenge result — calls RPC then removes it locally.
  Future<void> dismissChallengeResult(String habitId) async {
    // Optimistic: remove from local list immediately
    if (state is SoloDashboardLoaded) {
      final current = state as SoloDashboardLoaded;
      final updatedEndedHabits =
          current.data.endedHabits.where((h) => h.id != habitId).toList();

      // ✅ Only emit if endedHabits actually changed
      if (updatedEndedHabits.length != current.data.endedHabits.length) {
        emit(
          SoloDashboardLoaded(
            data: current.data.copyWith(
              endedHabits: updatedEndedHabits,
            ), // ✅ Use copyWith
          ),
        );
      }
    }
    try {
      await _spaceService.dismissChallengeResult(habitId: habitId);
    } catch (e) {
      AppLogger.error(
        'SoloDashboard',
        'dismissChallengeResult error',
        error: e,
      );
      // Non-fatal — the server will still dismiss on next load
    }
  }

  /// Mark a solo habit as complete.
  /// Returns true on success, false if already completed or error.
  Future<bool> completeHabit(String habitId) async {
    if (state is! SoloDashboardLoaded) return false;
    final current = state as SoloDashboardLoaded;

    // ── 1. Optimistic update ──────────────────────────────────────────────
    final updatedHabits =
        current.data.habits.map((h) {
          if (h.id != habitId) return h;
          return h.copyWith(
            currentStreak: h.currentStreak + 1,
            bestStreak:
                h.currentStreak + 1 > h.bestStreak
                    ? h.currentStreak + 1
                    : h.bestStreak,
            isDoneToday: true,
            doneCount: h.doneCount + 1,
            myCalendar: [...h.myCalendar, DateTime.now()],
            lastCompletedAt: DateTime.now(),
          );
        }).toList();

    emit(
      SoloDashboardLoaded(
        data: DashboardData(
          habits: updatedHabits,
          alerts: current.data.alerts,
          stickyHeader: current.data.stickyHeader,
        ),
      ),
    );

    // ── 2. Call RPC ───────────────────────────────────────────────────────
    try {
      if (activeSpaceId == null) return false;
      final result = await _spaceService.completeSoloHabit(habitId: habitId);

      AppLogger.info('SoloDashboard', '✅ completeHabit RPC result: $result');

      final success = result['success'] == true;

      if (!success) {
        AppLogger.warning(
          'SoloDashboard',
          '⚠️ ${result['code']}: ${result['message']} — reverting',
        );
        if (!isClosed) emit(current);
        return false;
      }

      // ── 3. Parse new nested response structure ────────────────────────
      final streakMap = result['streak'] as Map<String, dynamic>? ?? {};
      final celebration = result['celebration'] as Map<String, dynamic>? ?? {};

      final serverStreak =
          streakMap['current'] as int? ??
          updatedHabits.firstWhere((h) => h.id == habitId).currentStreak;
      final serverBest =
          streakMap['best'] as int? ??
          updatedHabits.firstWhere((h) => h.id == habitId).bestStreak;
      final message =
          celebration['message'] as String? ?? '🎉 Habit completed!';
      final category = celebration['category'] as String? ?? 'streak_progress';

      // Apply server-accurate streaks to the optimistic data.
      final serverHabits =
          updatedHabits.map((h) {
            if (h.id != habitId) return h;
            return h.copyWith(
              currentStreak: serverStreak,
              bestStreak: serverBest,
              isDoneToday: true,
            );
          }).toList();

      if (!isClosed) {
        emit(
          SoloDashboardHabitCompleted(
            data: DashboardData(
              habits: serverHabits,
              alerts: current.data.alerts,
              stickyHeader: current.data.stickyHeader,
            ),
            habitId: habitId,
            completionMessage: message,
            category: category,
            currentStreak: serverStreak,
            bestStreak: serverBest,
          ),
        );
      }

      // ── 4. Silent background refresh to sync full server state ────────
      _silentRefresh();
      return true;
    } catch (e) {
      AppLogger.error('SoloDashboard', 'completeHabit error', error: e);
      // Revert the optimistic update on error.
      if (!isClosed) emit(current);
    }
    return false;
  }

  /// Refresh in the background without emitting a loading/refreshing state,
  /// so it doesn't disturb an ongoing completion animation / snackbar.
  Future<void> _silentRefresh() async {
    try {
      if (activeSpaceId == null) return;
      final response = await _spaceService.getSoloDashboard(
        spaceId: activeSpaceId!,
        userId: userId,
      );
      final data = DashboardData.fromJson(response);
      if (!isClosed && state is! SoloDashboardHabitCompleted) {
        emit(SoloDashboardLoaded(data: data));
      }
    } catch (_) {}
  }
}
