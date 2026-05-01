# Firebase Cloud Messaging Implementation Guide

## ✅ Implementation Complete

I've successfully implemented Firebase Cloud Messaging (FCM) for your Habitz app with comprehensive features for push notifications.

## What Has Been Set Up

### 1. **Dependencies Added** ✅
- `firebase_core: ^3.8.0` - Firebase initialization
- `firebase_messaging: ^15.1.5` - Cloud messaging service
- `flutter_local_notifications: ^18.0.1` - Local notification display

### 2. **Core Services Created**

#### a) `firebase_notification_service.dart`
A complete singleton service handling:
- FCM initialization with permission requests
- Foreground message handling (displays notification immediately)
- Background message handling (works even when app is closed)
- Notification tap handling
- FCM token management
- Topic subscription/unsubscription
- Auto-save FCM token to Supabase profiles
- Local notification display with Android notification channels

**Key Features:**
```dart
// Get FCM token
final token = await FirebaseNotificationService().getFCMToken();

// Subscribe to topics for targeted messaging
await FirebaseNotificationService().subscribeToTopic('space_invites');

// Delete token on logout
await FirebaseNotificationService().deleteFCMToken();
```

#### b) `notification_utils.dart`
Utility class for managing notifications throughout your app:
- User-specific topic subscription/unsubscription
- Space-specific notifications
- Login/logout handlers
- Token management in Supabase

**Usage Example:**
```dart
// On user login
await NotificationUtils().onLogin(userId);

// Subscribe to a space
await NotificationUtils().subscribeToSpaceNotifications(spaceId);

// On logout
await NotificationUtils().onLogout(userId);
```

#### c) `notification_cubit.dart` (BLoC Pattern)
State management for notifications following your BLoC architecture:
- Initialize notifications for authenticated users
- Manage FCM token state
- Subscribe/unsubscribe from space notifications
- Handle logout cleanup

**Usage:**
```dart
// In your widgets
BlocProvider(
  create: (context) => NotificationCubit()
    ..initializeNotifications(userId),
),

// Use in widgets
context.read<NotificationCubit>().subscribeToSpace(spaceId);
```

### 3. **Android Configuration** ✅
- **build.gradle.kts**: Added Google Services plugin for Firebase
- **AndroidManifest.xml**: Added notification permissions:
  - `POST_NOTIFICATIONS` - Android 13+ permission
  - `INTERNET` - Network access
  - `ACCESS_NETWORK_STATE` - Network status checking

### 4. **Main App Integration** ✅
Updated `main.dart` to:
- Initialize Firebase before Supabase
- Initialize FCM notification service
- Ready for BLoC integration

## Quick Start

### Step 1: Add google-services.json (CRITICAL)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create/select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click "Generate New Private Key" to download `google-services.json`
5. **Place it here**: `android/app/google-services.json`

### Step 2: Update Supabase Schema
Add FCM token column to your profiles table:
```sql
ALTER TABLE profiles
ADD COLUMN fcm_token TEXT;

CREATE INDEX idx_profiles_fcm_token ON profiles(fcm_token);
```

### Step 3: Run Dependencies
```bash
flutter pub get
```

### Step 4: Build and Test
```bash
flutter clean
flutter run
```

## Integration with Your Auth Flow

### Add to AuthCubit
When users log in successfully, initialize notifications:

```dart
// In your auth_cubit.dart or auth_service.dart, after successful login:
import 'services/notification_utils.dart';

// On successful login
await NotificationUtils().onLogin(userId);

// On logout
await NotificationUtils().onLogout(userId);
```

### Optional: Add NotificationCubit to main.dart
For full BLoC integration:

```dart
// In main.dart imports
import 'Features/notifications/cubit/notification_cubit.dart';

// In MultiBlocProvider
BlocProvider(
  create: (context) => NotificationCubit(),
),

// In AuthCubit listener (when authenticated)
if (state is AuthAuthenticated) {
  context.read<NotificationCubit>().initializeNotifications(state.user.id);
}
```

## Sending Notifications

### From Firebase Console (Testing)
1. Firebase Console → Cloud Messaging → Send first message
2. Enter title, body, and target audience
3. Click "Review" → "Publish"

### From Your Backend (Production)

#### Using Supabase Edge Functions (Recommended)
Create a new Edge Function:
```bash
supabase functions new send-notification
```

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { user_id, title, body, data } = await req.json()
  
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  )
  
  // Get user's FCM token
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('fcm_token')
    .eq('id', user_id)
    .single()
  
  if (!profile?.fcm_token) {
    return new Response(
      JSON.stringify({ error: 'No FCM token found' }),
      { status: 404 }
    )
  }
  
  // Send via FCM
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`
    },
    body: JSON.stringify({
      to: profile.fcm_token,
      notification: {
        title,
        body,
      },
      data: data || {}
    })
  })
  
  return response
})
```

#### Using Direct HTTP Call
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "You have a new invite!",
      "body": "Someone invited you to a space"
    },
    "data": {
      "type": "invite",
      "invite_id": "12345"
    }
  }'
```

## Topic-Based Messaging

### Benefits
- Send to multiple users at once
- No need to manage individual tokens
- Automatic subscription management

### Subscribe to Topics
```dart
// In your space creation/join logic
await NotificationUtils().subscribeToSpaceNotifications(spaceId);

// Or directly
await FirebaseNotificationService()
  .subscribeToTopic('space_$spaceId');
```

### Send to Topic
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -d '{
    "to": "/topics/space_12345",
    "notification": {
      "title": "Activity in your space",
      "body": "New snap added"
    }
  }'
```

## Advanced Features

### 1. Deep Linking on Notification Tap
Update `_handleNotificationTap` in `firebase_notification_service.dart`:
```dart
void _handleNotificationTap(RemoteMessage message) {
  final type = message.data['type'];
  final id = message.data['id'];
  
  if (type == 'invite') {
    // Navigate to invites screen
    navigatorKey.currentState?.pushNamed('/invites');
  } else if (type == 'space') {
    // Navigate to space
    navigatorKey.currentState?.pushNamed('/space/$id');
  }
}
```

### 2. Custom Notification Handling
The service automatically:
- Shows notifications while app is in foreground
- Handles background notifications via handler
- Saves tokens to Supabase
- Manages notification channels

### 3. Token Refresh Handling
Automatic token refresh is handled internally - no action needed!

## File Structure
```
lib/
├── main.dart (UPDATED)
├── services/
│   ├── firebase_notification_service.dart (NEW)
│   ├── notification_utils.dart (NEW)
│   └── ...existing services
└── Features/
    └── notifications/
        └── cubit/
            └── notification_cubit.dart (NEW)

android/
├── build.gradle.kts (UPDATED)
├── app/
│   ├── build.gradle.kts (UPDATED)
│   ├── google-services.json (NEED TO ADD)
│   └── src/main/AndroidManifest.xml (UPDATED)

pubspec.yaml (UPDATED with Firebase deps)
```

## Troubleshooting

### Notifications not showing?
1. **Check google-services.json**: Must be at `android/app/google-services.json`
2. **Check permissions**: User must grant notification permission in Android settings
3. **Check token**: Verify FCM token is saved to Supabase:
   ```sql
   SELECT id, fcm_token FROM profiles WHERE fcm_token IS NOT NULL LIMIT 1;
   ```
4. **Check Firebase Console**: Verify messages are being sent in Cloud Messaging metrics

### Foreground notifications not displaying?
- The notification display system requires the app to be in foreground
- Background handling is automatic via `_firebaseMessagingBackgroundHandler`

### Token not saving to Supabase?
- Ensure user is authenticated when FCM initializes
- Check that profiles table has `fcm_token` column
- Verify Supabase RLS policies allow updates

### "google-services.json not found" error?
- File must be at: `android/app/google-services.json` (not in any subfolder)
- Rebuild with `flutter clean && flutter run`

## Security Notes

1. **Sensitive Data**: Don't send passwords or sensitive info in notifications
2. **Rate Limiting**: Implement rate limiting on notification sending
3. **User Consent**: Always show opt-in for notifications
4. **Data Privacy**: Store minimal data in FCM tokens
5. **Validation**: Validate notification payloads on client side

## Next Steps

1. ✅ Download and add `google-services.json` to `android/app/`
2. ✅ Run `flutter pub get`
3. ✅ Update Supabase: Add `fcm_token` column to profiles
4. ✅ Integrate with AuthCubit (call NotificationUtils on login/logout)
5. ✅ Test notifications via Firebase Console
6. ✅ Set up backend notification sending (Edge Functions or API)
7. ✅ Implement deep linking for notification taps (optional)
8. ✅ Monitor delivery in Firebase Console

## Testing Notifications

### Test in Firebase Console
```
1. Firebase Console → Cloud Messaging → Send test message
2. Select your app
3. Enter title and body
4. Click "Send test message"
5. Select your device
6. Check device for notification
```

### Test with cURL
```bash
# Get your FCM token from Supabase
# Then send:
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -d '{
    "to": "PASTE_YOUR_FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    }
  }'
```

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Package](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [FCM HTTP Protocol](https://firebase.google.com/docs/cloud-messaging/http-server-ref)

---

**Implementation Date**: March 16, 2026
**Status**: Ready for google-services.json and testing

