import 'package:equatable/equatable.dart';
import '../models/discover_models.dart';

class ActivePeopleState extends Equatable {
  final List<DiscoverPerson> people;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String? error;

  const ActivePeopleState({
    this.people = const [],
    this.isLoading = true, // shows shimmer immediately on first render
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  ActivePeopleState copyWith({
    List<DiscoverPerson>? people,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? error,
    bool clearError = false,
  }) {
    return ActivePeopleState(
      people: people ?? this.people,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    people,
    isLoading,
    isLoadingMore,
    hasMore,
    offset,
    error,
  ];
}
