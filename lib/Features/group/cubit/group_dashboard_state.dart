import 'package:equatable/equatable.dart';
import '../../../models/dashboard_model.dart';

abstract class GroupDashboardState extends Equatable {
  const GroupDashboardState();
  @override
  List<Object?> get props => [];
}

class GroupDashboardInitial extends GroupDashboardState {}

class GroupDashboardLoading extends GroupDashboardState {}

class GroupDashboardLoaded extends GroupDashboardState {
  final DashboardData data;
  final String? focusHabitId;
  const GroupDashboardLoaded({required this.data, this.focusHabitId});
  @override
  List<Object?> get props => [data, focusHabitId];
}

class GroupDashboardError extends GroupDashboardState {
  final String message;
  const GroupDashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
