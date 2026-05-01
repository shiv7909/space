# Habitz / Space Workspace Instructions

## Project Snapshot
- This is a Flutter app built around BLoC/Cubit state management and a feature-first layout.
- The repository name is `habitz`, while the app name in code and docs is often `space`.
- Treat the planning docs under [.planning/codebase](../.planning/codebase) and the main guides in the repo root as the source of truth.

## Working Principles
- Prefer small, focused changes that match the existing feature structure.
- Link to existing guides instead of restating architecture or setup details.
- Preserve the current BLoC/Cubit approach unless the user explicitly asks for a larger refactor.
- Keep UI changes aligned with the existing premium, emotion-driven design language.

## Common Commands
- Fetch dependencies: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Run locally: `flutter run`
- Profile: `flutter run --profile`
- Android release build: `flutter build apk --release --split-per-abi`
- Android app bundle: `flutter build appbundle --release`

## Architecture
- Presentation code lives under [lib/Features](../lib/Features) and is organized by feature.
- Shared app concerns live under [lib/core](../lib/core).
- State management uses Cubits and BLoC patterns; prefer `Cubit` for straightforward state transitions.
- Dependency injection is handled with `get_it` and provider-based wiring in the app bootstrap.
- Routing is centralized in [lib/core/routes/app_router.dart](../lib/core/routes/app_router.dart).

## Conventions
- Use `snake_case` for file names, `UpperCamelCase` for classes, and `lowerCamelCase` for variables and methods.
- Keep widgets small and extract reusable pieces into feature-local subwidgets when needed.
- Use `Theme.of(context)` and existing theme tokens instead of hardcoded colors or ad hoc styling.
- Favor `flutter_animate` for motion and micro-interactions when animation is needed.
- Keep async work inside `try-catch` blocks and prefer explicit error handling over silent failures.

## Testing
- Test business logic in services and cubits first.
- Use `flutter_test` for widget tests and `bloc_test` patterns for state transitions.
- Add tests for regressions in synchronization, navigation, and other multi-step flows when you touch them.

## Known Risks
- Secrets are currently hardcoded in [lib/core/config/supabase_config.dart](../lib/core/config/supabase_config.dart); do not spread more credentials through the codebase.
- Large service classes and RPC-heavy flows make refactors risky; keep changes narrow and verify side effects.
- Logging still relies heavily on `print()`, so be careful not to make log noise worse.
- Multi-user dashboard flows and brand challenge flows are fragile; add tests or manual verification when changing them.

## Start Here
- [BLOC_ARCHITECTURE_GUIDE.md](../BLOC_ARCHITECTURE_GUIDE.md)
- [BLOC_MIGRATION_COMPLETE.md](../BLOC_MIGRATION_COMPLETE.md)
- [PROJECT_SUMMARY.md](../PROJECT_SUMMARY.md)
- [.planning/codebase/ARCHITECTURE.md](../.planning/codebase/ARCHITECTURE.md)
- [.planning/codebase/CONVENTIONS.md](../.planning/codebase/CONVENTIONS.md)
- [.planning/codebase/TESTING.md](../.planning/codebase/TESTING.md)
- [.planning/codebase/CONCERNS.md](../.planning/codebase/CONCERNS.md)
- [.planning/codebase/STACK.md](../.planning/codebase/STACK.md)
- [.planning/codebase/INTEGRATIONS.md](../.planning/codebase/INTEGRATIONS.md)
- [AUTH_SETUP_GUIDE.md](../AUTH_SETUP_GUIDE.md)
- [FIREBASE_FCM_SETUP.md](../FIREBASE_FCM_SETUP.md)
- [IMAGE_LOADING_FIXES.md](../IMAGE_LOADING_FIXES.md)
