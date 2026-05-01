# Habitz App - Quick Start Guide

## 🎯 What's Been Created

A complete **Flutter app with BLoC architecture** for Google Sign-In authentication using Supabase as the backend.

## 📁 Project Structure

```
lib/
├── main.dart                              # App entry point
├── core/
│   ├── config/
│   │   └── supabase_config.dart          # ⚙️ CONFIGURE THIS FIRST
│   ├── di/
│   │   └── injection_container.dart      # Dependency injection
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── routes/
│   │   └── app_router.dart               # Navigation
│   ├── theme/
│   │   └── app_theme.dart                # App theme
│   └── usecases/
│       └── usecase.dart
│
└── features/
    ├── auth/                              # Authentication feature
    │   ├── data/                          # Data layer
    │   │   ├── datasources/
    │   │   │   └── auth_remote_data_source.dart
    │   │   ├── models/
    │   │   │   └── user_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/                        # Business logic layer
    │   │   ├── entities/
    │   │   │   └── user.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart
    │   │   └── usecases/
    │   │       ├── get_current_user.dart
    │   │       ├── sign_in_with_google.dart
    │   │       └── sign_out.dart
    │   └── presentation/                  # UI layer
    │       ├── bloc/
    │       │   ├── auth_bloc.dart
    │       │   ├── auth_event.dart
    │       │   └── auth_state.dart
    │       ├── pages/
    │       │   ├── login_page.dart
    │       │   └── splash_page.dart
    │       └── widgets/
    │           └── google_sign_in_button.dart
    │
    └── home/                              # Home feature
        └── presentation/
            └── pages/
                └── home_page.dart
```

## 🚀 Setup Steps (Required Before Running)

### Step 1: Install Dependencies

```bash
flutter pub get
```

### Step 2: Configure Supabase

1. **Create a Supabase project** at https://supabase.com
2. **Get your credentials** from `Settings → API`:
   - Project URL
   - anon/public key
3. **Update** `lib/core/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### Step 3: Enable Google Auth in Supabase

1. Go to `Authentication → Providers` in Supabase dashboard
2. Enable **Google**
3. Set up Google OAuth:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create OAuth credentials
   - Add redirect URI: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
   - Copy Client ID and Secret to Supabase

### Step 4: Configure Deep Linking

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add inside the `<activity>` with `.MainActivity`:

```xml
<intent-filter android:label="habitz_deep_link">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.habitz"
        android:host="login-callback" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)

Add before `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.habitz</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.habitz</string>
        </array>
    </dict>
</array>
```

### Step 5: Run the App

```bash
flutter run
```

## 🏗️ Architecture Overview

### BLoC Pattern (Business Logic Component)

```
UI (Pages/Widgets)
    ↓ dispatch events
  BLoC
    ↓ calls
Use Cases
    ↓ uses
Repository (Interface)
    ↓ implemented by
Repository Implementation
    ↓ uses
Data Source
    ↓ calls
Supabase API
```

### Data Flow

1. **User Action** → UI dispatches an event to BLoC
2. **BLoC** → Receives event, calls appropriate use case
3. **Use Case** → Executes business logic, calls repository
4. **Repository** → Delegates to data source
5. **Data Source** → Makes API call to Supabase
6. **Response** → Flows back through layers
7. **BLoC** → Emits new state
8. **UI** → Updates based on new state

## 📱 Features Implemented

### ✅ Authentication
- Google Sign-In using Supabase OAuth
- Auto sign-in (persistent sessions)
- Sign out functionality
- Auth state management with BLoC

### ✅ UI Pages
- **Splash Screen** - Initial loading and auth check
- **Login Page** - Google Sign-In button
- **Home Page** - Displays user info after login

### ✅ Architecture
- Clean Architecture (Data, Domain, Presentation layers)
- BLoC for state management
- Dependency Injection with GetIt
- Error handling with Either (dartz)
- Repository pattern

## 🧩 Key Components

### BLoC Events
- `AuthCheckRequested` - Check current auth status
- `SignInWithGoogleRequested` - Initiate Google sign-in
- `SignOutRequested` - Sign out user
- `AuthStateChanged` - Listen to auth changes

### BLoC States
- `AuthInitial` - Initial state
- `AuthLoading` - Processing auth action
- `Authenticated` - User is signed in
- `Unauthenticated` - User is signed out
- `AuthError` - Error occurred

### Use Cases
- `SignInWithGoogle` - Handle Google sign-in
- `SignOut` - Handle sign-out
- `GetCurrentUser` - Get current user info

## 🔄 Authentication Flow

1. App starts → `SplashPage`
2. `AuthBloc` dispatches `AuthCheckRequested`
3. Checks if user is already signed in
4. If **authenticated** → Navigate to `HomePage`
5. If **not authenticated** → Navigate to `LoginPage`
6. User taps "Continue with Google"
7. Opens Google sign-in flow
8. After success → Navigate to `HomePage`
9. User can sign out from `HomePage`

## 🛠️ Customization

### Change App Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF6C63FF);
static const Color secondaryColor = Color(0xFF4CAF50);
```

### Change Deep Link Scheme
1. Update `lib/core/config/supabase_config.dart`:
   ```dart
   static const String redirectUrl = 'your-scheme://login-callback/';
   ```
2. Update AndroidManifest.xml and Info.plist accordingly
3. Update in `auth_remote_data_source.dart`

### Add More Pages
1. Create page in `lib/features/your_feature/presentation/pages/`
2. Add route in `lib/core/routes/app_router.dart`
3. Navigate using: `Navigator.pushNamed(context, AppRouter.yourRoute)`

## 📚 Dependencies Used

```yaml
# State Management
flutter_bloc: ^8.1.6
equatable: ^2.0.8

# Backend & Auth
supabase_flutter: ^2.8.0

# Dependency Injection
get_it: ^8.0.2

# Functional Programming
dartz: ^0.10.1

# UI
google_fonts: ^6.2.1
```

## 🐛 Common Issues

### Issue: "No route defined"
**Solution**: Check imports in `app_router.dart`

### Issue: Google Sign-In doesn't work
**Solution**: 
- Verify Supabase Google provider is enabled
- Check OAuth credentials in Google Console
- Ensure deep linking is configured

### Issue: "Invalid Supabase URL"
**Solution**: Update `supabase_config.dart` with correct credentials

## 🎓 Learning Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Docs](https://docs.flutter.dev/)

## 🚀 Next Steps

Now you can add more features:

1. **Habits Feature**
   - Create habit CRUD operations
   - Add habit tracking
   - Show statistics

2. **Profile Feature**
   - Edit user profile
   - Upload avatar
   - Manage settings

3. **Persistence**
   - Add Hive for local caching
   - Offline support
   - Sync when online

4. **Analytics**
   - Track user behavior
   - Show progress charts
   - Generate reports

## 💡 Tips

- Always follow the layer structure (Data → Domain → Presentation)
- Create use cases for business logic
- Use BLoC for state management
- Handle errors properly with Either type
- Write tests for critical functionality

---

**You're all set! Happy coding! 🎉**

For detailed setup instructions, see `AUTH_SETUP_GUIDE.md`
