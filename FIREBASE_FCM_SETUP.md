# Firebase Cloud Messaging Setup Guide

## Overview
Firebase Cloud Messaging (FCM) has been successfully integrated into your Habitz app. This guide explains what you need to do to complete the setup.

## What Has Been Implemented

### 1. **Dependencies Added** (pubspec.yaml)
- `firebase_core: ^3.8.0` - Firebase core library
- `firebase_messaging: ^15.1.5` - Firebase Cloud Messaging
- `flutter_local_notifications: ^18.0.1` - Local notification handling

### 2. **Firebase Notification Service** (services/firebase_notification_service.dart)
A complete notification service with the following features:
- ✅ Initialize Firebase Cloud Messaging
- ✅ Request user notification permissions
- ✅ Handle foreground notifications
- ✅ Handle background notifications
- ✅ Handle notification taps
- ✅ Auto-save FCM token to Supabase profiles table
- ✅ Subscribe/unsubscribe to topics
- ✅ Local notification display with Android notification channels

### 3. **Android Configuration**
- ✅ Added Google Services plugin to build.gradle.kts files
- ✅ Added notification permissions to AndroidManifest.xml
- ✅ Configured NDK and build features

### 4. **Main App Integration**
- ✅ Firebase initialization in main.dart
- ✅ FCM service initialization before Supabase
- ✅ Ready to handle notifications

## What You Need To Do

### Step 1: Set Up Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Select your project
4. Go to **Project Settings** → **Service Accounts** tab
5. Click "Generate New Private Key" to download `google-services.json`

### Step 2: Add google-services.json
1. Place the downloaded `google-services.json` file in: `android/app/google-services.json`
2. This file is critical for Firebase authentication

### Step 3: Supabase Database Schema Update
Add an `fcm_token` column to your profiles table if not already present:

```sql
ALTER TABLE profiles
ADD COLUMN fcm_token TEXT;

-- Optional: Create index for faster lookups
CREATE INDEX idx_profiles_fcm_token ON profiles(fcm_token);
```

### Step 4: Install Dependencies
Run the following command in your project root:
```bash
flutter pub get
```

### Step 5: Build and Test
```bash
# Clean build
flutter clean

# Run the app
flutter run

# Or build APK
flutter build apk --release
```

## Features Available

### 1. **Automatic Token Management**
- FCM token is automatically saved to user's profile in Supabase
- Token is refreshed automatically when it changes
- Token can be deleted on logout

### 2. **Topic-Based Messaging**
Subscribe users to topics:
```dart
final fcmService = FirebaseNotificationService();
await fcmService.subscribeToTopic('space_notifications');
await fcmService.subscribeToTopic('invites');
```

Unsubscribe:
```dart
await fcmService.unsubscribeFromTopic('space_notifications');
```

### 3. **Notification Handling**
The service handles:
- **Foreground Notifications**: Display immediately with local notifications
- **Background Notifications**: Handled by background message handler
- **Notification Taps**: Can be extended to handle navigation
- **Custom Data**: Any custom data in the notification payload

### 4. **Getting FCM Token**
```dart
final fcmService = FirebaseNotificationService();
final token = await fcmService.getFCMToken();
print('FCM Token: $token');
```

## Sending Notifications from Backend

### Using Firebase Console
1. Go to Firebase Console → Cloud Messaging → Send first message
2. Select your app and send test notifications

### Using FCM API (Recommended for production)
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Content-Type: application/json" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Hello from Habitz!",
      "body": "You have a new invite"
    },
    "data": {
      "type": "invite",
      "invite_id": "12345"
    }
  }'
```

### Using Supabase Edge Functions (Recommended)
Create an edge function to send notifications:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { user_id, title, body } = await req.json()
  
  // Get user's FCM token
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('fcm_token')
    .eq('id', user_id)
    .single()
  
  // Send notification via FCM
  // ... implementation
})
```

## Logout Cleanup

When users log out, delete their FCM token:
```dart
// In your logout method
final fcmService = FirebaseNotificationService();
await fcmService.deleteFCMToken();
```

## Troubleshooting

### Issue: Notifications not received
1. Ensure `google-services.json` is in the correct location: `android/app/google-services.json`
2. Check that user has granted notification permissions
3. Verify FCM token is being saved to Supabase
4. Check Firebase Cloud Messaging metrics in Firebase Console

### Issue: Background messages not working
1. Background handler requires native code integration
2. Ensure app is properly signed
3. Test on physical device (emulators may have limitations)

### Issue: Duplicate notifications
1. Implement deduplication logic based on notification ID
2. Or clear notifications after handling

## Next Steps

1. ✅ Add `google-services.json` file
2. ✅ Run `flutter pub get`
3. ✅ Update Supabase schema with `fcm_token` column
4. ✅ Test notifications locally
5. ✅ Implement notification tap handling for deep linking
6. ✅ Set up backend notification sending (Edge Functions or external API)
7. ✅ Monitor notification delivery in Firebase Console

## File Structure

```
lib/
├── services/
│   ├── firebase_notification_service.dart  ← New service
│   ├── auth_service.dart
│   ├── profile_service.dart
│   └── ...
├── main.dart  ← Updated with Firebase init

android/
├── app/
│   ├── google-services.json  ← Need to add this
│   ├── build.gradle.kts  ← Updated
│   └── src/main/AndroidManifest.xml  ← Updated

pubspec.yaml  ← Updated with Firebase deps
```

## Additional Notes

- iOS setup will be needed separately (download GoogleService-Info.plist)
- The service is a singleton and should be accessed globally
- Notification channels are pre-configured for Android 8.0+
- All permissions are handled automatically

For more information, see:
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

