# Performance Optimization Guide for Habitz App

## 1. Image Caching & Optimization

### Current Implementation ✅
- `CachedNetworkImage` is already being used for avatar images
- Images are compressed before upload (maxWidth: 800, maxHeight: 800, quality: 85)

### Recommended Enhancements:
```dart
// Add image cache configuration in main.dart
imageCache.maximumSize = 100; // Max 100 images in memory
imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB max
```

---

## 2. Lazy Loading for Avatar Grid

### Problem:
Currently loading all avatars at once. For large avatar lists, this impacts startup performance.

### Solution:
Implement lazy loading using `GridView.builder` with pagination:

```dart
// Instead of loading all avatars, load in batches of 12
const int _pageSize = 12;
int _currentPage = 0;

// Load more when user scrolls to bottom
void _loadMoreAvatars() {
  if (!_isLoading) {
    _currentPage++;
    _loadAvatarsPage(_currentPage);
  }
}
```

---

## 3. Network Request Optimization

### Current ✅:
Avatar URL fetching already uses `Future.wait()` for parallel requests - Good!

### Further Optimization:
- Add request caching to avoid refetching the same URLs
- Implement exponential backoff for failed requests
- Add timeout configuration

```dart
// Add to ProfileService
final Map<String, String> _urlCache = {};

Future<String?> getAvatarUrlById(String id) async {
  if (_urlCache.containsKey(id)) {
    return _urlCache[id];
  }
  
  final url = await _fetchUrl(id);
  if (url != null) {
    _urlCache[id] = url; // Cache it
  }
  return url;
}
```

---

## 4. Widget Rebuild Optimization

### Problem:
Multiple `setState()` calls can trigger excessive rebuilds.

### Solution - Use Const Constructors:
✅ Already implemented in your code! The `_PhotoOptionTile`, `_MinimalSocialBtn` are const.

### Additional Optimization:
Extract smaller widgets to prevent parent rebuilds:

```dart
// Extract QR section into separate widget
class _QRSection extends StatelessWidget {
  final String qrData;
  final GlobalKey key;
  
  const _QRSection({required this.qrData, required this.key});
  
  @override
  Widget build(BuildContext context) {
    // QR code rendering
  }
}

// Use in main widget:
if (!_isEditMode) _QRSection(qrData: qrData, key: _qrKey)
```

---

## 5. Memory Management

### Current Issue:
Temporary image files from cropping aren't being cleaned up after upload.

### Solution:
```dart
Future<void> _saveChanges() async {
  // ... existing code ...
  
  if (mounted) {
    // Clean up temporary files
    try {
      if (_pendingPhotoFile != null && await _pendingPhotoFile!.exists()) {
        await _pendingPhotoFile!.delete();
      }
    } catch (e) {
      debugPrint('Failed to clean up temp file: $e');
    }
    
    setState(() {
      _isEditMode = false;
      // ... rest of code
    });
  }
}

@override
void dispose() {
  _nameController.dispose();
  
  // Clean up temp files on dispose
  if (_pendingPhotoFile != null) {
    try {
      _pendingPhotoFile!.deleteSync();
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }
  
  super.dispose();
}
```

---

## 6. Build Configuration Optimizations

### Android (build.gradle.kts):
```kotlin
android {
    // ...
    buildTypes {
        release {
            // Enable shrinking and obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
    
    // Optimize build features
    buildFeatures {
        buildConfig false
        aidl false
        renderScript false
        resValues false
        shaders false
    }
}
```

### Flutter Build Flags:
```bash
# Build for release with size optimization
flutter build apk --release --split-per-abi

# Or for splitting by ABI to reduce per-device size
flutter build apk --release --split-per-abi
```

---

## 7. Supabase Query Optimization

### Problem:
Loading profile data could be optimized at the database level.

### Solution:
```dart
// In ProfileService, add selective column queries
Future<ProfileModel?> getProfile(String userId) async {
  try {
    final response = await supabaseClient
        .from('profiles')
        .select('id, display_name, avatar_id, has_photo, photo_key') // Only needed columns
        .eq('user_id', userId)
        .single();
    
    return ProfileModel.fromJson(response);
  } catch (e) {
    return null;
  }
}
```

---

## 8. SharedPreferences Caching

### Add user data caching:
```dart
// Cache profile locally
Future<void> cacheProfileLocally(ProfileModel profile) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cached_profile_${profile.id}', jsonEncode(profile));
  await prefs.setInt('profile_cache_time', DateTime.now().millisecondsSinceEpoch);
}

// Check if cache is still valid (e.g., 1 hour)
bool isCacheValid() {
  final lastUpdate = prefs.getInt('profile_cache_time') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  return (now - lastUpdate) < Duration(hours: 1).inMilliseconds;
}
```

---

## 9. Dart Performance Best Practices

### ✅ Already Doing Great:
- Using `const` constructors
- Using `equatable` for equality checks
- Using BLoC for state management
- Lazy initialization with `late` keyword

### Additional Tips:
```dart
// Use const where possible
const EdgeInsets.all(16); // Good
EdgeInsets.all(16);       // Recreates every build

// Use addAll instead of multiple add calls
list.addAll([item1, item2, item3]); // Better than 3 separate adds

// Use spreads efficiently
final newList = [...oldList, newItem]; // Good

// Avoid string concatenation in hot loops
final sb = StringBuffer();
sb.write('...');
sb.write('...');
final result = sb.toString(); // Better than multiple string +
```

---

## 10. Analytics & Monitoring

### Add performance monitoring:
```dart
// In main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  // ... initialization ...
  
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };
}
```

---

## Summary of Quick Wins 🚀

| Priority | Action | Impact |
|----------|--------|--------|
| 🔴 HIGH | Implement file cleanup on dispose | Prevents memory leaks |
| 🔴 HIGH | Enable ProGuard/R8 in release build | 30-50% APK size reduction |
| 🟡 MEDIUM | Add image cache limits | Prevents OOM errors |
| 🟡 MEDIUM | Implement lazy loading for avatars | Faster initial load |
| 🟡 MEDIUM | Add local profile caching | Offline support + speed |
| 🟢 LOW | Extract QR section widget | Minor rebuild optimization |

---

## Testing Performance

```bash
# Profile app performance
flutter run --profile

# Check memory usage
adb shell dumpsys meminfo com.example.space

# Monitor frame rendering
# Enable Performance Overlay in Flutter DevTools
```

---

## Recommended Next Steps

1. ✅ Implement file cleanup (5 min)
2. ✅ Enable R8 shrinking (5 min)
3. ✅ Add image cache limits (10 min)
4. ✅ Implement profile caching with SharedPreferences (15 min)
5. ✅ Add lazy loading to avatar grid (30 min)

Total Time: ~1 hour for all optimizations!

