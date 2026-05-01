import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/snap_model.dart';
import '../models/snap_tray_model.dart';
import '../models/snap_sender_response.dart';

/// Service layer for the Snap System.
/// Calls all backend RPCs and handles image upload / signed-URL generation.
class SnapService {
  final SupabaseClient supabaseClient;

  // Standard paginated viewers payload:
  // { viewers, view_count, has_more, next_cursor, success }
  static const Map<String, dynamic> _emptyViewersPage = {
    'viewers': <Map<String, dynamic>>[],
    'view_count': 0,
    'has_more': false,
    'next_cursor': null,
    'success': false,
  };

  /// Supabase Storage bucket name for habit snaps.
  static const String _bucket = 'habit-snaps';

  SnapService({required this.supabaseClient});

  // ═══════════════════════════════════════════════════════════════════════
  //  TRAY — get_space_snaps_tray
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns one bubble per member who has active snaps today.
  /// Sorted: unseen from others → own bubble → seen from others.
  Future<SnapTrayResponse> getSpaceSnapsTray(String spaceId) async {
    try {
      print('🔵 SnapService: Fetching snaps tray for space $spaceId...');

      final response = await supabaseClient.rpc(
        'get_space_snaps_tray',
        params: {'p_space_id': spaceId == '00000000-0000-0000-0000-000000000000' ? null : spaceId},
      );

      if (response == null) {
      return SnapTrayResponse(
          tray: [], iPostedToday: false, totalActiveSnaps: 0, unseenCount: 0,
        );
      }

      final data = Map<String, dynamic>.from(response as Map);
      final result = SnapTrayResponse.fromJson(data);
      print('🟢 SnapService: Tray loaded — ${result.tray.length} senders, '
            '${result.unseenCount} unseen');
      return result;
    } catch (e) {
      print('🔴 SnapService: Error fetching snaps tray: $e');
      return SnapTrayResponse(
        tray: [], iPostedToday: false, totalActiveSnaps: 0, unseenCount: 0,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HOME TRAY — get_home_snaps_tray
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns story tray for the home screen — aggregated across all spaces.
  /// One bubble per sender, sorted: unseen others → own → seen others.
  Future<SnapTrayResponse> getHomeTray() async {
    try {
      print('🔵 SnapService: Fetching home snaps tray...');

      final response = await supabaseClient.rpc('get_home_snaps_tray');

      if (response == null) {
        return SnapTrayResponse(
          tray: [], iPostedToday: false, totalActiveSnaps: 0, unseenCount: 0,
        );
      }

      final data = Map<String, dynamic>.from(response as Map);
      final result = SnapTrayResponse.fromJson(data);
      print('🟢 SnapService: Home tray loaded — ${result.tray.length} senders, '
            '${result.unseenCount} unseen');
      return result;
    } catch (e) {
      print('🔴 SnapService: Error fetching home tray: $e');
      return SnapTrayResponse(
        tray: [], iPostedToday: false, totalActiveSnaps: 0, unseenCount: 0,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SNAP SPACES — get_my_snap_spaces
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns spaces eligible for sending snaps (couple and group spaces)
  Future<List<Map<String, dynamic>>> getMySnapSpaces() async {
    try {
      final response = await Supabase.instance.client.rpc('get_my_snap_spaces');
      if (response == null) return [];
      
      if (response is Map) {
        final data = Map<String, dynamic>.from(response);
        final listData = data['spaces'] ?? data['data'];
        if (listData is List) {
          return List<Map<String, dynamic>>.from(
            listData.map((e) => Map<String, dynamic>.from(e as Map))
          );
        }
        return [];
      } else if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((e) => Map<String, dynamic>.from(e as Map))
        );
      }
      return [];
    } catch (e) {
      debugPrint('🔴 SnapService: Error getting snap spaces: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SENDER SNAPS — get_space_sender_snaps
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns all active snaps from one sender.
  /// Routes to the correct RPC based on context (space vs challenge).
  Future<SenderSnapsResult> fetchSenderSnaps({
    required String senderId,
    String? spaceId,
    String? challengeId,
    SnapSenderInfo? knownSender,
  }) async {
    assert(spaceId != null || challengeId != null, 'Must provide either spaceId or challengeId');

    if (challengeId != null) {
      print('🔵 SnapService: Fetching sender $senderId snaps for challenge $challengeId...');
      final res = await supabaseClient.rpc('get_challenge_story_snaps', params: {
        'p_challenge_id': challengeId,
        'p_sender_id':    senderId,
      });

      if (res == null) throw Exception('Empty response from get_challenge_story_snaps');
      final data = Map<String, dynamic>.from(res as Map);
      
      if (data['success'] != true) {
        throw Exception(data['code'] ?? 'Failed to load challenge snaps');
      }

      if (data['sender'] == null && knownSender != null) {
        data['sender'] = {
          'id': knownSender.id,
          'display_name': knownSender.displayName,
          'avatar_id': knownSender.avatarId,
          'avatar_key': knownSender.avatarKey,
          'photo_id': knownSender.photoId,
          'photo_key': knownSender.photoKey,
        };
      }

      if (data['sender'] == null) {
        throw Exception('Sender not found in this challenge');
      }

      print('🟢 SnapService: Loaded challenge snaps for sender');
      return SenderSnapsResult.fromChallenge(data);

    } else {
      print('🔵 SnapService: Fetching sender $senderId snaps for space $spaceId...');
      final res = await supabaseClient.rpc('get_space_sender_snaps', params: {
        'p_space_id':  spaceId!,
        'p_sender_id': senderId,
      });

      if (res == null) throw Exception('Empty response from get_space_sender_snaps');
      final data = Map<String, dynamic>.from(res as Map);
      
      if (data['success'] != true) {
        throw Exception(data['code'] ?? 'Failed to load space snaps');
      }
      if (data['sender'] == null) {
        throw Exception('Sender not found in this space');
      }

      print('🟢 SnapService: Loaded space snaps for sender');
      return SenderSnapsResult.fromSpace(data);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  UPLOAD
  // ═══════════════════════════════════════════════════════════════════════

  /// Upload an image file to Storage and return the storage path.
  /// Path format: `{spaceId}/{userId}/{timestamp}.jpg`
  Future<String> uploadSnapImage({
    required File imageFile,
    required String spaceId,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$spaceId/$timestamp.jpg';

      print('🔵 SnapService: Uploading snap image to $storagePath...');

      await supabaseClient.storage.from(_bucket).upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      print('🟢 SnapService: Image uploaded successfully');
      return storagePath;
    } catch (e) {
      print('🔴 SnapService: Error uploading image: $e');
      rethrow;
    }
  }

  /// Generate a signed URL for a storage path (valid for 60 seconds).
  Future<String> getSignedUrl(String storagePath) async {
    try {
      final url = await supabaseClient.storage
          .from(_bucket)
          .createSignedUrl(storagePath, 60);
      return url;
    } catch (e) {
      print('🔴 SnapService: Error generating signed URL: $e');
      rethrow;
    }
  }

  /// Generate a signed URL for a snap image (valid for 24 hours to match snap lifetime).
  Future<String> getSnapImageUrl(
    String storagePath, {
    String bucket = _bucket,
  }) async {
    try {
      // Signed URL valid for 86400 seconds (24hrs — matches snap lifetime)
      final url = await supabaseClient.storage
          .from(bucket)
          .createSignedUrl(storagePath, 86400);
      return url;
    } catch (e) {
      print('🔴 SnapService: Error generating snap image URL: $e');
      rethrow;
    }
  }

  /// Delete a file from Storage by its path.
  Future<void> deleteFromStorage(String storagePath) async {
    try {
      await supabaseClient.storage.from(_bucket).remove([storagePath]);
      print('🟢 SnapService: Deleted file from storage: $storagePath');
    } catch (e) {
      print('🔴 SnapService: Error deleting from storage: $e');
      // Non-fatal — cleanup cron will handle it
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 1 — send_snap
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a snap row after upload. Validates 1/day limit per user per space.
  /// Solo spaces are blocked by the backend.
  Future<Map<String, dynamic>> sendSnap({
    required String spaceId,
    required String storagePath,
    String? habitId,
    String? caption,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('🔵 Sending snap — userId: ${user?.id}, spaceId: $spaceId');

      final response = await Supabase.instance.client.rpc(
        'send_snap',
        params: {
          'p_space_id': spaceId,
          'p_storage_path': storagePath,
          'p_habit_id': habitId,
          'p_caption': caption,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      debugPrint('🟢 send_snap response: $data');
      return data;
    } catch (e) {
      debugPrint('🔴 SnapService: Error sending snap: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 2 — get_space_snaps
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns all active snaps for a space — metadata only, no image URLs.
  Future<List<SnapModel>> getSpaceSnaps(String spaceId) async {
    try {
      print('🔵 SnapService: Fetching snaps for space $spaceId...');

      final response = await supabaseClient.rpc(
        'get_space_snaps',
        params: {'p_space_id': spaceId},
      );

      if (response == null) return [];

      final data = Map<String, dynamic>.from(response as Map);

      // Check for success
      if (data['success'] != true) {
        print('🔴 SnapService: get_space_snaps failed: ${data['code']}');
        return [];
      }

      final rawList = data['snaps'] as List? ?? [];

      final snaps = rawList
          .map((item) => SnapModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      print('🟢 SnapService: Fetched ${snaps.length} snaps');
      return snaps;
    } catch (e) {
      print('🔴 SnapService: Error fetching snaps: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 3 — view_snap
  // ═══════════════════════════════════════════════════════════════════════

  /// Marks a snap as viewed and returns the storage_path for signed URL.
  Future<Map<String, dynamic>> viewSnap(String snapId) async {
    try {
      print('🔵 SnapService: Viewing snap $snapId...');

      final response = await supabaseClient.rpc(
        'view_snap',
        params: {'p_snap_id': snapId},
      ).timeout(const Duration(seconds: 10));

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: view_snap response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error viewing snap: $e');
      rethrow;
    }
  }

  /// Marks a challenge snap as viewed.
  /// Calls challenge-specific RPC so brand challenge view counts update.
  Future<Map<String, dynamic>> viewBrandSnap(String snapId) async {
    try {
      print('🔵 SnapService: Viewing brand snap $snapId...');

      final response = await supabaseClient.rpc(
        'view_brand_snap',
        params: {'p_snap_id': snapId},
      ).timeout(const Duration(seconds: 10));

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: view_brand_snap response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error viewing brand snap: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 3b — view_snap (owner re-view)
  // ═══════════════════════════════════════════════════════════════════════

  /// Owner can view their own snap any number of times.
  /// Generates a signed URL directly from the storage path without RPC.
  Future<String?> viewOwnSnap(String storagePath) async {
    try {
      return await getSnapImageUrl(storagePath);
    } catch (e) {
      print('🔴 SnapService: Error viewing own snap: $e');
      return null;
    }
  }

  /// Fallback for when storagePath is not cached in the model.
  /// Fetches the storage_path directly from the DB (owner-only select)
  /// without touching the one-time view_snap RPC gate.
  Future<String?> viewOwnSnapRpc(String snapId) async {
    try {
      print('🔵 SnapService: Fetching own snap storage path for $snapId...');
      final response = await supabaseClient
          .from('habit_snaps')
          .select('storage_path')
          .eq('id', snapId)
          .eq('sender_id', supabaseClient.auth.currentUser!.id)
          .single();
      final path = response['storage_path'] as String?;
      if (path == null || path.isEmpty) return null;
      return await getSnapImageUrl(path);
    } catch (e) {
      print('🔴 SnapService: Error in viewOwnSnapRpc: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC — get_snap_viewers (paginated) - both habit and brand snaps
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a paginated page of viewers for a snap (owner only).
  /// Automatically uses correct RPC (get_snap_viewers for habit, get_brand_snap_viewers for brand)
  /// 
  /// Params:
  ///   - snapId: the snap identifier
  ///   - isBrandSnap: true to use brand snap RPC, false for habit snap RPC (default)
  ///   - limit: page size (default 20, max clamped to 50)
  ///   - afterViewedAt: cursor timestamp from previous page's next_cursor (for polling next page)
  /// 
  /// Response shape: { viewers, view_count, has_more, next_cursor, success }
  /// - viewers: [{ viewer_id, viewer_name, avatar_key, photo_key, viewed_at, reaction }]
  /// - view_count: total viewers count
  /// - has_more: whether more pages exist
  /// - next_cursor: timestamp to pass on next call (null if no more)
  Future<Map<String, dynamic>> getSnapViewers(
    String snapId, {
    bool isBrandSnap = false,
    int limit = 20,
    String? afterViewedAt,
  }) async {
    try {
      final rpcName = isBrandSnap ? 'get_brand_snap_viewers' : 'get_snap_viewers';
      final logNote = afterViewedAt != null ? ' (page continuation)' : ' (first page)';
      print('🔵 SnapService: Fetching viewers for snap $snapId...$logNote (RPC: $rpcName)');

      final params = {
        'p_snap_id': snapId,
        'p_limit': limit,
      };
      if (afterViewedAt != null) {
        params['p_after_viewed_at'] = afterViewedAt;
      }

      final response = await supabaseClient.rpc(
        rpcName,
        params: params,
      );

      if (response == null) {
        return _emptyViewersPage;
      }

      // Response could be a Map with viewers + metadata
      if (response is Map) {
        return {
          'viewers': (response['viewers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
          'view_count': response['view_count'] as int? ?? 0,
          'has_more': response['has_more'] as bool? ?? false,
          'next_cursor': response['next_cursor'] as String?,
          'success': response['success'] as bool? ?? true,
        };
      }

      // Fallback: if it's a plain List, wrap it
      if (response is List) {
        return {
          'viewers': response.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          'view_count': 0,
          'has_more': false,
          'next_cursor': null,
          'success': true,
        };
      }

      return {
        ..._emptyViewersPage,
      };
    } catch (e) {
      print('🔴 SnapService: Error fetching snap viewers: $e');
      return _emptyViewersPage;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 4 — react_to_snap
  // ═══════════════════════════════════════════════════════════════════════

  /// Toggles a reaction on a snap. Fixed set: fire, strong, laugh, eyes, heart.
  Future<Map<String, dynamic>> reactToSnap({
    required String snapId,
    required String reaction,
    bool isChallengeSnap = false,
  }) async {
    try {
      final rpcReaction =
          isChallengeSnap && reaction == 'strong' ? 'flex' : reaction;
      final rpcName = isChallengeSnap ? 'react_to_brand_snap' : 'react_to_snap';

      print('🔵 SnapService: Reacting to snap $snapId with $rpcReaction...');

      final response = await supabaseClient.rpc(
        rpcName,
        params: {
          'p_snap_id': snapId,
          'p_reaction': rpcReaction,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: $rpcName response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error reacting to snap: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 5 — delete_snap / delete_brand_snap
  // ═══════════════════════════════════════════════════════════════════════

  /// Owner-only delete. Returns storage_path for immediate storage cleanup.
  ///
  /// For brand challenge snaps, uses delete_brand_snap and brand-snaps bucket.
  /// For regular snaps, uses delete_snap and habit-snaps bucket.
  Future<Map<String, dynamic>> deleteSnap(
    String snapId, {
    bool isChallengeSnap = false,
  }) async {
    try {
      print('🔵 SnapService: Deleting snap $snapId...');

      final response = await supabaseClient.rpc(
        isChallengeSnap ? 'delete_brand_snap' : 'delete_snap',
        params: {'p_snap_id': snapId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print(
        '🟢 SnapService: ${isChallengeSnap ? 'delete_brand_snap' : 'delete_snap'} response: $data',
      );

      // Clean up storage file if path was returned
      final storagePath = data['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        if (isChallengeSnap) {
          await supabaseClient.storage.from('brand-snaps').remove([storagePath]);
          print('🟢 SnapService: Deleted brand snap from storage: $storagePath');
        } else {
          await deleteFromStorage(storagePath);
        }
      }

      return data;
    } catch (e) {
      print('🔴 SnapService: Error deleting snap: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 6 — report_snap
  // ═══════════════════════════════════════════════════════════════════════

  /// Logs a report for manual review.
  Future<Map<String, dynamic>> reportSnap({
    required String snapId,
    required String reason,
    String? details,
  }) async {
    try {
      print('🔵 SnapService: Reporting snap $snapId...');

      final response = await supabaseClient.rpc(
        'report_snap',
        params: {
          'p_snap_id': snapId,
          'p_reason': reason,
          'p_details': details,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: report_snap response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error reporting snap: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 7 — block_user
  // ═══════════════════════════════════════════════════════════════════════

  /// Hides that user's snaps from all your feeds.
  Future<Map<String, dynamic>> blockUser(String blockedId) async {
    try {
      print('🔵 SnapService: Blocking user $blockedId...');

      final response = await supabaseClient.rpc(
        'block_user',
        params: {'p_blocked_id': blockedId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: block_user response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error blocking user: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 8 — unblock_user
  // ═══════════════════════════════════════════════════════════════════════

  /// Reverses a block.
  Future<Map<String, dynamic>> unblockUser(String blockedId) async {
    try {
      print('🔵 SnapService: Unblocking user $blockedId...');

      final response = await supabaseClient.rpc(
        'unblock_user',
        params: {'p_blocked_id': blockedId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SnapService: unblock_user response: $data');
      return data;
    } catch (e) {
      print('🔴 SnapService: Error unblocking user: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RPC 9 — get_my_blocks
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the list of users the current user has blocked.
  /// Each item: { blocked_id, display_name, avatar_id, blocked_at }
  Future<List<Map<String, dynamic>>> getMyBlocks() async {
    try {
      print('🔵 SnapService: Fetching block list...');

      final response = await supabaseClient.rpc('get_my_blocks');

      if (response == null) return [];

      List rawList;
      if (response is Map && response['blocks'] is List) {
        rawList = response['blocks'] as List;
      } else if (response is List) {
        rawList = response;
      } else {
        rawList = [];
      }

      final blocks = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      print('🟢 SnapService: Fetched ${blocks.length} blocked users');
      return blocks;
    } catch (e) {
      print('🔴 SnapService: Error fetching block list: $e');
      return [];
    }
  }
}
