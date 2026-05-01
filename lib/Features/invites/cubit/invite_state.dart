import 'package:equatable/equatable.dart';
import '../../../models/invite_model.dart';

abstract class InviteState extends Equatable {
  const InviteState();
  @override
  List<Object?> get props => [];
}

class InviteInitial extends InviteState {}

class InviteLoading extends InviteState {}

class InviteLoaded extends InviteState {
  final List<InviteModel> invites;

  const InviteLoaded({required this.invites});

  int get count => invites.length;
  bool get hasInvites => invites.isNotEmpty;

  @override
  List<Object?> get props => [invites];
}

/// Emitted briefly after an invite is accepted — triggers space reload.
class InviteAccepted extends InviteLoaded {
  final String spaceId;
  final String message;
  final String spaceType; // 'couple' or 'group'

  const InviteAccepted({
    required super.invites,
    required this.spaceId,
    required this.message,
    this.spaceType = 'couple',
  });

  @override
  List<Object?> get props => [invites, spaceId, message, spaceType];
}

/// Emitted briefly after an invite is rejected.
class InviteRejected extends InviteLoaded {
  final String message;

  const InviteRejected({
    required super.invites,
    required this.message,
  });

  @override
  List<Object?> get props => [invites, message];
}

class InviteError extends InviteState {
  final String message;
  const InviteError(this.message);
  @override
  List<Object> get props => [message];
}

/// Emitted when accepting an invite conflicts with an existing space membership.
/// [code] is either 'CONFLICT_OWNER' or 'CONFLICT_MEMBER'.
class InviteConflict extends InviteLoaded {
  final String inviteId;
  final String code;
  final String conflictSpaceName;

  const InviteConflict({
    required super.invites,
    required this.inviteId,
    required this.code,
    required this.conflictSpaceName,
  });

  @override
  List<Object?> get props => [invites, inviteId, code, conflictSpaceName];
}

/// Emitted after successfully sending an invite to someone.
class InviteSent extends InviteState {
  final String message;
  final String? displayName;
  const InviteSent({required this.message, this.displayName});
  @override
  List<Object?> get props => [message, displayName];
}
