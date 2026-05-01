import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import 'firebase_notification_service.dart';

class AuthService {
  final SupabaseClient supabaseClient;

  AuthService({required this.supabaseClient});

  Future<UserModel> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In...');
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleWebClientId,
      );

      // Ensure any previous session is fully cleared. On some Android/Play Services
      // configurations signOut() leaves state that causes signIn() to return the
      // previous account without showing the chooser. Calling disconnect() forces
      // the account chooser to appear.
      try {
        await googleSignIn.disconnect();
        print('🔵 GoogleSignIn: disconnected previous session');
      } catch (e) {
        // disconnect may throw if not signed in; fall back to signOut
        print('🟡 GoogleSignIn: disconnect threw, falling back to signOut: $e');
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }

      print('🔵 Triggering Google Sign-In prompt...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('🔴 User cancelled sign-in');
        throw Exception('Google sign-in was cancelled');
      }

      print('🟢 Google user obtained: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      print('🔵 ID Token: ${idToken != null ? "✓ Found" : "✗ Not found"}');
      print(
        '🔵 Access Token: ${accessToken != null ? "✓ Found" : "✗ Not found"}',
      );

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      print('🔵 Sending tokens to Supabase...');
      final authResponse = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = authResponse.user;
      if (user == null) {
        print('🔴 No user found after sign-in');
        throw Exception('No user found after sign-in');
      }

      print('🟢 Successfully signed in: ${user.email}');
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      print('🔴 Sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Delete FCM token from Supabase before signing out
      await FirebaseNotificationService().deleteTokenOnLogout();

      await supabaseClient.auth.signOut();
      print('🟢 Successfully signed out');
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.map((state) {
      final user = state.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    });
  }
}
