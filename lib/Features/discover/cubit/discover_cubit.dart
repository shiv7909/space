// filepath: d:\habitz\lib\Features\discover\cubit\discover_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discover_models.dart';
import 'discover_state.dart';

// ── Result type for join requests ─────────────────────────────────────────
sealed class JoinResult {
  const JoinResult();
}

class JoinSuccess extends JoinResult {
  const JoinSuccess();
}



class JoinError extends JoinResult {
  final String message;
  const JoinError(this.message);
}

// ─────────────────────────────────────────────────────────────────────────

class DiscoverCubit extends Cubit<DiscoverState> {
  final SupabaseClient _supabase;

  DiscoverCubit(this._supabase) : super(const DiscoverState());

  String get userId => _supabase.auth.currentUser!.id;

  // ── Load everything at once (on screen open) ─────────────────────────────
  Future<void> loadAll(Position? pos) async {
    // Initial load of everything
    await Future.wait([
      _loadActivePeople(pos),
      if (state.trendingSpaces.isEmpty) _loadTrending(pos), // Guarded
      fetchSpaces(pos: pos, loadMore: false),
    ]);
  }

  // ── Active people ─────────────────────────────────────────────────────────
  Future<void> _loadActivePeople(Position? pos) async {
    try {
      final res = await _supabase.rpc('get_active_people', params: {
        if (pos != null) 'p_lat': pos.latitude,
        if (pos != null) 'p_lng': pos.longitude,
        'p_limit': 20,  // ✅ Already set to 20
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] == true) {
        final people = (data['people'] as List? ?? [])
            .map((p) => ActivePerson.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
        emit(state.copyWith(activePeople: people));
      }
    } catch (e) {
      // Silently fail — active people section is optional
      print('🔴 DiscoverCubit: Error loading active people: $e');
    }
  }

  // ── Trending carousel ────────────────────────────────────────────────────
  Future<void> _loadTrending(Position? pos) async {
    // Do not emit global loading here, it flickers the whole screen
    try {
      final res = await _supabase.rpc('get_discover_feed', params: {
        'p_filter':     'trending',
        'p_search':     null,
        'p_lat':        pos?.latitude,
        'p_lng':        pos?.longitude,
        'p_radius_km':  25,
        'p_limit':      10,
        'p_offset':     0,
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] == true) {
        final spaces = (data['spaces'] as List? ?? [])
            .map((s) => DiscoverSpace.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();

        // Only update if we actually found items, but emit empty list if none found so UI clears old data
        emit(state.copyWith(trendingSpaces: spaces));
      }
    } catch (e) {
      print('🔴 DiscoverCubit: Error loading trending: $e');
    }
  }

  // ── Main feed (The Fetch Function) ───────────────────────────────────────
  Future<void> fetchSpaces({required Position? pos, bool loadMore = false}) async {
    if (!loadMore) {
      // When switching filters, keep old spaces visible while loading new ones
      // Don't clear the list immediately — show loading indicator over old content
      emit(state.copyWith(
        offset: 0,
        isLoading: true,  // ✅ Set loading FIRST
        hasMore: true,
        total: 0,
      ));
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true));
    }

    try {
      final currentOffset = loadMore ? state.offset : 0;

      final res = await _supabase.rpc('get_discover_feed', params: {
        'p_filter':     state.activeFilter,
        'p_search':     state.searchQuery.isEmpty ? null : state.searchQuery,
        'p_lat':        pos?.latitude,
        'p_lng':        pos?.longitude,
        'p_radius_km':  25,
        'p_limit':      20,
        'p_offset':     currentOffset,
      });

      final data = Map<String, dynamic>.from(res as Map);

      if (data['success'] == true) {
        final newSpaces = (data['spaces'] as List? ?? [])
            .map((s) => DiscoverSpace.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();

        final total = data['total'] as int? ?? 0;
        final hasMore = data['has_more'] as bool? ?? false;

        // Calculate next offset based on actual list length
        final nextOffset = currentOffset + newSpaces.length;

        if (loadMore) {
           emit(state.copyWith(
            spaces: [...state.spaces, ...newSpaces],
            offset: nextOffset,
            total: total,
            hasMore: hasMore,
            isLoading: false,
            isLoadingMore: false,
          ));
        } else {
          // When not loading more (filter change), replace with new spaces
          emit(state.copyWith(
            spaces: newSpaces,
            offset: nextOffset,
            total: total,
            hasMore: hasMore,
            isLoading: false,
            isLoadingMore: false,
            isSearching: false,
          ));
        }
      }
    } catch (e) {
      print('🔴 DiscoverCubit: Error loading feed: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
        isLoadingMore: false,
        isSearching: false,
      ));
    }
  }

  // ── Public actions ────────────────────────────────────────────────────────

  Future<void> setFilter(String filter, Position? pos) async {
    if (state.activeFilter == filter) return;
    emit(state.copyWith(activeFilter: filter));
    // Chip tap → reset offset to 0, clear list, call fetch
    await fetchSpaces(pos: pos, loadMore: false);
  }

  Future<void> search(String query, Position? pos) async {
    emit(state.copyWith(searchQuery: query, isSearching: true));
    // Search tap → reset offset to 0
    await fetchSpaces(pos: pos, loadMore: false);
  }

  Future<void> refresh(Position? pos) => loadAll(pos);

  // ── Join request ──────────────────────────────────────────────────────────
  /// Returns error string or null on success
  Future<JoinResult> requestToJoin(String spaceId, {String? message}) async {
    try {
      final res = await _supabase.rpc('request_to_join_space', params: {
        'p_space_id': spaceId,
        if (message != null && message.isNotEmpty) 'p_message': message,
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] == true) {
        _markRequested(spaceId);
        return const JoinSuccess(); // success
      }

      return switch (data['code'] as String? ?? '') {
        'ALREADY_REQUESTED' => const JoinError('You already have a pending request'),
        'SPACE_FULL' => const JoinError('This space is full'),
        'ALREADY_MEMBER' => const JoinError('You are already in this space'),
        'SPACE_IS_PRIVATE' => const JoinError('This space is private'),
        'NOT_PREMIUM' => const JoinError('Something went wrong. Try again.'),
        _ => const JoinError('Something went wrong. Try again.'),
      };
    } catch (e) {
      return const JoinError('Something went wrong. Try again.');
    }
  }

  void _markRequested(String spaceId) {
    final updatedFeed = state.spaces
        .map((s) => s.spaceId == spaceId ? s.copyWith(iRequested: true) : s)
        .toList();
    final updatedTrending = state.trendingSpaces
        .map((s) => s.spaceId == spaceId ? s.copyWith(iRequested: true) : s)
        .toList();
    emit(state.copyWith(
      spaces: updatedFeed,
      trendingSpaces: updatedTrending,
    ));
  }
}
