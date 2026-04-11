# Technology Stack

**Analysis Date:** 2026-04-11

## Languages

**Primary:**
- Dart ^3.7.0-323.0.dev - All application logic, UI components, and services.

**Secondary:**
- Kotlin/Java - Android platform-specific code (found in `android/`).
- Swift/Objective-C - iOS platform-specific code (found in `ios/`).
- JavaScript/Python - Utility scripts for icon and asset generation (found in root).

## Runtime

**Environment:**
- Flutter SDK - Cross-platform framework.
- Dart VM - For development and JIT execution.

**Package Manager:**
- Flutter Pub - Dependency management via `pubspec.yaml`.
- Lockfile: `pubspec.lock` present.

## Frameworks

**Core:**
- Flutter - UI Framework.
- flutter_bloc ^8.1.6 - State management (BLoC pattern).

**Testing:**
- flutter_test - Bundled with Flutter SDK.

**Build/Dev:**
- build_runner ^2.4.13 - Code generation.
- flutter_gen_runner ^5.7.0 - Asset generation.
- flutter_launcher_icons ^0.14.4 - App icon generation.

## Key Dependencies

**Critical:**
- supabase_flutter ^2.8.0 - Backend-as-a-Service integration (Auth, Database).
- get_it ^8.0.2 - Service locator for dependency injection.
- flutter_animate ^4.0.0 - Premium UI animations and effects.
- google_fonts ^6.2.1 - Typography (Inter, Roboto, Nunito, etc.).

**Infrastructure:**
- dio ^5.7.0 - HTTP client for API requests.
- hive ^2.2.3 - Lightweight and fast NoSQL database for local storage.
- firebase_messaging ^15.1.5 - Push notifications.

## Configuration

**Environment:**
- Supabase credentials and Firebase configs (not yet mapped to specific .env files).

**Build:**
- `pubspec.yaml` - Main project configuration.
- `analysis_options.yaml` - Linter rules.

## Platform Requirements

**Development:**
- Flutter SDK, Android Studio/Xcode.

**Production:**
- Android 5.0 (SDK 21) or higher.
- iOS compatibility.

---

*Stack analysis: 2026-04-11*
*Update after major dependency changes*
