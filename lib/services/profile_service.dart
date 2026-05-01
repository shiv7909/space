import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/avatar_model.dart';

class ProfileService {
  final SupabaseClient supabaseClient;
  final Map<String, String> _avatarUrlCache = {};
  final Map<String, String> _photoUrlCache = {};

  /// Cache: avatarId (UUID) → avatarKey (e.g. "Number=18.webp")
  final Map<String, String> _avatarIdToKeyCache = {};

  /// Storage bucket for profile photos
  static const String _photoBucket = 'profile-photos';

  ProfileService({required this.supabaseClient});

  /// Check if user has a complete profile — retries up to 3 times on network errors
  Future<ProfileModel?> getProfile(String userId) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 800);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print(
          '🔵 ProfileService: Fetching profile for user: $userId (attempt $attempt)',
        );
        // JOIN profile_photos so photo_key comes back in one query
        final response =
            await supabaseClient
                .from('profiles')
                .select('*, profile_photos(photo_key)')
                .eq('id', userId)
                .maybeSingle();

        print('🔵 ProfileService: Response: $response');
        if (response == null) {
          print('🟡 ProfileService: No profile found for user $userId');
          return null;
        }

        // Flatten the nested profile_photos object into the top-level map
        final flat = Map<String, dynamic>.from(response);
        final photoRow = flat['profile_photos'];
        if (photoRow is Map) {
          flat['photo_key'] = photoRow['photo_key'];
        }
        flat.remove('profile_photos');

        print('🟢 ProfileService: Profile found: ${flat['display_name']}');
        return ProfileModel.fromJson(flat);
      } catch (e) {
        final errStr = e.toString();
        final isNetworkError =
            errStr.contains('SSL') ||
            errStr.contains('525') ||
            errStr.contains('SocketException') ||
            errStr.contains('HandshakeException') ||
            errStr.contains('Connection') ||
            errStr.contains('<!DOCTYPE');

        print(
          '🔴 ProfileService: Error fetching profile (attempt $attempt): $e',
        );

        if (isNetworkError && attempt < maxRetries) {
          print(
            '🟡 ProfileService: Network error — retrying in ${retryDelay.inMilliseconds}ms...',
          );
          await Future.delayed(retryDelay);
          continue;
        }

        // On final attempt or non-network error, re-throw so caller can handle
        rethrow;
      }
    }
    return null;
  }

  /// Create a new profile
  Future<ProfileModel> createProfile({
    required String userId,
    required String displayName,
    String? avatarId,
  }) async {
    try {
      final data = {
        'id': userId,
        'display_name': displayName,
        'avatar_id': avatarId,

        'timezone': 'UTC',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response =
          await supabaseClient.from('profiles').insert(data).select().single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      print('Error creating profile: $e');
      rethrow;
    }
  }

  /// Update profile
  Future<ProfileModel> updateProfile({
    required String userId,
    String? displayName,
    String? avatarId,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) data['display_name'] = displayName;
      if (avatarId != null) data['avatar_id'] = avatarId;

      final response =
          await supabaseClient
              .from('profiles')
              .update(data)
              .eq('id', userId)
              .select()
              .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Get all available avatars
  Future<List<AvatarModel>> getAvatars() async {
    try {
      print('🔵 ProfileService: Fetching avatars from database...');
      final response = await supabaseClient
          .from('avatars')
          .select()
          .order('created_at');

      print('🔵 ProfileService: Avatar response: $response');
      final avatarList =
          (response as List).map((json) => AvatarModel.fromJson(json)).toList();
      print('🟢 ProfileService: Parsed ${avatarList.length} avatars');
      return avatarList;
    } catch (e) {
      print('🔴 ProfileService: Error fetching avatars: $e');
      return [];
    }
  }

  /// Get avatar URL from storage
  Future<String> getAvatarUrl(String avatarKey) async {
    try {
      // Check cache first
      if (_avatarUrlCache.containsKey(avatarKey)) {
        print('🟡 ProfileService: Avatar URL for $avatarKey found in cache');
        return _avatarUrlCache[avatarKey]!;
      }

      // ✅ FIXED: Use public URL directly since Avatars bucket is public
      final url = supabaseClient.storage
          .from('Avatars')
          .getPublicUrl(avatarKey);

      // Cache the generated URL
      _avatarUrlCache[avatarKey] = url;

      print('🔵 ProfileService: Public avatar URL for $avatarKey: $url');
      return url;
    } catch (e) {
      print('🔴 ProfileService: Error generating URL for $avatarKey: $e');
      rethrow;
    }
  }

  /// Get avatar bytes from storage and remove background
  Future<Uint8List> getAvatarBytes(String avatarKey) async {
    try {
      final url = await getAvatarUrl(avatarKey);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }
      // Return original bytes without any background removal or processing
      return response.bodyBytes;
    } catch (e) {
      print(
        '🔴 ProfileService: Error fetching avatar bytes for $avatarKey: $e',
      );
      rethrow;
    }
  }

  /// Get avatar URL by avatar ID
  Future<String?> getAvatarUrlById(String avatarId) async {
    try {
      // Check id→key cache first to avoid a DB round-trip on every rebuild
      String avatarKey;
      if (_avatarIdToKeyCache.containsKey(avatarId)) {
        print('🟡 ProfileService: Avatar key for ID $avatarId found in cache');
        avatarKey = _avatarIdToKeyCache[avatarId]!;
      } else {
        final avatar =
            await supabaseClient
                .from('avatars')
                .select('avatar_key')
                .eq('id', avatarId)
                .single();
        avatarKey = avatar['avatar_key'] as String;
        _avatarIdToKeyCache[avatarId] = avatarKey;
      }
      return await getAvatarUrl(avatarKey);
    } catch (e) {
      print('🔴 ProfileService: Error getting avatar URL by ID $avatarId: $e');
      return null;
    }
  }

  /// Get user ID by email — uses the search_user_by_email RPC
  Future<String?> getUserIdByEmail(String email) async {
    try {
      print('🔵 ProfileService: Searching for user with email: $email');

      final response = await supabaseClient.rpc(
        'search_user_by_email',
        params: {'p_email': email},
      );

      final data = Map<String, dynamic>.from(response as Map);

      if (data['success'] == true) {
        final userId = data['user_id'] as String;
        print('🟢 ProfileService: Found user: $userId');
        return userId;
      }

      print('🟡 ProfileService: ${data['message']}');
      return null;
    } catch (e) {
      print('🔴 ProfileService: Error searching user by email: $e');
      return null;
    }
  }

  /// Update display name for current user
  Future<void> updateDisplayName(String displayName) async {
    final userId = supabaseClient.auth.currentUser!.id;
    await updateProfile(userId: userId, displayName: displayName);
  }

  /// Update avatar URL for current user
  Future<void> updateAvatarUrl(String avatarUrl) async {
    // For now, since avatarUrl is not directly stored, we'll assume it's handled elsewhere
    // This method is added to fix the compilation error
    // TODO: Implement proper avatar URL update logic
    print('updateAvatarUrl called with $avatarUrl - not implemented yet');
  }

  /// Update avatar ID for current user
  Future<void> updateAvatarId(String avatarId) async {
    final userId = supabaseClient.auth.currentUser!.id;
    await updateProfile(userId: userId, avatarId: avatarId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROFILE PHOTO — Upload / Display / Delete
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload a profile photo to Storage and link it via RPC.
  /// Returns the updated [ProfileModel] with photoId/photoKey set.
  Future<ProfileModel> uploadProfilePhoto(File imageFile) async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;

      // Fetch current profile to get the old photoKey for cleanup later
      final currentProfile = await getProfile(userId);
      final oldPhotoKey = currentProfile?.photoKey;

      // Generate a unique path to bust the image cache across the app
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$userId/$timestamp.jpg';

      print('🔵 ProfileService: Uploading profile photo to $path...');

      // 1. Upload to Storage
      await supabaseClient.storage
          .from(_photoBucket)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      print('🟢 ProfileService: Photo uploaded to Storage');

      // 2. Link via RPC — upserts profile_photos row, sets photo_id on profile
      final res = await supabaseClient.rpc(
        'update_profile_photo',
        params: {'p_photo_key': path},
      );

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] != true) {
        throw Exception('RPC update_profile_photo failed');
      }

      print('🟢 ProfileService: Photo linked — photo_id=${data['photo_id']}');

      // 3. Cleanup: Delete the old photo from storage if it exists
      if (oldPhotoKey != null && oldPhotoKey != path) {
        try {
          await supabaseClient.storage.from(_photoBucket).remove([oldPhotoKey]);
          _photoUrlCache.remove(oldPhotoKey);
          print('🟢 ProfileService: Cleaned up old photo ($oldPhotoKey)');
        } catch (e) {
          print(
            '🟡 ProfileService: Failed to clean up old photo (ignoring): $e',
          );
        }
      }

      // 4. Invalidate cached URL for this user
      _photoUrlCache.remove(path);

      // 5. Re-fetch full profile so caller gets the updated model
      final profile = await getProfile(userId);
      return profile!;
    } catch (e) {
      print('🔴 ProfileService: Error uploading profile photo: $e');
      rethrow;
    }
  }

  /// Returns the public URL for a profile photo key.
  /// Synchronous — no expiry, no signing, no network call.
  String getProfilePhotoUrl(String photoKey) {
    return supabaseClient.storage.from(_photoBucket).getPublicUrl(photoKey);
  }

  /// Get a public URL for a profile photo by its UUID (profile_photos.id PK).
  /// Queries profile_photos by primary key — no user_id column needed.
  Future<String?> getProfilePhotoUrlByPhotoId(String photoId) async {
    try {
      final row =
          await supabaseClient
              .from('profile_photos')
              .select('photo_key')
              .eq('id', photoId)
              .maybeSingle();

      if (row == null) return null;
      return getProfilePhotoUrl(row['photo_key'] as String);
    } catch (e) {
      print(
        '🔴 ProfileService: Error getting photo URL for photo $photoId: $e',
      );
      return null;
    }
  }

  /// Get a public URL for a profile photo by user ID.
  /// Looks up the photo_key from the profile_photos table by user_id.
  Future<String?> getProfilePhotoUrlByUserId(String userId) async {
    try {
      final row =
          await supabaseClient
              .from('profile_photos')
              .select('photo_key')
              .eq('user_id', userId)
              .maybeSingle();

      if (row == null) return null;
      return getProfilePhotoUrl(row['photo_key'] as String);
    } catch (e) {
      print('🔴 ProfileService: Error getting photo URL for user $userId: $e');
      return null;
    }
  }

  /// Delete the current user's profile photo. Reverts to avatar display.
  /// Calls the delete_profile_photo RPC and removes the file from Storage.
  Future<ProfileModel> deleteProfilePhoto() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;

      print('🔵 ProfileService: Deleting profile photo...');

      // 1. RPC — clears photo_id, deletes row, returns photo_key
      final res = await supabaseClient.rpc('delete_profile_photo');
      final data = Map<String, dynamic>.from(res as Map);

      if (data['success'] == true) {
        final photoKey = data['photo_key'] as String;

        // 2. Remove file from Storage
        await supabaseClient.storage.from(_photoBucket).remove([photoKey]);
        print('🟢 ProfileService: Photo deleted from Storage ($photoKey)');

        // 3. Invalidate cache
        _photoUrlCache.remove(photoKey);
      } else {
        print('🟡 ProfileService: No photo to delete');
      }

      // 4. Re-fetch profile
      final profile = await getProfile(userId);
      return profile!;
    } catch (e) {
      print('🔴 ProfileService: Error deleting profile photo: $e');
      rethrow;
    }
  }

  /// Resolve the display URL for a profile — photo first, avatar fallback.
  /// Returns a map with 'url' and 'isPhoto' keys.
  Future<Map<String, dynamic>> resolveProfileImageUrl(
    ProfileModel profile,
  ) async {
    // Priority 1: Real photo
    if (profile.hasPhoto) {
      try {
        final url = await getProfilePhotoUrl(profile.photoKey!);
        return {'url': url, 'isPhoto': true};
      } catch (_) {
        // Fall through to avatar
      }
    }

    // Priority 2: Preset avatar
    if (profile.avatarId != null) {
      final url = await getAvatarUrlById(profile.avatarId!);
      if (url != null) return {'url': url, 'isPhoto': false};
    }

    // Priority 3: Nothing
    return {'url': null, 'isPhoto': false};
  }
}
