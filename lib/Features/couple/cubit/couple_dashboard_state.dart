import 'package:equatable/equatable.dart';
import '../../../models/dashboard_model.dart';

abstract class CoupleDashboardState extends Equatable {
  const CoupleDashboardState();

  @override
  List<Object?> get props => [];
}

class CoupleDashboardInitial extends CoupleDashboardState {}

class CoupleDashboardLoading extends CoupleDashboardState {}

/// Silent refresh — keeps the old data visible while new data loads.
class CoupleDashboardRefreshing extends CoupleDashboardLoaded {
  const CoupleDashboardRefreshing({required super.data});
}

class CoupleDashboardLoaded extends CoupleDashboardState {
  final DashboardData data;
  final String? focusHabitId;

  const CoupleDashboardLoaded({required this.data, this.focusHabitId});

  @override
  List<Object?> get props => [data, focusHabitId];
}

/// Emitted right after a habit is marked complete.
class CoupleDashboardHabitCompleted extends CoupleDashboardLoaded {
  final String habitId;
  final String completionMessage;
  final String category;
  final int currentStreak;
  final int bestStreak;

  const CoupleDashboardHabitCompleted({
    required super.data,
    required this.habitId,
    required this.completionMessage,
    required this.category,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  List<Object?> get props => [
    data,
    habitId,
    completionMessage,
    category,
    currentStreak,
    bestStreak,
  ];
}

class CoupleDashboardError extends CoupleDashboardState {
  final String message;

  const CoupleDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
