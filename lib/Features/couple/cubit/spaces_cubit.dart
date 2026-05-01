import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/space_service.dart';
import '../../invites/cubit/invite_cubit.dart';
import '../../invites/cubit/invite_state.dart';
import 'spaces_state.dart';

class SpacesCubit extends Cubit<SpacesState> {
  final SpaceService spaceService;
  String userId;
  StreamSubscription<InviteState>? _inviteSubscription;

  SpacesCubit({
    required this.spaceService,
    required this.userId,
    InviteCubit? inviteCubit,
  }) : super(SpacesInitial()) {
    // Auto-reload when an invite is accepted
    if (inviteCubit != null) {
      _inviteSubscription = inviteCubit.stream.listen((state) {
        if (state is InviteAccepted) {
          loadSpaces();
        }
      });
    }
  }

  void updateUserId(String newId) {
    userId = newId;
    loadSpaces();
  }

  Future<void> loadSpaces() async {
    emit(SpacesLoading());
    try {
      final spaces = await spaceService.getUserSpaces(userId);
      final coupleSpaces = spaces.where((s) => s.type == 'couple').toList();
      final groupSpaces = spaces.where((s) => s.type == 'group').toList();
      if (!isClosed) {
        emit(
          SpacesLoaded(coupleSpaces: coupleSpaces, groupSpaces: groupSpaces),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(SpacesError('Failed to load spaces: ${e.toString()}'));
      }
    }
  }

  Future<void> createSpace({
    required String name,
    required String type,
    required List<String> memberIds,
  }) async {
    try {
      emit(SpaceCreating());
      final space = await spaceService.createSpace(
        name: name,
        type: type,
      );
      if (!isClosed) {
        emit(SpaceCreated(space));
        await loadSpaces();
      }
    } catch (e) {
      if (!isClosed) {
        emit(SpacesError('Failed to create space: ${e.toString()}'));
        await loadSpaces();
      }
    }
  }

  Future<void> deleteSpace(String spaceId) async {
    try {
      await spaceService.deleteSpace(spaceId);
      if (!isClosed) await loadSpaces();
    } catch (e) {
      if (!isClosed)
        emit(SpacesError('Failed to delete space: ${e.toString()}'));
    }
  }

  Future<void> leaveSpace(String spaceId) async {
    try {
      await spaceService.removeMemberFromSpace(
        spaceId: spaceId,
        userId: userId,
      );
      if (!isClosed) await loadSpaces();
    } catch (e) {
      if (!isClosed)
        emit(SpacesError('Failed to leave space: ${e.toString()}'));
    }
  }

  /// Owner removes another member via the remove_space_member RPC.
  Future<void> removeMember({
    required String spaceId,
    required String targetUserId,
  }) async {
    emit(MemberRemoving());
    try {
      final result = await spaceService.removeSpaceMember(
        spaceId: spaceId,
        userId: targetUserId,
      );
      if (result['success'] == true) {
        if (!isClosed) {
          emit(MemberRemoved(result['message'] as String? ?? 'Member removed ✅'));
          await loadSpaces();
        }
      } else {
        if (!isClosed) {
          emit(SpacesError(result['message'] as String? ?? 'Failed to remove member'));
          await loadSpaces();
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(SpacesError('Failed to remove member: ${e.toString()}'));
        await loadSpaces();
      }
    }
  }

  @override
  Future<void> close() {
    _inviteSubscription?.cancel();
    return super.close();
  }
}
