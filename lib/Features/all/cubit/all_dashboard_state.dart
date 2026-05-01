import 'package:equatable/equatable.dart';
import '../../../models/dashboard_model.dart';

abstract class AllDashboardState extends Equatable {
  const AllDashboardState();
  
  @override
  List<Object?> get props => [];
}

class AllDashboardInitial extends AllDashboardState {}

class AllDashboardLoading extends AllDashboardState {}

class AllDashboardRefreshing extends AllDashboardState {
  final DashboardData data;
  const AllDashboardRefreshing({required this.data});
  
  @override
  List<Object?> get props => [data];
}

class AllDashboardLoaded extends AllDashboardState {
  final DashboardData data;
  final String? focusHabitId;

  const AllDashboardLoaded({required this.data, this.focusHabitId});

  @override
  List<Object?> get props => [data, focusHabitId];
}

class AllDashboardError extends AllDashboardState {
  final String message;
  const AllDashboardError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Emitted when a habit is completed successfully in the All dashboard.
class AllDashboardHabitCompleted extends AllDashboardState {
  final DashboardData data;
  final String habitId;
  final String completionMessage;
  final String category;
  final int currentStreak;
  final int bestStreak;

  const AllDashboardHabitCompleted({
    required this.data,
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
