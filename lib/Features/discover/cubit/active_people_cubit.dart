import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discover_models.dart';
import 'active_people_state.dart';

class ActivePeopleCubit extends Cubit<ActivePeopleState> {
  final SupabaseClient _supabase;
  final int _pageSize = 10; // ✅ Changed back to 10
  double? _lat;
  double? _lng;

  ActivePeopleCubit(this._supabase) : super(const ActivePeopleState());

  // ── Initial load ────────────────────────────────────────────
  Future<void> load({double? lat, double? lng}) async {
    _lat = lat;
    _lng = lng;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final params = {
        if (_lat != null) 'p_lat': _lat,
        if (_lng != null) 'p_lng': _lng,
        'p_limit': _pageSize,
        'p_offset': 0,
      };

      final res = await _supabase.rpc('get_active_people', params: params);

      final data = Map<String, dynamic>.from(res as Map);

      if (data['success'] != true) {
        emit(state.copyWith(
          isLoading: false,
          error: data['message'] as String? ?? 'Failed to load people',
        ));
        return;
      }

      final people = (data['people'] as List? ?? [])
          .map((e) => DiscoverPerson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // ✅ FIXED: Trust the backend's has_more calculation
      final hasMore = data['has_more'] as bool? ?? false;

      emit(state.copyWith(
        isLoading: false,
        people: people,
        hasMore: hasMore,
        offset: people.length,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Something went wrong'));
    }
  }

  // ── Load more (pagination) ───────────────────────────────────
  Future<void> loadMore() async {
    print('📦 loadMore called — hasMore=${state.hasMore}, isLoadingMore=${state.isLoadingMore}, offset=${state.offset}');
    if (!state.hasMore || state.isLoadingMore) {
      print('🛑 loadMore blocked');
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final params = {
        if (_lat != null) 'p_lat': _lat,
        if (_lng != null) 'p_lng': _lng,
        'p_limit': _pageSize,
        'p_offset': state.offset,
      };

      final res = await _supabase.rpc('get_active_people', params: params);

      print('📦 loadMore response: $res');

      final data = Map<String, dynamic>.from(res as Map);

      if (data['success'] != true) {
        print('❌ Backend returned success=false: ${data['message']}');
        emit(state.copyWith(isLoadingMore: false));
        return;
      }

      final newPeople = (data['people'] as List? ?? [])
          .map((e) => DiscoverPerson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final updatedList = [...state.people, ...newPeople];
      final newOffset = state.offset + newPeople.length;

      // ✅ FIXED: Trust the backend's has_more calculation
      final hasMore = data['has_more'] as bool? ?? false;

      print('✅ loadMore success: loaded ${newPeople.length} people, hasMore=$hasMore, newOffset=$newOffset');

      emit(state.copyWith(
        isLoadingMore: false,
        people: updatedList,
        hasMore: hasMore,
        offset: newOffset,
      ));
    } catch (e) {
      print('🔴 loadMore ERROR: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  // ── Request to join via person ───────────────────────────────
  Future<String?> requestToJoin(
    String targetUserId, {
    bool force = false,
    String? spaceType,
  }) async {
    try {
      final res = await _supabase.rpc('request_to_join_via_user', params: {
        'p_target_user_id': targetUserId,
        'p_force':          force,
        if (spaceType != null) 'p_space_type': spaceType,
      });
      final data = Map<String, dynamic>.from(res as Map);

      if (data['success'] == true || data['code'] == 'ALREADY_REQUESTED') {
        // Flip i_requested locally — no full reload needed
        final updated = state.people.map((p) => p.userId == targetUserId
            ? DiscoverPerson.fromJson({...p.toJson(), 'i_requested': true})
            : p).toList();
        emit(state.copyWith(people: updated));
        return null; // null = success
      }

      // Pack conflict space name into the return string
      if (data['code'] == 'CONFLICT_OWNER' || data['code'] == 'CONFLICT_MEMBER') {
        return '${data['code']}|${data['conflict_space_name'] ?? ''}';
      }

      return data['code'] as String?;
    } catch (e) {
      return 'UNKNOWN_ERROR';
    }
  }

  // ── Get my invitable spaces (for invite bottom sheet) ────────
  Future<List<InvitableSpace>> getMyInvitableSpaces(String targetUserId) async {
    try {
      final res = await _supabase.rpc('get_my_invitable_spaces', params: {
        'p_target_user_id': targetUserId,
      });
      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] != true) return [];
      return (data['spaces'] as List? ?? [])
          .map((e) => InvitableSpace.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Send invite by user id ─────────���─────────────────────────
  Future<String?> sendInvite(String targetUserId, String spaceId) async {
    try {
      final res = await _supabase.rpc('send_invite_by_user_id', params: {
        'p_target_user_id': targetUserId,
        'p_space_id': spaceId,
      });
      final data = Map<String, dynamic>.from(res as Map);
      return data['success'] == true ? null : data['code'] as String?;
    } catch (e) {
      return 'UNKNOWN_ERROR';
    }
  }
}
