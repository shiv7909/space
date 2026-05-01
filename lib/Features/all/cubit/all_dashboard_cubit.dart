import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_helpers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../services/space_service.dart';
import '../../../models/dashboard_model.dart';
import 'all_dashboard_state.dart';

class AllDashboardCubit extends Cubit<AllDashboardState> {
  final SpaceService _spaceService;
  final String userId;

  AllDashboardCubit(this._spaceService, {required this.userId})
      : super(AllDashboardInitial());

  Future<void> loadDashboard({String? focusHabitId}) async {
    if (state is! AllDashboardLoaded) {
      emit(AllDashboardLoading());
    } else {
      emit(AllDashboardRefreshing(data: (state as AllDashboardLoaded).data));
    }

    try {
      final spaces = await _spaceService.getUserSpaces(userId);
      
      final List<DashboardAlert> allAlerts = [];
      final List<DashboardHabit> allHabits = [];
      final List<EndedHabit> allEndedHabits = [];
      
      // Fetch all dashboards concurrently
      final futures = spaces.map((space) async {
        try {
          Map<String, dynamic> response;
          if (space.type == 'solo') {
            response = await _spaceService.getSoloDashboard(spaceId: space.id, userId: userId);
          } else if (space.type == 'couple') {
            response = await _spaceService.getCoupleDashboard(spaceId: space.id, userId: userId);
          } else {
            response = await _spaceService.getGroupDashboard(spaceId: space.id, userId: userId);
          }
          return DashboardData.fromJson(response);
        } catch (e) {
          AppLogger.error('AllDashboardCubit', 'Failed to load space ${space.id}', error: e);
          return DashboardData(habits: [], alerts: [], endedHabits: []);
        }
      });

      final results = await Future.wait(futures);

      for (var data in results) {
        allAlerts.addAll(data.alerts);
        allHabits.addAll(data.habits);
        allEndedHabits.addAll(data.endedHabits);
      }
      
      // Sort habits logically
      allHabits.sort((a, b) {
        // Place scheduled but incomplete first
        final aPending = a.isScheduledToday && !a.isDoneToday;
        final bPending = b.isScheduledToday && !b.isDoneToday;
        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
        
        // Then completed today
        final aDone = a.isScheduledToday && a.isDoneToday;
        final bDone = b.isScheduledToday && b.isDoneToday;
        if (aDone && !bDone) return -1;
        if (!aDone && bDone) return 1;
        
        return 0;
      });

      final combinedData = DashboardData(
        alerts: allAlerts,
        habits: allHabits,
        endedHabits: allEndedHabits,
      );

      if (!isClosed) emit(AllDashboardLoaded(data: combinedData, focusHabitId: focusHabitId));
    } catch (e, stack) {
      AppLogger.error('AllDashboardCubit', 'Error loading all dashboards', error: e, stack: stack);
      if (!isClosed) emit(AllDashboardError(message: userMessage(e)));
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }
  
  void dismissAlert(String alertId) {
    if (state is AllDashboardLoaded) {
      final current = state as AllDashboardLoaded;
      final updatedAlerts = current.data.alerts.where((a) => a.id != alertId).toList();
      if (updatedAlerts.length != current.data.alerts.length) {
        emit(AllDashboardLoaded(data: current.data.copyWith(alerts: updatedAlerts)));
      }
    }
  }

  Future<void> dismissChallengeResult(String habitId) async {
    if (state is AllDashboardLoaded) {
      final current = state as AllDashboardLoaded;
      final updatedEndedHabits = current.data.endedHabits.where((h) => h.id != habitId).toList();
      if (updatedEndedHabits.length != current.data.endedHabits.length) {
        emit(AllDashboardLoaded(data: current.data.copyWith(endedHabits: updatedEndedHabits)));
      }
    }
    try {
      await _spaceService.dismissChallengeResult(habitId: habitId);
    } catch (e) {
      AppLogger.error('AllDashboardCubit', 'dismissChallengeResult error', error: e);
    }
  }

  Future<bool> completeHabit(DashboardHabit habit) async {
    if (state is! AllDashboardLoaded) return false;
    final current = state as AllDashboardLoaded;
    
    // 1. Optimistic update
    final updatedHabits = current.data.habits.map((h) {
      if (h.id != habit.id) return h;
      return h.copyWith(
        currentStreak: h.currentStreak + 1,
        bestStreak: h.currentStreak + 1 > h.bestStreak ? h.currentStreak + 1 : h.bestStreak,
        isDoneToday: true,
        doneCount: h.doneCount + 1,
        myCalendar: [...h.myCalendar, DateTime.now()],
        lastCompletedAt: DateTime.now(),
      );
    }).toList();

    emit(AllDashboardLoaded(data: DashboardData(
      habits: updatedHabits,
      alerts: current.data.alerts,
      endedHabits: current.data.endedHabits,
    )));

    // 2. Call correct RPC
    try {
      Map<String, dynamic> result;
      if (habit.spaceType == DashboardSpaceType.solo) {
        result = await _spaceService.completeSoloHabit(habitId: habit.id);
      } else if (habit.spaceType == DashboardSpaceType.couple) {
        result = await _spaceService.completeDuoHabit(habitId: habit.id);
      } else {
        result = await _spaceService.completeGroupHabit(habitId: habit.id);
      }

      final success = result['success'] == true;
      if (!success) {
        if (!isClosed) emit(current);
        return false;
      }

      final streakMap = result['streak'] as Map<String, dynamic>? ?? {};
      final celebration = result['celebration'] as Map<String, dynamic>? ?? {};

      final serverStreak = streakMap['current'] as int? ?? (habit.currentStreak + 1);
      final serverBest = streakMap['best'] as int? ?? (habit.bestStreak);
      final message = celebration['message'] as String? ?? '🎉 Habit completed!';
      final category = celebration['category'] as String? ?? 'streak_progress';

      final serverHabits = updatedHabits.map((h) {
        if (h.id != habit.id) return h;
        return h.copyWith(
          currentStreak: serverStreak,
          bestStreak: serverBest,
          isDoneToday: true,
        );
      }).toList();

      if (!isClosed) {
        emit(AllDashboardHabitCompleted(
          data: DashboardData(
            habits: serverHabits,
            alerts: current.data.alerts,
            endedHabits: current.data.endedHabits,
          ),
          habitId: habit.id,
          completionMessage: message,
          category: category,
          currentStreak: serverStreak,
          bestStreak: serverBest,
        ));
      }

      _silentRefresh();
      return true;
    } catch (e) {
      if (!isClosed) emit(current);
      return false;
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final spaces = await _spaceService.getUserSpaces(userId);
      final List<DashboardAlert> allAlerts = [];
      final List<DashboardHabit> allHabits = [];
      final List<EndedHabit> allEndedHabits = [];
      
      final futures = spaces.map((space) async {
        try {
          Map<String, dynamic> response;
          if (space.type == 'solo') {
            response = await _spaceService.getSoloDashboard(spaceId: space.id, userId: userId);
          } else if (space.type == 'couple') {
            response = await _spaceService.getCoupleDashboard(spaceId: space.id, userId: userId);
          } else {
            response = await _spaceService.getGroupDashboard(spaceId: space.id, userId: userId);
          }
          return DashboardData.fromJson(response);
        } catch (_) {
          return DashboardData(habits: [], alerts: [], endedHabits: []);
        }
      });

      final results = await Future.wait(futures);
      for (var data in results) {
        allAlerts.addAll(data.alerts);
        allHabits.addAll(data.habits);
        allEndedHabits.addAll(data.endedHabits);
      }
      
      allHabits.sort((a, b) {
        final aPending = a.isScheduledToday && !a.isDoneToday;
        final bPending = b.isScheduledToday && !b.isDoneToday;
        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;
        final aDone = a.isScheduledToday && a.isDoneToday;
        final bDone = b.isScheduledToday && b.isDoneToday;
        if (aDone && !bDone) return -1;
        if (!aDone && bDone) return 1;
        return 0;
      });

      if (!isClosed && state is! AllDashboardHabitCompleted) {
        emit(AllDashboardLoaded(data: DashboardData(
          alerts: allAlerts,
          habits: allHabits,
          endedHabits: allEndedHabits,
        )));
      }
    } catch (_) {}
  }
}
