import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_helpers.dart';
import '../../../services/space_service.dart';
import '../../../models/habit_model.dart';
import 'habits_state.dart';

class HabitsCubit extends Cubit<HabitsState> {
  final SpaceService _spaceService;

  HabitsCubit(this._spaceService) : super(HabitsInitial());

  Future<void> loadHabits({String? spaceId}) async {
    if (isClosed) return;
    try {
      emit(HabitsLoading());

      final rawHabits = await _spaceService.getHabits(spaceId: spaceId);

      if (isClosed) return;

      final habits =
          rawHabits.map((data) => HabitModel.fromJson(data)).toList();

      emit(HabitsLoaded(habits));
    } catch (e) {
      if (isClosed) return;
      emit(HabitsError(userMessage(e)));
    }
  }
}
