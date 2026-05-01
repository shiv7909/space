abstract class DeleteAccountState {}

class DeleteAccountInitial extends DeleteAccountState {}

class DeleteAccountLoading extends DeleteAccountState {}

class DeleteAccountSuccess extends DeleteAccountState {}

class DeleteAccountError extends DeleteAccountState {
  final String message;
  DeleteAccountError(this.message);
}

