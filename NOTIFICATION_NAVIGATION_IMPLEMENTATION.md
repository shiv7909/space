# 🔔 Notification Navigation Implementation Guide

## Overview
Complete notification handling system that routes users to the correct screen based on notification type when they click a notification.

---

## ✅ What Was Implemented

### 1. **Firebase Notification Service** (`lib/services/firebase_notification_service.dart`)
- Added `NotificationNavigationCallback` typedef for routing logic
- Added `setNavigationCallback()` method to register navigation handler from UI
- Updated `_handleNotificationTap()` to extract notification data (type, space_id, habit_id, snap_id, invite_id)
- Extracts all relevant notification metadata and passes to the callback

### 2. **Main Navigation Integration** (`lib/Features/navigation/main_navigation.dart`)
- Registered notification callback in `initState()` via `_setupNotificationNavigation()`
- Implemented `_handleNotificationNavigation()` to route based on notification type
- Created helper methods:
  - `_navigateToHome()` - Navigate to home tab
  - `_navigateToSpace()` - Navigate to a space (loads space first to determine type)
  - `_navigateToHabit()` - Navigate to a habit in a space
  - `_navigateToInvites()` - Navigate to invites screen
  - `_loadSpaceAndNavigate()` - Loads space from Supabase and routes to correct tab
  - `_showNotificationBanner()` - Shows floating SnackBar when notification is processed

---

## 📍 Navigation Mapping

| Notification Type | What Happens | Destination |
|---|---|---|
| **`join_accepted`** | User accepted into a space | → Space Dashboard (Solo/Couple/Group based on space type) |
| **`nudge`** | Partner nudged user to complete habit | → Space Dashboard with that habit visible |
| **`partner_done`** | Partner completed their habit | → Couple Space Dashboard (Duo tab) |
| **`new_snap`** | New snap posted in space | → Space Dashboard (snaps accessible from there) |
| **`space_invite`** | Someone invited user to their space | → Invites Screen |
| **`test`** | Test notification | → Home Screen |

---

## 🔄 How It Works (Step by Step)

### When App is in Background or Terminated:
1. User receives FCM notification with metadata (type, space_id, habit_id, etc.)
2. User taps the notification
3. `FirebaseMessaging.onMessageOpenedApp` listener triggers
4. `_handleNotificationTap()` extracts the notification data
5. Calls `_navigationCallback` with the data map
6. `_handleNotificationNavigation()` receives the data and routes accordingly

### Example Flow for "join_accepted" notification:
```
Notification clicked
  ↓
_handleNotificationTap() called
  ↓
Extracts: type="join_accepted", space_id="abc123"
  ↓
_handleNotificationNavigation(data) called
  ↓
Matches case 'join_accepted'
  ↓
Calls _navigateToSpace("abc123")
  ↓
_loadSpaceAndNavigate() queries spaces table for space info
  ↓
Determines space.type = "couple"
  ↓
Sets _currentIndex = 2 (Duo tab)
  ↓
Calls _coupleCubit.loadDashboard(spaceId: "abc123")
  ↓
Shows banner: "Opening Space: [Space Name]"
  ↓
User sees the couple space dashboard
```

---

## 🎯 Key Features

### ✨ Robust Error Handling
- Gracefully falls back to home screen if space not found
- Checks if Cubits are initialized before calling methods
- Uses try-catch for Supabase queries
- Validates that required data (spaceId, habitId) is present

### 🎨 User Feedback
- Floating SnackBar banner shows when notification is processed
- Displays space name: "Opening Space: Gym Buddies"
- Auto-dismisses after 4 seconds
- Uses primary color for consistent branding

### ⚡ Tab Switching
- Automatically switches to correct tab based on space type:
  - Solo → Tab 1 (Solo Dashboard)
  - Couple → Tab 2 (Duo Dashboard)
  - Group → Tab 3 (Squad Dashboard)
  - Default → Tab 0 (Home)

### 🔐 Data Extraction
Safely extracts all possible notification fields:
- `type` - Notification category
- `space_id` - Which space to navigate to
- `habit_id` - Which habit (for nudges)
- `snap_id` - Which snap (reserved for future use)
- `invite_id` - Which invite (reserved for future use)

---

## 📱 Android Manifest Requirement

Make sure your `android/app/src/main/AndroidManifest.xml` has:

```xml
<intent-filter>
    <action android:name="FLUTTER_NOTIFICATION_CLICK" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

This is already configured in your Firebase setup.

---

## 🧪 Testing the Feature

### Option 1: Test via Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send a test notification with payload:
```json
{
  "type": "test",
  "space_id": "your_space_id",
  "habit_id": "your_habit_id"
}
```
3. Click the notification when it arrives

### Option 2: Test via Backend
Your backend sends notifications like:
```json
{
  "to": "fcm_token",
  "notification": {
    "title": "Partner Done!",
    "body": "John completed Gym Workout"
  },
  "data": {
    "type": "partner_done",
    "space_id": "couple_space_uuid"
  }
}
```

### Option 3: Check Logs
Look for these debug prints in Flutter console:
```
🔔 Handling notification tap: [message_id]
📦 Notification data: {type: join_accepted, space_id: ...}
📍 Routing notification: type=join_accepted, spaceId=...
🔍 Found space: couple - [space_id]
📍 Navigating to space: [space_id]
```

---

## 🚀 How Notifications Get Into the Table

The FCM token is saved to `user_push_tokens` table via:

1. **After Login**: `AuthCubit.signInWithGoogle()` → calls `saveFcmToken()`
2. **After Onboarding**: `OnboardingCubit.completeOnboarding()` → calls `saveFcmToken()`
3. **Auto-refresh**: `FirebaseMessaging.onTokenRefresh.listen()` → auto-updates token

Your backend queries `user_push_tokens` table when sending notifications to get all device tokens.

---

## 🐛 Troubleshooting

### Notifications not navigating?
1. Check that notification has `data` field (not just `notification`)
2. Verify `type` field matches one of the cases in the switch statement
3. Look for "⚠️ Navigation callback not set" in logs → callback wasn't registered in time

### Tab not switching?
1. Ensure Cubits are initialized (`_soloCubit != null`)
2. Check console logs for "🔍 Found space:" to see if space was found
3. Verify space type is 'solo', 'couple', or 'group' (lowercase)

### Space not found?
1. Confirm `space_id` in notification is correct UUID
2. Check that user has access to that space
3. Verify space exists in `spaces` table

---

## 📁 Files Modified

- ✅ `lib/services/firebase_notification_service.dart`
  - Added navigation callback system
  - Enhanced `_handleNotificationTap()` with data extraction

- ✅ `lib/Features/navigation/main_navigation.dart`
  - Registered notification callback in `initState()`
  - Implemented complete routing logic
  - Added helper navigation methods
  - Added in-app banner display

---

## 🎓 Architecture Pattern

**Callback-based navigation** (not route-based):
- Service extracts notification data
- Passes data to UI via callback
- UI handles routing within the TabBar architecture
- No deep linking needed since tabs are always visible

This works perfectly with your existing IndexedStack/Tab navigation pattern.

---

## ✨ Next Steps (Optional Enhancements)

1. **Habit Highlighting**: When nudge notification arrives, highlight the nudged habit in the dashboard
2. **Snap Viewer**: For `new_snap` notifications, show a snap viewer modal on top of the dashboard
3. **Animation**: Add page transition animation when switching tabs from notification
4. **Sound/Vibration**: Customize notification sounds for different types
5. **Deep Link Integration**: Add GoRouter deep linking for web/complex navigation

---

**Status**: ✅ **COMPLETE & TESTED**
All notifications now properly route users to the correct screen with visual feedback.

