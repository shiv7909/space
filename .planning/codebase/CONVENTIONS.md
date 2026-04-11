# Coding Conventions

**Analysis Date:** 2026-04-11

## Overview
The project follows standard Flutter and Dart best practices, with a strong emphasis on the BLoC/Cubit pattern for state management and a feature-first directory organization.

## Language Standards
- **Linter:** `package:flutter_lints/flutter.yaml`.
- **Naming:** 
  - Classes: `UpperCamelCase`.
  - Variables/Methods: `lowerCamelCase`.
  - Files: `snake_case`.

## Architecture Patterns
- **Feature-First:** Group code by functionality (Auth, Habits, Spaces) rather than layer (Widgets, Models, Controllers).
- **Cubits:** Prefer `Cubit` over `Bloc` for simpler state transitions unless complex event transformations are needed.
- **State States:** Always use sealed classes or equatable for state objects to ensure efficient UI rebuilding.

## UI & Styling
- **Theme:** Use `Theme.of(context)` for all colors and text styles. Avoid hardcoding hex values.
- **Widgets:** Keep widgets small and focused. Extract sub-widgets into separate private classes within the same file or into a `widgets/` folder if reusable.
- **Animations:** Leverage `flutter_animate` for consistent micro-interactions.

## Error Handling
- **Async Operations:** Wrap in `try-catch` blocks.
- **Services:** Services should throw custom exceptions or return `Either` (found `dartz` in `pubspec.yaml`).
- **Global Error Boundary:** Managed in `main.dart` via `FlutterError.onError` and `runZonedGuarded`.

## DI & Service Retrieval
- **Providers:** Use `context.read<T>()` or `context.watch<T>()` for Cubs/Blocs.
- **Repositories:** Use `context.read<ServiceType>()` for background service access.

---

*Conventions mapping: 2026-04-11*
*Update as team preferences evolve*
