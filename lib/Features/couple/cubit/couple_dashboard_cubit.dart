import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/space_service.dart';
import '../../../models/dashboard_model.dart';
import 'couple_dashboard_state.dart';

/// 💕 COUPLE DASHBOARD CUBIT
///
/// Manages the state for the duo/couple space dashboard.
/// Fetches data from get_dashboard_couple() for the couple space.
class CoupleDashboardCubit extends Cubit<CoupleDashboardState> {
  final SpaceService _spaceService;
  final String userId;
  String? _activeSpaceId;

  CoupleDashboardCubit(this._spaceService, {required this.userId})
    : super(CoupleDashboardInitial());

  String? get activeSpaceId => _activeSpaceId;

  /// Initial load — shows spinner only on first load.
  Future<void> loadDashboard({
    required String spaceId,
    String? focusHabitId,
  }) async {
    _activeSpaceId = spaceId;

    if (state is! CoupleDashboardLoaded) {
      emit(CoupleDashboardLoading());
    } else {
      emit(
        CoupleDashboardRefreshing(data: (state as CoupleDashboardLoaded).data),
      );
    }

    try {
      final response = await _spaceService.getCoupleDashboard(
        spaceId: spaceId,
        userId: userId,
      );

      print('🟣 CoupleDashboard RAW response keys: ${response.keys.toList()}');
      print('🟣 CoupleDashboard status: ${response['status']}');
      print('🟣 CoupleDashboard message: ${response['message']}');
      print(
        '🟣 CoupleDashboard habits count: ${(response['habits'] as List?)?.length ?? 'null'}',
      );
      print('🟣 CoupleDashboard partner_id: ${response['partner_id']}');

      final data = DashboardData.fromJson(response);

      print(
        '🟣 CoupleDashboard PARSED: status=${data.status}, habits=${data.habits.length}, alerts=${data.alerts.length}',
      );

      if (!isClosed) {
        emit(CoupleDashboardLoaded(data: data, focusHabitId: focusHabitId));
      }

      // ── Mark any nudges sent to the current user as seen (bulk, fire-and-forget) ──
      _markAllNudgesSeen(data.habits);
    } catch (e) {
      print('🔴 CoupleDashboardCubit ERROR: $e');
      if (!isClosed) {
        emit(CoupleDashboardError(message: e.toString()));
      }
    }
  }

  /// Bulk mark-as-seen for all couple habits on dashboard load.
  void _markAllNudgesSeen(List<DashboardHabit> habits) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    for (final h in habits) {
      if (h.spaceType == DashboardSpaceType.couple) {
        _spaceService.markNudgesSeen(habitId: h.id, userId: uid);
      }
    }
  }

  /// Pull-to-refresh — never shows the full-screen spinner.
  Future<void> refreshDashboard() async {
    if (_activeSpaceId == null) return;
    if (state is CoupleDashboardLoaded) {
      emit(
        CoupleDashboardRefreshing(data: (state as CoupleDashboardLoaded).data),
      );
    }
    try {
      final response = await _spaceService.getCoupleDashboard(
        spaceId: _activeSpaceId!,
        userId: userId,
      );
      final data = DashboardData.fromJson(response);
      if (!isClosed) emit(CoupleDashboardLoaded(data: data));
    } catch (e) {
      if (!isClosed && state is! CoupleDashboardLoaded) {
        emit(CoupleDashboardError(message: e.toString()));
      }
    }
  }

  /// Dismiss an alert (local only).
  void dismissAlert(String alertId) {
    if (state is CoupleDashboardLoaded) {
      final current = state as CoupleDashboardLoaded;
      final updatedAlerts =
          current.data.alerts.where((a) => a.id != alertId).toList();

      // ✅ Only emit if alerts actually changed
      if (updatedAlerts.length != current.data.alerts.length) {
        emit(
          CoupleDashboardLoaded(
            data: current.data.copyWith(
              alerts: updatedAlerts,
            ), // ✅ Use copyWith
          ),
        );
      }
    }
  }

  /// Dismiss a finished challenge result — optimistic removal + RPC call.
  Future<void> dismissChallengeResult(String habitId) async {
    if (state is CoupleDashboardLoaded) {
      final current = state as CoupleDashboardLoaded;
      final updatedEndedHabits =
          current.data.endedHabits.where((h) => h.id != habitId).toList();

      // ✅ Only emit if endedHabits actually changed
      if (updatedEndedHabits.length != current.data.endedHabits.length) {
        emit(
          CoupleDashboardLoaded(
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
      print('🔴 CoupleDashboardCubit: dismissChallengeResult error: $e');
    }
  }

  /// Mark a couple habit as complete.
  /// Returns true on success, false otherwise.
  Future<bool> completeHabit(String habitId) async {
    if (state is! CoupleDashboardLoaded || _activeSpaceId == null) return false;
    final current = state as CoupleDashboardLoaded;

    // ── 1. Optimistic update ──
    final updatedHabits =
        current.data.habits.map((h) {
          if (h.id != habitId) return h;
          return DashboardHabit(
            id: h.id,
            name: h.name,
            emoji: h.emoji,
            spaceType: h.spaceType,
            currentStreak: h.currentStreak + 1,
            bestStreak:
                h.currentStreak + 1 > h.bestStreak
                    ? h.currentStreak + 1
                    : h.bestStreak,
            streakStatus: DashboardStreakStatus.active,
            isDoneToday: true,
            doneCount: h.doneCount + 1,
            totalMembers: h.totalMembers,
            whyReason: h.whyReason,
            myCalendar: [...h.myCalendar, DateTime.now()],
            habitHeader: h.habitHeader,
            scheduledDays: h.scheduledDays,
            startDate: h.startDate,
            endDate: h.endDate,
            mode: h.mode,
            isScheduledToday: h.isScheduledToday,
            lastCompletedAt: DateTime.now(),
            createdAt: h.createdAt,
            targetDays: h.targetDays,
            // Preserve couple-specific fields
            partnerId: h.partnerId,
            partnerAvatarKey: h.partnerAvatarKey,
            partnerPhotoId: h.partnerPhotoId,
            partnerPhotoKey: h.partnerPhotoKey,
            partnerCurrentStreak: h.partnerCurrentStreak,
            partnerBestStreak: h.partnerBestStreak,
            partnerTotalLogs: h.partnerTotalLogs,
            partnerStreakStatus: h.partnerStreakStatus,
            partnerDoneToday: h.partnerDoneToday,
            partnerLastDone: h.partnerLastDone,
            partnerCalendar: h.partnerCalendar,
            combinedCalendar: h.combinedCalendar,
            groupStreak: h.groupStreak,
            daysRemaining: h.daysRemaining,
            myDaysCompleted:
                h.myDaysCompleted != null ? h.myDaysCompleted! + 1 : null,
            myDaysMissed: h.myDaysMissed,
            myLogsNeeded:
                h.myLogsNeeded != null
                    ? (h.myLogsNeeded! - 1).clamp(0, 999)
                    : null,
            myCompletionPct: h.myCompletionPct,
            partnerDaysCompleted: h.partnerDaysCompleted,
            partnerDaysMissed: h.partnerDaysMissed,
            partnerLogsNeeded: h.partnerLogsNeeded,
            partnerCompletionPct: h.partnerCompletionPct,
            canStillComplete: h.canStillComplete,
          );
        }).toList();

    emit(
      CoupleDashboardLoaded(
        data: DashboardData(
          habits: updatedHabits,
          alerts: current.data.alerts,
          stickyHeader: current.data.stickyHeader,
        ),
      ),
    );

    // ── 2. Call RPC ──
    try {
      final result = await _spaceService.completeDuoHabit(habitId: habitId);
      final success = result['success'] == true;

      if (!success) {
        print('⚠️ ${result['code']}: ${result['message']} — reverting');
        if (!isClosed) emit(current);
        return false;
      }

      // ── 3. Parse server response ──
      // complete_duo_habit returns: my_streak, sync, celebration
      final myStreakMap = result['my_streak'] as Map<String, dynamic>? ?? {};
      final syncMap = result['sync'] as Map<String, dynamic>? ?? {};
      final celebration = result['celebration'] as Map<String, dynamic>? ?? {};

      final serverStreak =
          myStreakMap['current'] as int? ??
          updatedHabits.firstWhere((h) => h.id == habitId).currentStreak;
      final serverBest =
          myStreakMap['best'] as int? ??
          updatedHabits.firstWhere((h) => h.id == habitId).bestStreak;
      final partnerDoneToday = syncMap['partner_done_today'] as bool? ?? false;
      final serverGroupStreak = syncMap['group_streak'] as int? ?? 0;
      final message =
          celebration['message'] as String? ?? '🎉 Habit completed!';
      const category = 'streak_progress';

      final serverHabits =
          updatedHabits.map((h) {
            if (h.id != habitId) return h;
            return DashboardHabit(
              id: h.id,
              name: h.name,
              emoji: h.emoji,
              spaceType: h.spaceType,
              currentStreak: serverStreak,
              bestStreak: serverBest,
              streakStatus: DashboardStreakStatus.active,
              isDoneToday: true,
              doneCount: h.doneCount,
              totalMembers: h.totalMembers,
              whyReason: h.whyReason,
              myCalendar: h.myCalendar,
              habitHeader: h.habitHeader,
              scheduledDays: h.scheduledDays,
              startDate: h.startDate,
              endDate: h.endDate,
              mode: h.mode,
              isScheduledToday: h.isScheduledToday,
              lastCompletedAt: h.lastCompletedAt,
              createdAt: h.createdAt,
              targetDays: h.targetDays,
              // Couple-specific — update partner sync + group streak from server
              partnerId: h.partnerId,
              partnerAvatarKey: h.partnerAvatarKey,
              partnerPhotoId: h.partnerPhotoId,
              partnerPhotoKey: h.partnerPhotoKey,
              partnerCurrentStreak: h.partnerCurrentStreak,
              partnerBestStreak: h.partnerBestStreak,
              partnerTotalLogs: h.partnerTotalLogs,
              partnerStreakStatus: h.partnerStreakStatus,
              partnerDoneToday: partnerDoneToday,
              partnerLastDone: h.partnerLastDone,
              partnerCalendar: h.partnerCalendar,
              combinedCalendar: h.combinedCalendar,
              groupStreak: serverGroupStreak,
              daysRemaining: h.daysRemaining,
              myDaysCompleted: h.myDaysCompleted,
              myDaysMissed: h.myDaysMissed,
              myLogsNeeded: h.myLogsNeeded,
              myCompletionPct: h.myCompletionPct,
              partnerDaysCompleted: h.partnerDaysCompleted,
              partnerDaysMissed: h.partnerDaysMissed,
              partnerLogsNeeded: h.partnerLogsNeeded,
              partnerCompletionPct: h.partnerCompletionPct,
              canStillComplete: h.canStillComplete,
            );
          }).toList();

      if (!isClosed) {
        emit(
          CoupleDashboardHabitCompleted(
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

      // ── 4. Silent background refresh ──
      _silentRefresh();
      return true;
    } catch (e) {
      print('🔴 completeHabit error: $e');
      if (!isClosed) emit(current);
    }
    return false;
  }

  Future<void> _silentRefresh() async {
    if (_activeSpaceId == null) return;
    try {
      final response = await _spaceService.getCoupleDashboard(
        spaceId: _activeSpaceId!,
        userId: userId,
      );
      final data = DashboardData.fromJson(response);
      if (!isClosed && state is! CoupleDashboardHabitCompleted) {
        emit(CoupleDashboardLoaded(data: data));
      }
    } catch (_) {}
  }

  /// Send a nudge for the given habit.
  /// Returns the response [code] string from the RPC so the UI can react.
  /// Does not emit any state change — nudging is a side-effect only.
  Future<String> sendNudge(String habitId) async {
    try {
      final response = await _spaceService.sendNudge(habitId: habitId);
      return response['code'] as String? ?? 'CLIENT_ERROR';
    } catch (e) {
      print('🔴 CoupleDashboardCubit.sendNudge error: $e');
      return 'CLIENT_ERROR';
    }
  }
}
