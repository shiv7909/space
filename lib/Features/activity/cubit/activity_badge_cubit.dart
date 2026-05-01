import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

class ActivityBadgeState extends Equatable {
  final int count;

  const ActivityBadgeState({this.count = 0});

  @override
  List<Object> get props => [count];
}

class ActivityBadgeCubit extends Cubit<ActivityBadgeState> with WidgetsBindingObserver {
  final SupabaseClient supabase;
  int _latestTotal = 0;
  int _seenCount = 0;

  ActivityBadgeCubit(this.supabase) : super(const ActivityBadgeState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (supabase.auth.currentUser != null) {
        refreshBadgeCount();
      }
    }
  }

  Future<void> refreshBadgeCount({bool markRead = false}) async {
    try {
      if (supabase.auth.currentUser == null) {
        emit(const ActivityBadgeState(count: 0));
        return;
      }

      final results = await Future.wait([
        supabase.rpc('get_pending_join_requests'),
        supabase.rpc('get_my_pending_invites'),
      ]);

      // Handle cases where RPC returns list directly or wrapped in { "data": ... } or { "requests": ... }
      // The user prompt implies: (results[0]['requests'] as List? ?? []).length

      final requestsData = results[0];
      final invitesData = results[1];

      int requestsCount = 0;
      int invitesCount = 0;

      // Safe parsing for requests
      if (requestsData is Map && requestsData.containsKey('requests')) {
        requestsCount = (requestsData['requests'] as List? ?? []).length;
      } else if (requestsData is List) {
        requestsCount = requestsData.length;
      }

      // Safe parsing for invites
      if (invitesData is Map && invitesData.containsKey('invites')) {
        invitesCount = (invitesData['invites'] as List? ?? []).length;
      } else if (invitesData is List) {
        invitesCount = invitesData.length;
      }

      final total = requestsCount + invitesCount;
      print('🔴 ActivityBadgeCubit: Requests($requestsCount) + Invites($invitesCount) = $total');

      _latestTotal = total;

      if (markRead) {
        _seenCount = total;
        emit(const ActivityBadgeState(count: 0));
      } else if (total > _seenCount) {
        emit(ActivityBadgeState(count: total));
      } else {
        // If count dropped (e.g. accepted on another device or cleared),
        // lower the seen count so future increments trigger the badge.
        if (total < _seenCount) {
          _seenCount = total;
        }
        emit(const ActivityBadgeState(count: 0));
      }

    } catch (e) {
      print('🔴 ActivityBadgeCubit: refresh failed: $e');
      // keep previous value on error — do not set to 0
    }
  }

  void markAsSeen() {
    _seenCount = _latestTotal;
    emit(const ActivityBadgeState(count: 0));
    // Ensure we sync with server to avoid race conditions with stale _latestTotal
    refreshBadgeCount(markRead: true);
  }

  // Call this when user logs in
  void initForUser() {
    refreshBadgeCount();
  }

  // Call this when user logs out
  void clear() {
    emit(const ActivityBadgeState(count: 0));
  }
}
