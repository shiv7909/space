import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/habit_model.dart';

abstract class HabitsState {}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<HabitModel> habits;
  HabitsLoaded(this.habits);
}

class HabitsError extends HabitsState {
  final String message;
  HabitsError(this.message);
}
