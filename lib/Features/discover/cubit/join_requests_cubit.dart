// filepath: d:\habitz\lib\Features\discover\cubit\join_requests_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discover_models.dart';
import 'join_requests_state.dart';

class JoinRequestsCubit extends Cubit<JoinRequestsState> {
  final SupabaseClient _supabase;
  final String spaceId;

  JoinRequestsCubit(this._supabase, {required this.spaceId})
      : super(const JoinRequestsState());

  Future<void> loadRequests() async {
    emit(state.copyWith(status: JoinRequestsStatus.loading, clearError: true));

    try {
      final res = await _supabase.rpc('get_pending_join_requests', params: {
        'p_space_id': spaceId,
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] == true) {
        final requests = (data['requests'] as List? ?? [])
            .map((r) =>
                JoinRequest.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        emit(state.copyWith(
          requests: requests,
          status: JoinRequestsStatus.loaded,
        ));
      } else {
        final code = data['code'] as String? ?? '';
        emit(state.copyWith(
          status: JoinRequestsStatus.error,
          error: code == 'NOT_OWNER'
              ? 'Only the space owner can view requests'
              : 'Failed to load requests',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: JoinRequestsStatus.error,
        error: 'Failed to load requests',
      ));
    }
  }

  /// Handle a join request — returns error string or null on success
  Future<String?> handleRequest(String requestId, String action) async {
    // Mark as processing
    emit(state.copyWith(
      processingIds: {...state.processingIds, requestId},
    ));

    try {
      final res = await _supabase.rpc('handle_join_request', params: {
        'p_request_id': requestId,
        'p_action': action,
        'p_force': false,
      });

      final data = Map<String, dynamic>.from(res as Map);

      // Remove from processing
      final updatedProcessing = {...state.processingIds}..remove(requestId);

      if (data['success'] == true) {
        // Optimistically remove the request from the list
        final updatedRequests =
            state.requests.where((r) => r.requestId != requestId).toList();
        emit(state.copyWith(
          requests: updatedRequests,
          processingIds: updatedProcessing,
        ));
        return null;
      }

      emit(state.copyWith(processingIds: updatedProcessing));

      return switch (data['code'] as String? ?? '') {
        'NOT_OWNER' => 'Only the space owner can handle requests',
        'ALREADY_HANDLED' => 'This request was already handled',
        'SPACE_FULL' => 'Space is full — cannot accept',
        _ => 'Something went wrong. Try again.',
      };
    } catch (e) {
      final updatedProcessing = {...state.processingIds}..remove(requestId);
      emit(state.copyWith(processingIds: updatedProcessing));
      return 'Something went wrong. Try again.';
    }
  }
}
