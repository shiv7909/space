# Architecture

**Analysis Date:** 2026-04-11

## Overview
The 'habitz' project (internal name 'space') follows a **Feature-Based Architecture** with clear separation between business logic (Cubits), data access (Services), and UI (Features). It utilizes the BLoC pattern for state management and Supabase as the primary backend.

## Design Patterns
- **BLoC / Cubit**: Used for state management across all features.
- **Repository Pattern**: Services in `lib/services` act as repositories, abstracting Supabase RPC and database calls.
- **Dependency Injection**: Managed via `MultiRepositoryProvider` and `MultiBlocProvider` in `main.dart` (Top-down injection).
- **Centralized Routing**: Managed via `AppRouter` in `lib/core/routes`.

## Layers

### 1. Presentation Layer (`lib/Features`)
- **Structure:** Each feature (e.g., `auth`, `habits`, `spaces`) contains its own UI components and logic.
- **Components:**
  - `screens/`: Top-level page widgets.
  - `widgets/`: Reusable feature-specific UI components.
  - `cubit/`: State management logic (Cubit and State classes).

### 2. Service Layer (`lib/services`)
- **Role:** Handles communication with external APIs (Supabase, Firebase).
- **Responsibilities:** Data fetching, mapping database models to local models, and error handling.
- **Key Services:** `AuthService`, `SpaceService`, `ProfileService`, `BrandChallengeService`.

### 3. Core Layer (`lib/core`)
- **Role:** Shared logic and configurations that span multiple features.
- **Contents:**
  - `config/`: Integration settings (Supabase, Google).
  - `theme/`: Global styling and UI tokens (AppTheme, colors, spacing).
  - `routes/`: Navigation definitions.
  - `utils/`: Common helper functions.

## Data Flow
1. **User Interaction:** User clicks a button in a **Feature Widget**.
2. **Event Dispatch:** The Widget calls a method on the associated **Cubit**.
3. **Data Request:** The Cubit calls a method on a **Service**.
4. **Network Call:** The Service performs an RPC or database operation on **Supabase**.
5. **State Update:** The Service returns data (or an error); the Cubit emits a new **State**.
6. **UI Refresh:** The Feature Widget rebuilds based on the new state.

## Entry Points
- `lib/main.dart`: App initialization (Firebase, Supabase, Services, and global Providers).

---

*Architecture mapping: 2026-04-11*
*Update when introducing major architectural changes (e.g., switching state management or DI)*
