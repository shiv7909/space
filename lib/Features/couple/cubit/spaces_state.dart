import 'package:equatable/equatable.dart';
import '../../../models/space_model.dart';

abstract class SpacesState extends Equatable {
  const SpacesState();
  @override
  List<Object?> get props => [];
}

class SpacesInitial extends SpacesState {}

class SpacesLoading extends SpacesState {}

class SpacesLoaded extends SpacesState {
  final List<SpaceModel> coupleSpaces;
  final List<SpaceModel> groupSpaces;

  const SpacesLoaded({required this.coupleSpaces, required this.groupSpaces});

  @override
  List<Object?> get props => [coupleSpaces, groupSpaces];

  SpacesLoaded copyWith({
    List<SpaceModel>? coupleSpaces,
    List<SpaceModel>? groupSpaces,
  }) {
    return SpacesLoaded(
      coupleSpaces: coupleSpaces ?? this.coupleSpaces,
      groupSpaces: groupSpaces ?? this.groupSpaces,
    );
  }
}

class SpacesError extends SpacesState {
  final String message;
  const SpacesError(this.message);
  @override
  List<Object> get props => [message];
}

class SpaceCreating extends SpacesState {}

class SpaceCreated extends SpacesState {
  final SpaceModel space;
  const SpaceCreated(this.space);
  @override
  List<Object> get props => [space];
}

class MemberRemoving extends SpacesState {}

class MemberRemoved extends SpacesState {
  final String message;
  const MemberRemoved(this.message);
  @override
  List<Object> get props => [message];
}
