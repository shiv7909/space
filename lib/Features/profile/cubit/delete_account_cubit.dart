import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'delete_account_state.dart';

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final SupabaseClient _supabase;

  DeleteAccountCubit(this._supabase) : super(DeleteAccountInitial());

  Future<void> deleteAccount() async {
    emit(DeleteAccountLoading());

    try {
      // ── Step 1: Call the backend function ──────────────────────
      final res = await _supabase.rpc('delete_my_account');

      if (res == null) {
        print('❌ delete_my_account returned null');
        emit(DeleteAccountError('No response from server.'));
        return;
      }

      Map<String, dynamic> data;
      try {
        // defensive conversion in case the RPC returns a Map-like object
        data = Map<String, dynamic>.from(res as Map);
      } catch (e) {
        print('❌ Unexpected RPC response for delete_my_account: ${res.runtimeType} -> $res');
        emit(DeleteAccountError('Unexpected server response.'));
        return;
      }

      // If backend indicates failure, print full details and emit the error message
      if (data['success'] != true) {
        final code = data['code'] ?? 'unknown_code';
        final message = data['message'] ?? 'Failed to delete account';
        print('❌ Delete failed: $code — $message');
        emit(DeleteAccountError(message));
        return;
      }

      // ── Step 2: Delete profile photo from storage if exists ────
      final photoKey = data['photo_key'] as String?;
      if (photoKey != null && photoKey.isNotEmpty) {
        try {
          await _supabase.storage.from('profile-photos').remove([photoKey]);
        } catch (e) {
          // Storage deletion failure is non-critical — continue, but log it
          print('⚠️ Failed to remove profile photo from storage: $e');
        }
      }

      // ── Step 3: Sign out locally ───────────────────────────────
      await _supabase.auth.signOut();

      emit(DeleteAccountSuccess());

    } catch (e, st) {
      // Surface the actual exception so the UI can show it and logs contain the stack
      print('❌ deleteAccount exception: $e\n$st');
      emit(DeleteAccountError(e.toString()));
    }
  }
}
