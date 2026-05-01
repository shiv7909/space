import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/space_service.dart';
import '../../../models/invite_model.dart';
import 'invite_state.dart';

class InviteCubit extends Cubit<InviteState> {
  final SpaceService spaceService;
  Timer? _pollTimer;
  bool _isPolling = false;
  bool _isFetching = false;
  DateTime? _lastFetchTime;

  /// Minimum seconds between fetches — prevents spam from multiple BlocBuilders
  static const _fetchCooldownSeconds = 10;

  InviteCubit({required this.spaceService}) : super(InviteInitial());

  /// Load pending invites from the server.
  /// Skips the call if one is already in flight or if fetched within the cooldown window.
  Future<void> loadInvites({bool force = false}) async {
    if (_isFetching) return; // already in flight

    if (!force && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!).inSeconds;
      if (elapsed < _fetchCooldownSeconds) return; // too soon
    }

    _isFetching = true;

    // Don't show loading spinner on subsequent refreshes
    if (state is InviteInitial) {
      emit(InviteLoading());
    }

    try {
      final invites = await spaceService.getMyPendingInvites();
      _lastFetchTime = DateTime.now();
      if (!isClosed) {
        emit(InviteLoaded(invites: invites));
      }
    } catch (e) {
      if (!isClosed) {
        emit(InviteError('Failed to load invites: ${e.toString()}'));
      }
    } finally {
      _isFetching = false;
    }
  }

  /// Start polling every 30 seconds.
  /// Safe to call multiple times — only starts once.
  void startPolling() {
    if (_isPolling) return; // already running — don't restart
    _isPolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadInvites(force: true);
    });
    // Initial load
    loadInvites();
  }

  /// Stop the polling timer.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  /// Accept an invite — adds user to the space.
  /// On CONFLICT_OWNER / CONFLICT_MEMBER emits [InviteConflict] so the UI
  /// can show the danger dialog before calling [forceAcceptInvite].
  Future<void> acceptInvite(String inviteId) async {
    try {
      final result = await spaceService.acceptInvite(inviteId, force: false);

      if (!isClosed) {
        if (result['success'] == true) {
          _emitAccepted(inviteId, result);
        } else {
          final code = result['code'] as String? ?? '';
          if (code == 'CONFLICT_OWNER' || code == 'CONFLICT_MEMBER') {
            final currentInvites = state is InviteLoaded
                ? (state as InviteLoaded).invites
                : const <InviteModel>[];
            emit(InviteConflict(
              invites: currentInvites,
              inviteId: inviteId,
              code: code,
              conflictSpaceName:
                  result['conflict_space_name'] as String? ?? 'your current space',
            ));
          } else {
            emit(InviteError(
              result['message'] as String? ?? 'Failed to accept invite',
            ));
            _lastFetchTime = null;
            await loadInvites(force: true);
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(InviteError('Error accepting invite: ${e.toString()}'));
        _lastFetchTime = null;
        await loadInvites(force: true);
      }
    }
  }

  /// Force-accept after the user confirms the conflict dialog.
  Future<void> forceAcceptInvite(String inviteId) async {
    try {
      final result = await spaceService.acceptInvite(inviteId, force: true);

      if (!isClosed) {
        if (result['success'] == true) {
          _emitAccepted(inviteId, result);
        } else {
          emit(InviteError(
            result['message'] as String? ?? 'Failed to join space',
          ));
          _lastFetchTime = null;
          await loadInvites(force: true);
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(InviteError('Error joining space: ${e.toString()}'));
        _lastFetchTime = null;
        await loadInvites(force: true);
      }
    }
  }

  /// Shared helper — emits [InviteAccepted] then resets to [InviteLoaded].
  void _emitAccepted(String inviteId, Map<String, dynamic> result) {
    final currentState = state;
    final List<InviteModel> currentInvites =
        currentState is InviteLoaded ? currentState.invites : const [];

    final acceptedInvite =
        currentInvites.where((i) => i.inviteId == inviteId).firstOrNull;

    final updated = List<InviteModel>.from(
        currentInvites.where((i) => i.inviteId != inviteId));

    emit(InviteAccepted(
      invites: updated,
      spaceId: result['space_id'] as String? ?? acceptedInvite?.spaceId ?? '',
      message: result['message'] as String? ?? 'Invite accepted! 🎉',
      spaceType: acceptedInvite?.spaceType ?? 'couple',
    ));

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isClosed) emit(InviteLoaded(invites: updated));
    });
  }

  /// Reject an invite — removes it from the list.
  Future<void> rejectInvite(String inviteId) async {
    try {
      final result = await spaceService.rejectInvite(inviteId);

      if (!isClosed) {
        if (result['success'] == true) {
          final currentState = state;
          final List<InviteModel> currentInvites =
              currentState is InviteLoaded ? currentState.invites : const [];
          final updated = List<InviteModel>.from(
              currentInvites.where((i) => i.inviteId != inviteId));

          emit(InviteRejected(
            invites: updated,
            message: result['message'] as String? ?? 'Invite rejected.',
          ));

          await Future.delayed(const Duration(milliseconds: 100));
          if (!isClosed) {
            emit(InviteLoaded(invites: updated));
          }
        } else {
          emit(InviteError(
            result['message'] as String? ?? 'Failed to reject invite',
          ));
          await loadInvites();
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(InviteError('Error rejecting invite: ${e.toString()}'));
        await loadInvites();
      }
    }
  }

  /// Get current invite count (for badge).
  int get pendingCount {
    final s = state;
    if (s is InviteLoaded) return s.count;
    return 0;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
