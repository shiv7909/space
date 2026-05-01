// filepath: d:\habitz\lib\Features\discover\cubit\discover_state.dart
import 'package:equatable/equatable.dart';
import '../models/discover_models.dart';

class DiscoverState extends Equatable {
  final List<ActivePerson> activePeople;
  final List<DiscoverSpace> trendingSpaces;
  final List<DiscoverSpace> spaces;
  final String activeFilter;
  final String searchQuery;
  final bool isLoading;      // Initial load
  final bool isLoadingMore;  // Pagination
  final bool isSearching;    // Search occurring
  final bool hasMore;
  final int offset;
  final int total;
  final String? error;

  const DiscoverState({
    this.activePeople = const [],
    this.trendingSpaces = const [],
    this.spaces = const [],
    this.activeFilter = 'all',
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.hasMore = true,
    this.offset = 0,
    this.total = 0,
    this.error,
  });

  DiscoverState copyWith({
    List<ActivePerson>? activePeople,
    List<DiscoverSpace>? trendingSpaces,
    List<DiscoverSpace>? spaces,
    String? activeFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSearching,
    bool? hasMore,
    int? offset,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return DiscoverState(
      activePeople: activePeople ?? this.activePeople,
      trendingSpaces: trendingSpaces ?? this.trendingSpaces,
      spaces: spaces ?? this.spaces,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        activePeople,
        trendingSpaces,
        spaces,
        activeFilter,
        searchQuery,
        isLoading,
        isLoadingMore,
        isSearching,
        hasMore,
        offset,
        total,
        error,
      ];
}
