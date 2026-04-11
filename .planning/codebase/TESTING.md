# Testing Strategy

**Analysis Date:** 2026-04-11

## Current State
- **Coverage:** Very low. Only a boilerplate `widget_test.dart` is present.
- **Framework:** `flutter_test`.

## Recommended Patterns

### 1. Unit Testing (Services & Models)
- Focus on testing business logic in `services/`.
- Use `mocktail` or `mockito` to mock `SupabaseClient`.

### 2. Cubit Testing
- Use `bloc_test` (from `flutter_bloc`) to verify state transitions in response to events.
- Test both success and error states.

### 3. Widget Testing
- Test reusable UI components in isolation (e.g., custom buttons, banners).
- Verify that widgets correctly dispatch events to Cubits.

## Running Tests
```bash
flutter test
```

## Future Goals
- Integration tests for core user paths (Login -> Home -> Create Space).
- Golden tests for premium UI components to prevent visual regression.

---

*Testing mapping: 2026-04-11*
*Update as test coverage increases*
