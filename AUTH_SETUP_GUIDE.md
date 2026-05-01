# Habitz - Authentication Setup Guide

This guide will help you set up Google Sign-In authentication using Supabase in your Flutter app with BLoC architecture.

## 📋 Prerequisites

- Flutter SDK installed
- A Supabase account (sign up at https://supabase.com)
- Android Studio / Xcode for mobile development

## 🚀 Setup Instructions

### 1. Create a Supabase Project

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in your project details and create the project
4. Wait for the project to be fully initialized

### 2. Get Your Supabase Credentials

1. Go to your project settings: `Settings` → `API`
2. Copy the following:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### 3. Configure Supabase in Your App

Open `lib/core/config/supabase_config.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co'; // Your URL
static const String supabaseAnonKey = 'eyJxxx...'; // Your anon key
```

### 4. Enable Google Authentication in Supabase

1. In your Supabase dashboard, go to `Authentication` → `Providers`
2. Find **Google** in the list
3. Toggle it to **Enabled**
4. You'll need to set up Google OAuth credentials:

#### Setting up Google OAuth:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Go to `APIs & Services` → `Credentials`
4. Click `Create Credentials` → `OAuth client ID`
5. Configure the OAuth consent screen if you haven't already
6. Select `Web application` as the application type
7. Add authorized redirect URIs:
   ```
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```
   Replace `YOUR_PROJECT_REF` with your actual Supabase project reference

8. Copy the **Client ID** and **Client Secret**
9. Go back to Supabase and paste them in the Google provider settings
10. Save the configuration

### 5. Configure Deep Linking

#### Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following inside the `<activity>` tag that contains the `.MainActivity`:

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

#### iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Add the following before the final `</dict>` tag:

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

### 6. Update Google OAuth for Mobile

Go back to Google Cloud Console and add mobile OAuth credentials:

#### For Android:
1. Create a new OAuth client ID
2. Select `Android` as the application type
3. Get your SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Enter your package name: `com.example.habitz` (or your actual package name)
5. Enter the SHA-1 fingerprint

#### For iOS:
1. Create a new OAuth client ID
2. Select `iOS` as the application type
3. Enter your bundle ID (found in Xcode or `ios/Runner.xcodeproj/project.pbxproj`)

### 7. Install Dependencies

Run the following command to install all dependencies:

```bash
flutter pub get
```

### 8. Run the App

```bash
flutter run
```

## 🏗️ Project Structure

The project follows **Clean Architecture** with **BLoC** pattern:

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart          # Supabase configuration
│   ├── di/
│   │   └── injection_container.dart      # Dependency injection (GetIt)
│   ├── error/
│   │   ├── exceptions.dart               # Exception classes
│   │   └── failures.dart                 # Failure classes
│   ├── routes/
│   │   └── app_router.dart               # App navigation
│   ├── theme/
│   │   └── app_theme.dart                # App theming
│   └── usecases/
│       └── usecase.dart                  # Base UseCase class
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart  # Supabase API calls
│   │   │   ├── models/
│   │   │   │   └── user_model.dart               # User data model
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart     # Repository implementation
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart                     # User entity
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart          # Repository interface
│   │   │   └── usecases/
│   │   │       ├── get_current_user.dart         # Use case: Get user
│   │   │       ├── sign_in_with_google.dart      # Use case: Sign in
│   │   │       └── sign_out.dart                 # Use case: Sign out
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart                # Authentication BLoC
│   │       │   ├── auth_event.dart               # BLoC events
│   │       │   └── auth_state.dart               # BLoC states
│   │       ├── pages/
│   │       │   ├── login_page.dart               # Login screen
│   │       │   └── splash_page.dart              # Splash screen
│   │       └── widgets/
│   │           └── google_sign_in_button.dart    # Custom button
│   │
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart                # Home screen
│
└── main.dart                                     # App entry point
```

## 🧪 Testing the Authentication Flow

1. Launch the app - you'll see the splash screen
2. After auth check, you'll be redirected to the login page
3. Tap "Continue with Google"
4. Sign in with your Google account
5. Grant permissions when prompted
6. You'll be redirected back to the app and see the home page with your profile info

## 🔧 Troubleshooting

### "No route defined" error
- Make sure all page imports in `app_router.dart` are correct

### Google Sign-In not working
- Verify your Google OAuth credentials in Supabase
- Check that deep linking is configured correctly
- Ensure the redirect URI matches in both Google Console and your app

### Supabase connection issues
- Verify your Supabase URL and anon key are correct
- Check your internet connection
- Ensure your Supabase project is active

## 📚 Key Dependencies

- **flutter_bloc**: State management
- **supabase_flutter**: Backend and authentication
- **get_it**: Dependency injection
- **dartz**: Functional programming (Either type)
- **equatable**: Value equality
- **google_fonts**: Typography

## 🎯 Next Steps

Now that authentication is working, you can:

1. Add more features (habits tracking, statistics, etc.)
2. Implement user profile management
3. Add local caching with Hive
4. Create habit CRUD operations
5. Add push notifications
6. Implement analytics

## 📝 Notes

- The current implementation uses OAuth redirect flow
- User sessions are managed automatically by Supabase
- The app listens to auth state changes in real-time
- All authentication logic follows Clean Architecture principles
- BLoC pattern ensures clear separation of concerns

## 🤝 Support

If you encounter any issues:
1. Check the error messages in the console
2. Verify all configuration steps
3. Check Supabase dashboard for authentication logs
4. Review the Google Cloud Console for OAuth issues

---

**Happy Coding! 🚀**
