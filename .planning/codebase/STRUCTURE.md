# Directory Structure

**Analysis Date:** 2026-04-11

## Overview
The 'habitz' project (internal name 'space') is organized by **Feature**, with centralized folders for cross-cutting concerns like shared services, core logic, and UI widgets.

## Root Directory
- `.agent/`: GSD workflow skills, agents, and templates.
- `.planning/`: GSD project metadata, requirements, roadmap, and codebase map.
- `android/`: Android-specific platform code and configurations.
- `ios/`: iOS-specific platform code and configurations.
- `assets/`: Static resources (Images, SVGs, Lottie Animations).
- `lib/`: Main Flutter application code.
- `test/`: Unit and widget tests.
- `supabase/`: Local Supabase configurations (if any).

## `lib/` Structure
- `Features/`: **Primary Feature Modules**
  - Each subfolder (e.g., `auth`, `habits`, `spaces`) contains:
    - `cubit/`: Feature-specific state management.
    - `screens/`: Primary page widgets.
    - `widgets/`: Local UI components.
- `services/`: **Global Data Services**
  - Logic for Supabase RPCs, Firebase Notifications, and local storage.
- `core/`: **Global Infrastructure**
  - `config/`: Integration keys and configurations.
  - `theme/`: Design tokens, colors, and global styles.
  - `routes/`: App navigation router.
  - `utils/`: Common utilities (date formatting, validators).
  - `models/`: Shared data models (if not feature-specific).
- `widgets/`: **Global Shared Widgets**
  - Reusable UI elements like buttons, loaders, and banners.
- `models/`: **Domain Data Models**
  - Data classes and serializable objects.

## Key Files
- `lib/main.dart`: App entry point and dependency injection.
- `pubspec.yaml`: Project metadata, dependencies, and asset definitions.
- `analysis_options.yaml`: Dart linter configuration.

---

*Structure mapping: 2026-04-11*
*Update when moving major folders or restructuring the feature layout*
