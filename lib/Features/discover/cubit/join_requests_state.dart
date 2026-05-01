// filepath: d:\habitz\lib\Features\discover\cubit\join_requests_state.dart
import 'package:equatable/equatable.dart';
import '../models/discover_models.dart';

enum JoinRequestsStatus { initial, loading, loaded, error }

class JoinRequestsState extends Equatable {
  final List<JoinRequest> requests;
  final JoinRequestsStatus status;
  final String? error;
  final Set<String> processingIds; // request IDs currently being handled

  const JoinRequestsState({
    this.requests = const [],
    this.status = JoinRequestsStatus.initial,
    this.error,
    this.processingIds = const {},
  });

  JoinRequestsState copyWith({
    List<JoinRequest>? requests,
    JoinRequestsStatus? status,
    String? error,
    Set<String>? processingIds,
    bool clearError = false,
  }) {
    return JoinRequestsState(
      requests: requests ?? this.requests,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      processingIds: processingIds ?? this.processingIds,
    );
  }

  @override
  List<Object?> get props => [requests, status, error, processingIds];
}

