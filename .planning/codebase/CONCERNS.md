# Technical Concerns & Debt

**Analysis Date:** 2026-04-11

## Critical Concerns

### Hardcoded Secrets
- **Location:** `lib/core/config/supabase_config.dart`.
- **Issue:** Supabase URL, Anon Key, and Google Web Client ID are currently hardcoded in a configuration file.
- **Risk:** High. These should be moved to environment variables or a `.env` file that is not committed to version control.

### Low Test Coverage
- **Issue:** Only one boilerplate widget test exists.
- **Risk:** High. As the project grows in complexity (especially with brand challenges and synchronization), the lack of unit and integration tests will lead to regressions.

## Technical Debt

### Large Service Classes
- **Issue:** `SpaceService` is nearly 1000 lines and handles many different concerns (creating spaces, managing members, habits, dashboards, nudges, invites).
- **Impact:** Decreased maintainability and readability.
- **Recommendation:** Refactor into smaller, focused services (e.g., `HabitService`, `InviteService`, `NudgeService`).

### Extensive Reliance on RPCs
- **Issue:** Much of the business logic is handled via Supabase RPCs (e.g., `add_habit_smart`, `complete_solo_habit`).
- **Impact:** The code is heavily coupled to the specific database implementation. Logic transitions are hard to track without access to the SQL/Backend repo.

### Logging & Diagnostics
- **Issue:** Extensive use of `print()` statements for debugging throughout the codebase.
- **Impact:** Messy logs and potential performance overhead in release builds.
- **Recommendation:** Move to a structured logger (e.g., `logger` package) with defined levels (info, debug, error).

## Areas of Fragility
- **Synchronization:** The multi-user "Duo" and "Group" dashboards rely on complex state updates across BLoCs. Without tests, these areas are vulnerable to race conditions.
- **Theming:** The premium "Gen Z" aesthetics rely on complex `flutter_animate` sequences. Ad-hoc changes to UI logic could easily break the "premium" feel.

---

*Concerns mapping: 2026-04-11*
*Review periodically during refactoring phases*
