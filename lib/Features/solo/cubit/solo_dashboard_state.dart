import 'package:equatable/equatable.dart';
import '../../../models/dashboard_model.dart';

abstract class SoloDashboardState extends Equatable {
  const SoloDashboardState();

  @override
  List<Object?> get props => [];
}

class SoloDashboardInitial extends SoloDashboardState {}

class SoloDashboardLoading extends SoloDashboardState {}

/// Silent refresh — keeps the old data visible while new data loads in the background.
class SoloDashboardRefreshing extends SoloDashboardLoaded {
  const SoloDashboardRefreshing({required super.data});
}

class SoloDashboardLoaded extends SoloDashboardState {
  final DashboardData data;
  final String? focusHabitId;

  const SoloDashboardLoaded({required this.data, this.focusHabitId});

  @override
  List<Object?> get props => [data, focusHabitId];
}

/// Emitted right after a habit is marked complete.
/// Carries the motivational message & streak info from the RPC.
class SoloDashboardHabitCompleted extends SoloDashboardLoaded {
  final String habitId;
  final String completionMessage;
  final String category;
  final int currentStreak;
  final int bestStreak;

  const SoloDashboardHabitCompleted({
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

class SoloDashboardError extends SoloDashboardState {
  final String message;

  const SoloDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
