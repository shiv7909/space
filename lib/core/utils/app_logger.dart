import 'package:flutter/foundation.dart';

/// Centralized logger that only outputs in debug mode.
/// Replaces all raw print() calls across the app.
///
/// Usage:
///   AppLogger.info('SpaceService', 'Creating space...');
///   AppLogger.error('SpaceService', 'Failed to create space', error: e);
///   AppLogger.warning('AuthCubit', 'Token expired, retrying...');
class AppLogger {
  AppLogger._();

  /// General info — only visible in debug builds.
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔵 [$tag] $message');
    }
  }

  /// Success confirmation — only visible in debug builds.
  static void success(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟢 [$tag] $message');
    }
  }

  /// Warning — something recoverable happened.
  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟡 [$tag] $message');
    }
  }

  /// Error — something failed.
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (kDebugMode) {
      debugPrint('🔴 [$tag] $message');
      if (error != null) debugPrint('    Error: $error');
      if (stack != null) debugPrint('    $stack');
    }
    // TODO: Send to Crashlytics / Sentry in production
  }

  /// Print a potentially long value in chunks (prevents console truncation).
  static void verbose(String tag, String label, dynamic value) {
    if (!kDebugMode) return;
    final str = value.toString();
    debugPrint('📋 [$tag] $label (${str.length} chars):');
    for (var i = 0; i < str.length; i += 800) {
      debugPrint(str.substring(i, i + 800 > str.length ? str.length : i + 800));
    }
  }
}
