# Integrations

**Analysis Date:** 2026-04-11

## Backend as a Service

### Supabase
- **Role:** Primary backend service for authentication, database, and storage.
- **Integration Point:** `lib/core/config/supabase_config.dart`
- **Key Services:**
  - `auth_service.dart`: Handles user registration and login.
  - `space_service.dart`: Manages "Spaces" data.
  - `snap_service.dart`: Manages "Snaps" (activity logs/updates).
  - `brand_challenge_service.dart`: Manages brand-related activities and challenges via RPC/Database.

## Authentication Providers

### Google Sign-In
- **Role:** Native OAuth provider for user onboarding.
- **Integration Point:** `googleWebClientId` in `SupabaseConfig`.

## Cloud Messaging & Notifications

### Firebase Cloud Messaging (FCM)
- **Role:** Push notifications for user engagement.
- **Integration Point:** `lib/services/firebase_notification_service.dart`
- **Setup:** `firebase_core` initialized in `main.dart`.

## External Libraries & APIs

### Flutter Animate
- **Role:** UI micro-interactions and transitions.
- **Scope:** Used across various feature widgets for a premium feel.

### Google Fonts
- **Role:** Typography management.
- **Service:** Dynamic font loading for curated themes.

## Local Services

### Hive / Shared Preferences
- **Role:** Local persistence of session data and lightweight caching.
- **Integration:** Initialized in `main.dart`.

---

*Integration mapping: 2026-04-11*
*Update when adding new external services*
