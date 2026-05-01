import '../models/habit_model.dart';

/// Data wrapper passed into the cinematic screen.
/// [habit]     – the habit that was just created / acted upon.
/// [spaceType] – 'solo', 'couple', or 'group' (from SpaceModel.type).
/// [success]   – whether the operation succeeded.
/// [errorMessage] – optional message shown when [success] is false.
class CinematicPayload {
  final HabitModel habit;
  final String spaceType;
  final bool success;
  final String? errorMessage;

  const CinematicPayload({
    required this.habit,
    required this.spaceType,
    this.success = true,
    this.errorMessage,
  });
}
