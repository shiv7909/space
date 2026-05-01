import 'package:equatable/equatable.dart';
import '../../../models/snap_tray_model.dart';

abstract class SnapState extends Equatable {
  const SnapState();

  @override
  List<Object?> get props => [];
}

class SnapInitial extends SnapState {}

class SnapLoading extends SnapState {}

/// Tray loaded — one bubble per sender, sorted unseen-first by backend.
class SnapTrayLoaded extends SnapState {
  final SnapTrayResponse trayResponse;
  final String spaceId;

  const SnapTrayLoaded({required this.trayResponse, required this.spaceId});

  /// Convenience getters
  List<SnapTrayItem> get tray => trayResponse.tray;
  bool get iPostedToday => trayResponse.iPostedToday;
  int  get totalActiveSnaps => trayResponse.totalActiveSnaps;
  int  get unseenCount => trayResponse.unseenCount;

  @override
  List<Object?> get props => [trayResponse.tray.length, spaceId, trayResponse.unseenCount];
}

/// Uploading a new snap (camera → storage → RPC).
class SnapSending extends SnapTrayLoaded {
  const SnapSending({required super.trayResponse, required super.spaceId});
}

/// Snap sent successfully — tray refreshed.
class SnapSent extends SnapTrayLoaded {
  final String message;
  const SnapSent({
    required super.trayResponse,
    required super.spaceId,
    this.message = 'Snap sent!',
  });

  @override
  List<Object?> get props => [trayResponse.tray.length, spaceId, message];
}

class SnapError extends SnapState {
  final String message;
  final SnapTrayResponse? previousTray;
  final String? spaceId;

  const SnapError({
    required this.message,
    this.previousTray,
    this.spaceId,
  });

  @override
  List<Object?> get props => [message, spaceId];
}
