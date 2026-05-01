import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final SupabaseClient supabase;

  ActivityCubit(this.supabase) : super(const ActivityState());

  Future<void> loadAll() async {
    emit(state.copyWith(status: ActivityStatus.loading));

    try {
      final results = await Future.wait([
        supabase.rpc('get_pending_join_requests'),  // [0]
        supabase.rpc('get_my_pending_invites'),     // [1]
        supabase.rpc('get_my_sent_requests'),       // [2]
        supabase.rpc('get_my_sent_invites'),        // [3]
      ]);

      // 1. get_pending_join_requests -> key: 'requests'
      final joinRequests = _safeParse(results[0], key: 'requests')
          .map((e) => {
            ...e,
            '_type': 'incoming_request',
            // Ensure created_at exists for sorting if backend sends requested_at
            if (e['created_at'] == null && e['requested_at'] != null) 'created_at': e['requested_at']
          })
          .toList();

      // 2. get_my_pending_invites -> key: 'invites'
      final pendingInvites = _safeParse(results[1], key: 'invites')
          .map((e) => { ...e, '_type': 'incoming_invite' })
          .toList();

      // Merge and sort For You by created_at DESC
      final forYouItems = [...joinRequests, ...pendingInvites]
        ..sort((a, b) {
            final tA = a['created_at'] ?? a['requested_at'];
            final tB = b['created_at'] ?? b['requested_at'];
            if (tA == null || tB == null) return 0;
            return DateTime.parse(tB).compareTo(DateTime.parse(tA));
        });

      // 3. get_my_sent_requests -> key: 'requests'
      // Backend filters: pending always + accepted within 7 days.
      final sentRequests = _safeParse(results[2], key: 'requests');

      // 4. get_my_sent_invites -> key: 'invites'
      // Backend filters: pending always + accepted within 7 days.
      final sentInvites = _safeParse(results[3], key: 'invites');

      // Badge = count of all actionable items
      final badgeCount = forYouItems.length;

      emit(state.copyWith(
        status: ActivityStatus.success,
        forYouItems: forYouItems,
        sentRequests: sentRequests,
        sentInvites: sentInvites,
        badgeCount: badgeCount,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.failure,
        errorMessage: e.toString()
      ));
    }
  }

  /// Parses RPC response that might be `[{...}]` OR `{ "key": [{...}] }`
  List<Map<String, dynamic>> _safeParse(dynamic response, {String? key}) {
    if (response == null) return [];

    // Case 1: Direct List
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // Case 2: Wrapped Map
    if (response is Map) {
      // If we have a key, try to find the list at that key
      if (key != null && response[key] is List) {
        return (response[key] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      // If no key provided, or key not found, maybe the map itself is not what we want.
      // Or maybe the key was wrong?
      // Some RPCs might return { 'data': [...] } or just the list.
    }

    return [];
  }

  // --- ACTIONS ---

  Future<void> acceptJoinRequest(Map<String, dynamic> item, {bool force = false}) async {
    // Optimistic remove
    final previousItems = [...state.forYouItems];
    final newItems = [...state.forYouItems]..remove(item);

    // Update state to remove item, but keep badge count sync for now or let reload handle it?
    // Better to update badge count immediately
    emit(state.copyWith(
      forYouItems: newItems,
      badgeCount: state.badgeCount > 0 ? state.badgeCount - 1 : 0
    ));

    try {
      final res = await supabase.rpc('handle_join_request', params: {
        'p_request_id': item['request_id'],
        'p_action': 'accept',
        'p_force': force,
      });

      if (res['code'] == 'CONFLICT_OWNER' || res['code'] == 'CONFLICT_MEMBER') {
        // Put card back
        emit(state.copyWith(
          forYouItems: previousItems,
          badgeCount: state.badgeCount + 1,
          conflictItem: item,
          conflictMessage: res['message'],
          conflictIsOwner: res['code'] == 'CONFLICT_OWNER',
          conflictType: 'join_request',
        ));
        return;
      }

      if (res['code'] == 'SPACE_FULL') {
        // Keep removed, trigger toast via listener? or put back?
        // Spec says: "keep removed, showToast('Space is full 😅')"
        // We will emit error message for toast
        emit(state.copyWith(errorMessage: 'Space is full 😅'));
        return;
      }

      // Success
      if (res['success'] == true) {
        emit(state.copyWith(errorMessage: 'SUCCESS_MSG:${item['requester_name']} joined ${item['space_name']}! 🎉'));
      }

      // Reload to ensure data consistency? Spec says optimistic is enough.

    } catch (e) {
      // Revert
      emit(state.copyWith(
        forYouItems: previousItems,
         badgeCount: state.badgeCount + 1,
        errorMessage: 'Failed to accept request'
      ));
    }
  }

  Future<void> declineJoinRequest(Map<String, dynamic> item) async {
    final newItems = [...state.forYouItems]..remove(item);
    emit(state.copyWith(forYouItems: newItems, badgeCount: state.badgeCount > 0 ? state.badgeCount - 1 : 0));

    try {
      await supabase.rpc('handle_join_request', params: {
        'p_request_id': item['request_id'],
        'p_action': 'reject',
        'p_force': false,
      });
    } catch (_) {
      // Silent error
    }
  }

  Future<void> acceptInvite(Map<String, dynamic> item, {bool force = false}) async {
    final previousItems = [...state.forYouItems];
    final newItems = [...state.forYouItems]..remove(item);
    emit(state.copyWith(forYouItems: newItems, badgeCount: state.badgeCount > 0 ? state.badgeCount - 1 : 0));

    try {
      final res = await supabase.rpc('accept_invite', params: {
        'p_invite_id': item['invite_id'],
        'p_force': force,
      });

      if (res['code'] == 'CONFLICT_OWNER' || res['code'] == 'CONFLICT_MEMBER') {
        emit(state.copyWith(
          forYouItems: previousItems,
           badgeCount: state.badgeCount + 1,
          conflictItem: item,
          conflictMessage: res['message'],
          conflictIsOwner: res['code'] == 'CONFLICT_OWNER',
          conflictType: 'invite',
        ));
        return;
      }

      if (res['code'] == 'SPACE_FULL') {
        emit(state.copyWith(errorMessage: 'This space is now full 😅'));
        return;
      }

      if (res['success'] == true) {
         emit(state.copyWith(
           errorMessage: 'SUCCESS_MSG:Welcome to ${item['space_name']}! 🎉',
           joinedSpaceId: item['space_id'],
           joinedSpaceType: item['space_type'],
         ));
      }
    } catch (e) {
      // Revert
      emit(state.copyWith(
        forYouItems: previousItems,
        badgeCount: state.badgeCount + 1,
        errorMessage: 'Failed to accept invite'
      ));
    }
  }

  Future<void> declineInvite(Map<String, dynamic> item) async {
    final newItems = [...state.forYouItems]..remove(item);
    emit(state.copyWith(forYouItems: newItems, badgeCount: state.badgeCount > 0 ? state.badgeCount - 1 : 0));

    try {
      await supabase.rpc('reject_invite', params: {
        'p_invite_id': item['invite_id'],
      });
    } catch (_) {
      // Silent
    }
  }

  Future<void> revokeRequest(Map<String, dynamic> item) async {
    final previousItems = [...state.sentRequests];
    final newItems = [...state.sentRequests]..remove(item);
    emit(state.copyWith(sentRequests: newItems));

    try {
      final res = await supabase.rpc('cancel_join_request', params: {
        'p_request_id': item['request_id'],
      });

      if (res['success'] != true) {
         emit(state.copyWith(sentRequests: previousItems, errorMessage: 'Could not revoke. Try again.'));
      }
    } catch (e) {
       emit(state.copyWith(sentRequests: previousItems));
    }
  }

  Future<void> revokeInvite(Map<String, dynamic> item) async {
     final previousItems = [...state.sentInvites];
    final newItems = [...state.sentInvites]..remove(item);
    emit(state.copyWith(sentInvites: newItems));

    try {
      final res = await supabase.rpc('revoke_sent_invite', params: {
        'p_invite_id': item['invite_id'],
      });

      if (res['success'] != true) {
        emit(state.copyWith(sentInvites: previousItems, errorMessage: 'Could not revoke. Try again.'));
      }
    } catch (e) {
       emit(state.copyWith(sentInvites: previousItems));
    }
  }

  void clearConflict() {
    emit(state.clearConflict());
  }

  void resetNavigation() {
    emit(state.clearNavigation());
  }
}
