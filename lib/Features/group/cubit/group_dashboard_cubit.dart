import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/space_service.dart';
import '../../../models/dashboard_model.dart';
import 'group_dashboard_state.dart';

class GroupDashboardCubit extends Cubit<GroupDashboardState> {
  final SpaceService _spaceService;
  final String userId;
  String? _activeSpaceId;

  GroupDashboardCubit(this._spaceService, {required this.userId})
    : super(GroupDashboardInitial());

  String? get activeSpaceId => _activeSpaceId;

  Future<void> loadDashboard({
    required String spaceId,
    String? focusHabitId,
  }) async {
    _activeSpaceId = spaceId;
    emit(GroupDashboardLoading());
    try {
      final response = await _spaceService.getGroupDashboard(
        spaceId: spaceId,
        userId: userId,
      );
      final data = DashboardData.fromJson(_injectUserId(response));
      if (!isClosed)
        emit(GroupDashboardLoaded(data: data, focusHabitId: focusHabitId));
    } catch (e) {
      if (!isClosed) emit(GroupDashboardError(message: e.toString()));
    }
  }

  Future<void> refreshDashboard({required String spaceId}) async {
    _activeSpaceId = spaceId;
    try {
      final response = await _spaceService.getGroupDashboard(
        spaceId: spaceId,
        userId: userId,
      );
      final data = DashboardData.fromJson(_injectUserId(response));
      if (!isClosed) emit(GroupDashboardLoaded(data: data));
    } catch (e) {
      if (!isClosed && state is! GroupDashboardLoaded) {
        emit(GroupDashboardError(message: e.toString()));
      }
    }
  }

  void dismissAlert(String alertId) {
    if (state is GroupDashboardLoaded) {
      final currentState = state as GroupDashboardLoaded;
      final updatedAlerts =
          currentState.data.alerts
              .where((alert) => alert.id != alertId)
              .toList();

      // ✅ Only emit if alerts actually changed
      if (updatedAlerts.length != currentState.data.alerts.length) {
        emit(
          GroupDashboardLoaded(
            data: currentState.data.copyWith(
              alerts: updatedAlerts,
            ), // ✅ Use copyWith
          ),
        );
      }
    }
  }

  /// Dismiss a finished challenge result — optimistic removal + RPC call.
  Future<void> dismissChallengeResult(String habitId) async {
    if (state is GroupDashboardLoaded) {
      final current = state as GroupDashboardLoaded;
      final updatedEndedHabits =
          current.data.endedHabits.where((h) => h.id != habitId).toList();

      // ✅ Only emit if endedHabits actually changed
      if (updatedEndedHabits.length != current.data.endedHabits.length) {
        emit(
          GroupDashboardLoaded(
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
      print('🔴 GroupDashboardCubit: dismissChallengeResult error: $e');
    }
  }

  /// Mark a group habit as complete for the current user.
  ///
  /// Pattern:
  ///   1. Guard — bail out if already done today or cubit is not in Loaded state.
  ///   2. Optimistic update — instant UI feedback (streak +1, isDoneToday, doneTodayCount +1).
  ///   3. Call complete_group_habit() RPC.
  ///   4. On failure — revert to the pre-call state and return false.
  ///   5. On success — reconcile server-authoritative streak values.
  ///   6. Silent background refresh to sync full group state (members, leaderboard, etc.).
  ///
  /// Returns true on success, false if already completed, guard failed, or RPC error.
  Future<bool> completeHabit(String habitId, String spaceId) async {
    if (state is! GroupDashboardLoaded) return false;

    final pre = state as GroupDashboardLoaded; // snapshot for revert
    final habit = pre.data.habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw StateError('Habit $habitId not found'),
    );

    // ── 1. Guard: already completed today ────────────────────────────────
    if (habit.isDoneToday) return false;

    _activeSpaceId = spaceId;

    // ── 2. Optimistic update ─────────────────────────────────────────────
    final optimisticStreak = habit.currentStreak + 1;
    final optimisticBest =
        optimisticStreak > habit.bestStreak
            ? optimisticStreak
            : habit.bestStreak;

    emit(
      GroupDashboardLoaded(
        data: DashboardData(
          habits: _patchHabit(
            pre.data.habits,
            habitId,
            (h) => DashboardHabit(
              id: h.id,
              name: h.name,
              emoji: h.emoji,
              spaceType: h.spaceType,
              currentStreak: optimisticStreak,
              bestStreak: optimisticBest,
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
              members: h.members,
              leaderboard: h.leaderboard,
              doneTodayCount: h.doneTodayCount + 1,
              streakThreshold: h.streakThreshold,
              myRank: h.myRank,
              myDisplayName: h.myDisplayName,
              myAvatarId: h.myAvatarId,
              myAvatarKey: h.myAvatarKey,
              myPhotoKey: h.myPhotoKey,
              groupStreak: h.groupStreak,
            ),
          ),
          alerts: pre.data.alerts,
          endedHabits: pre.data.endedHabits,
          stickyHeader: pre.data.stickyHeader,
        ),
      ),
    );

    // ── 3. RPC call ──────��────────────────────────────────────────────────
    try {
      final result = await _spaceService.completeGroupHabit(habitId: habitId);
      final success = result['success'] == true;

      // ── 4. Revert on failure ──────────────────────────────────────────
      if (!success) {
        print(
          '⚠️ GroupDashboardCubit: ${result['code']}: ${result['message']} — reverting',
        );
        if (!isClosed) emit(pre);
        return false;
      }

      // ── 5. Reconcile server-authoritative values ──────────────────────
      // complete_group_habit returns:
      //   my_streak  → { current, best }
      //   sync       → { done_today_count, group_streak }
      //   celebration (optional)
      final myStreak = (result['my_streak'] as Map<String, dynamic>?) ?? {};
      final sync = (result['sync'] as Map<String, dynamic>?) ?? {};

      final currentState = state as GroupDashboardLoaded? ?? pre;
      final optimisticHabit = currentState.data.habits.firstWhere(
        (h) => h.id == habitId,
        orElse: () => habit,
      );

      final serverStreak =
          (myStreak['current'] as int?) ?? optimisticHabit.currentStreak;
      final serverBest =
          (myStreak['best'] as int?) ?? optimisticHabit.bestStreak;
      final serverDoneToday =
          (sync['done_today_count'] as int?) ?? optimisticHabit.doneTodayCount;
      final serverGroupStreak =
          (sync['group_streak'] as int?) ?? optimisticHabit.groupStreak;

      if (!isClosed) {
        emit(
          GroupDashboardLoaded(
            data: DashboardData(
              habits: _patchHabit(
                currentState.data.habits,
                habitId,
                (h) => DashboardHabit(
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
                  members: h.members,
                  leaderboard: h.leaderboard,
                  doneTodayCount: serverDoneToday,
                  streakThreshold: h.streakThreshold,
                  myRank: h.myRank,
                  myDisplayName: h.myDisplayName,
                  myAvatarId: h.myAvatarId,
                  myAvatarKey: h.myAvatarKey,
                  myPhotoKey: h.myPhotoKey,
                  groupStreak: serverGroupStreak,
                ),
              ),
              alerts: pre.data.alerts,
              endedHabits: pre.data.endedHabits,
              stickyHeader: pre.data.stickyHeader,
            ),
          ),
        );
      }

      // ── 6. Silent background refresh (syncs members, leaderboard, etc.) ─
      _silentRefresh(spaceId);
      return true;
    } catch (e) {
      print('🔴 GroupDashboardCubit: completeHabit error: $e');
      if (!isClosed) emit(pre);
      return false;
    }
  }

  /// Replace the single habit matching [habitId] using [updater]; leave others unchanged.
  List<DashboardHabit> _patchHabit(
    List<DashboardHabit> habits,
    String habitId,
    DashboardHabit Function(DashboardHabit) updater,
  ) => habits.map((h) => h.id == habitId ? updater(h) : h).toList();

  /// Refresh in the background without showing loading state.
  Future<void> _silentRefresh(String spaceId) async {
    try {
      final response = await _spaceService.getGroupDashboard(
        spaceId: spaceId,
        userId: userId,
      );
      final data = DashboardData.fromJson(_injectUserId(response));
      if (!isClosed) emit(GroupDashboardLoaded(data: data));
    } catch (e) {
      print('🟡 GroupDashboardCubit: silentRefresh error: $e');
    }
  }

  /// Stamps `my_user_id` into every habit map in the response so the model
  /// can identify the current user's GroupMember entry even when the backend
  /// doesn't include `is_me` in the members array.
  Map<String, dynamic> _injectUserId(Map<String, dynamic> response) {
    final habits = response['habits'] as List?;
    if (habits == null || habits.isEmpty) return response;
    final injected = List<dynamic>.from(
      habits.map((h) {
        final habit = Map<String, dynamic>.from(h as Map);
        habit['my_user_id'] = userId;
        return habit;
      }),
    );
    return {...response, 'habits': injected};
  }
}
