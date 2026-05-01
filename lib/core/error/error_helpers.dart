import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts any caught exception into a user-friendly message.
///
/// Usage in cubits:
///   } catch (e) {
///     emit(SomeError(userMessage(e)));
///   }
///
/// This prevents raw `e.toString()` from reaching the UI.
String userMessage(Object error) {
  // ── Network / connectivity ──────────────────────────────────────
  if (error is SocketException) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (error is HttpException) {
    return 'Could not reach the server. Please try again shortly.';
  }

  // ── Supabase-specific ───────────────────────────────────────────
  if (error is PostgrestException) {
    // Rate-limit / timeout / server errors
    final code = error.code;
    if (code == '429' || code == 'PGRST301') {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (code == '408' || code == 'PGRST000') {
      return 'The request timed out. Please try again.';
    }
    if (code == '23505') {
      return 'This item already exists. Try a different name.';
    }
    if (code != null && code.startsWith('P')) {
      // Postgres internal error — don't expose details
      return 'Something went wrong on our end. Please try again.';
    }
    // RPC returned a user-facing message (like our custom error codes)
    final msg = error.message;
    if (msg.isNotEmpty && !msg.contains('function') && msg.length < 200) {
      return msg; // It's likely a custom, user-friendly RPC message
    }
    return 'Something went wrong. Please try again.';
  }

  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('cancel')) {
      return 'Sign-in was cancelled.';
    }
    if (msg.contains('token') || msg.contains('expired')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (msg.contains('email')) {
      return 'There was a problem with your account. Please try again.';
    }
    return 'Authentication failed. Please try again.';
  }

  // ── Generic Exception with message ──────────────────────────────
  if (error is Exception) {
    final msg = error.toString();
    // Strip "Exception: " prefix that Dart adds
    final clean = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
    // Only return if it looks like a human-readable message
    if (clean.length < 200 &&
        !clean.contains('Exception') &&
        !clean.contains('Error')) {
      return clean;
    }
    return 'Something went wrong. Please try again.';
  }

  return 'An unexpected error occurred. Please try again.';
}
