// ============================================================
// HABITZ — Brand Challenge Service
// All methods use Supabase RPCs — no direct table queries.
//
// Follows the existing SpaceService / SnapService pattern:
//   - Takes SupabaseClient via constructor
//   - Every method handles its own errors
//   - Colored log emojis: 🔵 start, 🟢 success, 🔴 error
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand_challenge_models.dart';
import '../models/brand_snap_model.dart';
import '../models/home_brand_section_model.dart';
import '../models/snap_tray_model.dart';

class BrandChallengeService {
  final SupabaseClient supabaseClient;
  HomeBrandSectionModel? _homeBrandSectionCache;
  DateTime? _homeBrandSectionFetchedAt;

  BrandChallengeService({required this.supabaseClient});
  // ═══════════════════════════════════════════════════════════════════════
  //  SNAP TRAY — get_snaps_tray (challenge context)
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns one bubble per participant who has active snaps in this challenge.
  /// Sorted: unseen from others → own bubble → seen from others.
  Future<SnapTrayResponse> getSnapsTray(String challengeId) async {
    try {
      print(
        '🔵 BrandChallengeService: Fetching snaps tray for challenge $challengeId...',
      );

      final response = await supabaseClient.rpc(
        'get_snaps_tray',
        params: {'p_challenge_id': challengeId},
      );

      if (response == null) {
        return SnapTrayResponse(
          tray: [],
          iPostedToday: false,
          totalActiveSnaps: 0,
          unseenCount: 0,
        );
      }

      final data = Map<String, dynamic>.from(response as Map);
      final result = SnapTrayResponse.fromJson(data);

      // Sign preview_storage_path for each tray item in parallel
      if (result.tray.isNotEmpty) {
        final signedUrls = await Future.wait(
          result.tray.map((item) async {
            final path = item.previewStoragePath;
            if (path == null || path.isEmpty) return null;
            try {
              return await supabaseClient.storage
                  .from('brand-snaps')
                  .createSignedUrl(path, 3600);
            } catch (_) {
              return null;
            }
          }),
        );
        // Attach signed URLs back onto each item
        for (var i = 0; i < result.tray.length; i++) {
          result.tray[i].previewSignedUrl = signedUrls[i];
        }
      }

      print(
        '🟢 BrandChallengeService: Tray loaded — ${result.tray.length} senders',
      );
      return result;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching snaps tray: $e');
      return SnapTrayResponse(
        tray: [],
        iPostedToday: false,
        totalActiveSnaps: 0,
        unseenCount: 0,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STORIES — get_challenge_stories (challenge context)
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns story bubbles (rings) for a challenge, paginated.
  /// Each story = one sender, but just meta-data, no snaps nested.
  /// Must be enrolled to call this.
  Future<ChallengeStoriesResponse> getChallengeStories(
    String challengeId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print(
        '🔵 BrandChallengeService: Fetching stories page $page for challenge $challengeId...',
      );

      final response = await supabaseClient.rpc(
        'get_challenge_stories',
        params: {
          'p_challenge_id': challengeId,
          'p_page': page,
          'p_limit': limit,
        },
      );

      if (response == null) {
        return ChallengeStoriesResponse.empty;
      }

      final data = Map<String, dynamic>.from(response as Map);
      final result = ChallengeStoriesResponse.fromJson(data);

      print(
        '🟢 BrandChallengeService: Stories loaded — ${result.stories.length} senders (page $page)',
      );
      return result;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching stories: $e');
      return ChallengeStoriesResponse.empty;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CHALLENGES — Discovery & Listing
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch all active brand challenges (for discovery screen).
  Future<List<DiscoveryChallengeModel>> getActiveChallenges() async {
    try {
      print('🔵 BrandChallengeService: Fetching active challenges...');

      final response = await supabaseClient.rpc('get_active_challenges');

      if (response == null) return [];

      final challenges =
          (response as List)
              .map(
                (e) => DiscoveryChallengeModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      print(
        '🟢 BrandChallengeService: Fetched ${challenges.length} active challenges',
      );
      return challenges;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching active challenges: $e');
      return [];
    }
  }

  /// Fetch home brand section card.
  /// Caches successful responses for 60 seconds to avoid repeated RPC calls
  /// when users switch tabs frequently.
  Future<HomeBrandSectionModel?> getHomeBrandSection({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _homeBrandSectionCache != null &&
        _homeBrandSectionFetchedAt != null &&
        now.difference(_homeBrandSectionFetchedAt!).inSeconds < 60) {
      return _homeBrandSectionCache;
    }

    try {
      print('🔵 BrandChallengeService: Fetching home brand section...');

      final response = await supabaseClient.rpc('get_home_brand_section');
      if (response == null || response is! Map) {
        _homeBrandSectionCache = const HomeBrandSectionModel(
          card: null,
          snapLimit: 0,
        );
        _homeBrandSectionFetchedAt = now;
        return _homeBrandSectionCache;
      }

      final payload = Map<String, dynamic>.from(response);
      final hasEnvelope =
          payload.containsKey('success') ||
          payload.containsKey('status') ||
          payload.containsKey('code') ||
          payload.containsKey('message');
      final isSuccess = payload['success'] == true || payload['status'] == 200;

      if (hasEnvelope && !isSuccess) {
        final code = (payload['code'] ?? '').toString();
        final message = (payload['message'] ?? '').toString();

        // Hide Brand Drops completely for known empty states like inactive-only data.
        _homeBrandSectionCache = const HomeBrandSectionModel(
          card: null,
          snapLimit: 0,
        );
        _homeBrandSectionFetchedAt = now;
        print(
          '🟡 BrandChallengeService: Home brand section hidden '
          '(code=$code, message=$message)',
        );
        return _homeBrandSectionCache;
      }

      final result = HomeBrandSectionModel.fromJson(
        payload,
      );

      _homeBrandSectionCache = result;
      _homeBrandSectionFetchedAt = now;
      print(
        '🟢 BrandChallengeService: Home brand section loaded '
        '(hasCard=${result.card != null}, cardType=${result.card?.cardType})',
      );
      return result;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching home brand section: $e');
      return _homeBrandSectionCache;
    }
  }

  /// Get all challenges the current user is enrolled in (still running).
  /// Filters: ends_at > NOW() + is_active = true
  /// Includes days_left for countdown badge
  Future<List<HomeBrandCardModel>> getMyActiveChallenges() async {
    try {
      print('🔵 BrandChallengeService: Fetching my active challenges...');

      final response = await supabaseClient.rpc('get_my_active_challenges');

      if (response == null) return [];

      final challenges =
          (response as List)
              .map(
                (e) => HomeBrandCardModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      print(
        '🟢 BrandChallengeService: Fetched ${challenges.length} active enrolled challenges',
      );
      return challenges;
    } catch (e) {
      print(
        '🔴 BrandChallengeService: Error fetching my active challenges: $e',
      );
      return [];
    }
  }

  /// Get all challenges the current user completed or failed (ended).
  /// Filters: ends_at <= NOW() OR is_active = false
  /// Includes my_stats with final score: total_logs, best_streak, completion_pct
  /// Includes "earned": true/false on each milestone
  Future<List<BrandChallengeModel>> getMyPastChallenges() async {
    try {
      print('🔵 BrandChallengeService: Fetching my past challenges...');

      final response = await supabaseClient.rpc('get_my_past_challenges');

      if (response == null) return [];

      final challenges =
          (response as List)
              .map(
                (e) => BrandChallengeModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      print(
        '🟢 BrandChallengeService: Fetched ${challenges.length} past enrolled challenges',
      );
      return challenges;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching my past challenges: $e');
      return [];
    }
  }

  /// Get all challenges the current user is enrolled in (legacy — use getMyActiveChallenges + getMyPastChallenges instead).
  @Deprecated('Use getMyActiveChallenges() or getMyPastChallenges() instead')
  Future<List<BrandChallengeModel>> getMyChallenges() async {
    try {
      print('🔵 BrandChallengeService: Fetching my challenges...');

      final response = await supabaseClient.rpc('get_my_challenges');

      if (response == null) return [];

      final challenges =
          (response as List)
              .map(
                (e) => BrandChallengeModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

      print(
        '🟢 BrandChallengeService: Fetched ${challenges.length} enrolled challenges',
      );
      return challenges;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching my challenges: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CHALLENGE DETAIL — 5 RPC Section Loaders
  // ═══════════════════════════════════════════════════════════════════════

  // ── ①②  HEADER (hero + stats + brand + enrollment) ────────────────────

  Future<ChallengeHeaderModel?> getChallengeHeader(String challengeId) async {
    try {
      print('🔵 BrandChallengeService: Fetching header $challengeId...');
      final response = await supabaseClient.rpc(
        'get_challenge_header',
        params: {'p_challenge_id': challengeId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] == false) return null;
      print('🟢 BrandChallengeService: Header fetched');
      return ChallengeHeaderModel.fromJson(data);
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching header: $e');
      return null;
    }
  }

  // ── ③  PULSE ──────────────────────────────────────────────

  Future<PulsePostModel?> getChallengePulse(String challengeId) async {
    try {
      print('🔵 BrandChallengeService: Fetching pulse $challengeId...');
      final response = await supabaseClient.rpc(
        'get_challenge_pulse',
        params: {'p_challenge_id': challengeId},
      );
      if (response == null) return null;
      print('🟢 BrandChallengeService: 1 pulse post loaded');
      return PulsePostModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching pulse: $e');
      return null;
    }
  }

  // ── ④  SNAPS (paginated) ──────────────────────────────────

  Future<BrandSnapPageResult> getChallengeSnaps(
    String challengeId, {
    int limit = 20,
    String? cursor,
  }) async {
    return getBrandSnaps(challengeId, limit: limit, cursor: cursor);
  }

  Future<BrandSnapPageResult> getBrandSnaps(
    String challengeId, {
    int limit = 20,
    String? cursor,
  }) async {
    try {
      print(
        '🔵 BrandChallengeService: Fetching snaps $challengeId cursor=$cursor...',
      );
      final response = await supabaseClient.rpc(
        'get_brand_snaps',
        params: {
          'p_challenge_id': challengeId,
          'p_limit': limit,
          'p_cursor': cursor,
        },
      );
      var result = BrandSnapPageResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      // Batch-sign storage_path for every snap in parallel
      if (result.snaps.isNotEmpty) {
        final signedUrls = await Future.wait(
          result.snaps.map((snap) async {
            try {
              return await supabaseClient.storage
                  .from('brand-snaps')
                  .createSignedUrl(snap.storagePath, 3600);
            } catch (_) {
              return null;
            }
          }),
        );
        final updatedSnaps = <BrandSnapModel>[];
        for (var i = 0; i < result.snaps.length; i++) {
          updatedSnaps.add(result.snaps[i].copyWith(signedUrl: signedUrls[i]));
        }
        result = BrandSnapPageResult(
          snaps: updatedSnaps,
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
          postedToday: result.postedToday,
          totalToday: result.totalToday,
        );
      }

      print(
        '🟢 BrandChallengeService: ${result.snaps.length} snaps, hasMore=${result.hasMore}',
      );
      return result;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching snaps: $e');
      return const BrandSnapPageResult(
        snaps: [],
        hasMore: false,
        postedToday: false,
        totalToday: 0,
      );
    }
  }

  // ── ⑤  PRODUCTS ──────────────────────────────────────────

  Future<List<BrandProductModel>> getChallengeProducts(
    String challengeId,
  ) async {
    try {
      print('🔵 BrandChallengeService: Fetching products $challengeId...');
      final response = await supabaseClient.rpc(
        'get_challenge_products',
        params: {'p_challenge_id': challengeId},
      );
      final list = (response as List?) ?? [];
      print('🟢 BrandChallengeService: ${list.length} products');
      return list
          .map(
            (e) =>
                BrandProductModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching products: $e');
      return [];
    }
  }

  // ── ⑧  COUPONS (Earned Rewards) ──────────────────────────

  Future<List<ChallengeCouponModel>> getChallengeCoupons(
    String challengeId,
  ) async {
    try {
      print('🔵 BrandChallengeService: Fetching coupons $challengeId...');
      final response = await supabaseClient.rpc(
        'get_my_challenge_coupons',
        params: {'p_challenge_id': challengeId},
      );
      final list = (response as List?) ?? [];
      print('🟢 BrandChallengeService: ${list.length} coupons');
      return list
          .map(
            (e) => ChallengeCouponModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching coupons: $e');
      return [];
    }
  }

  // ── ⑥⑦⑧  JOURNEY (progress + milestones + crew + energy) ──

  Future<ChallengeJourneyModel?> getChallengeJourney(String challengeId) async {
    try {
      print('🔵 BrandChallengeService: Fetching journey $challengeId...');
      final response = await supabaseClient.rpc(
        'get_challenge_journey',
        params: {'p_challenge_id': challengeId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 BrandChallengeService: Journey fetched');
      return ChallengeJourneyModel.fromJson(data);
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching journey: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ACTIONS — Enrollment, Habit Completion, Reactions
  // ═══════════════════════════════════════════════════════════════════════

  /// Enroll the current user in a brand challenge.
  Future<Map<String, dynamic>> enrollInChallenge(String challengeId) async {
    try {
      print('🔵 BrandChallengeService: Enrolling in challenge $challengeId...');

      final response = await supabaseClient.rpc(
        'enroll_brand_challenge',
        params: {'p_challenge_id': challengeId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 BrandChallengeService: enroll response: $data');
      return data;
    } catch (e) {
      print('🔴 BrandChallengeService: Error enrolling: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Failed to join challenge: ${e.toString()}',
      };
    }
  }

  /// Fetch membership/progress status for the current user in a challenge.
  /// Uses the view requested by product: brand_challenge_user_status.
  Future<Map<String, dynamic>?> getChallengeUserStatus(String challengeId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) return null;

      final row = await supabaseClient
          .from('brand_challenge_user_status')
          .select('*')
          .eq('challenge_id', challengeId)
          .eq('user_id', userId)
          .single();

      return Map<String, dynamic>.from(row as Map);
    } catch (e) {
      print('🟡 BrandChallengeService: brand_challenge_user_status lookup failed: $e');
      return null;
    }
  }

  /// Exit the current user's brand challenge membership.
  /// Uses server-side cleanup function: exit_brand_challenge_self.
  Future<Map<String, dynamic>> exitChallengeSelf(String challengeId) async {
    try {
      print('🔵 BrandChallengeService: Exiting challenge $challengeId...');

      final response = await supabaseClient.rpc(
        'exit_brand_challenge_self',
        params: {'p_challenge_id': challengeId},
      );

      final data = Map<String, dynamic>.from((response as Map?) ?? const {});
      print('🟢 BrandChallengeService: exit_brand_challenge_self response: $data');
      return data;
    } catch (e) {
      print('🔴 BrandChallengeService: Error exiting challenge: $e');
      return {
        'success': false,
        'error': 'CLIENT_ERROR',
        'message': 'Failed to exit challenge: ${e.toString()}',
      };
    }
  }

  /// Mark the brand challenge habit as done for today.
  Future<Map<String, dynamic>> completeBrandHabit(String challengeId) async {
    try {
      print(
        '🔵 BrandChallengeService: Completing brand habit for $challengeId...',
      );

      final response = await supabaseClient.rpc(
        'complete_brand_habit',
        params: {'p_challenge_id': challengeId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 BrandChallengeService: complete_brand_habit response: $data');
      return data;
    } catch (e) {
      print('🔴 BrandChallengeService: Error completing brand habit: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Something went wrong, try again',
      };
    }
  }

  /// Dismiss the challenge result modal.
  Future<void> dismissChallengeResult(String habitId) async {
    try {
      print(
        '🔵 BrandChallengeService: Dismissing challenge result for $habitId...',
      );

      await supabaseClient.rpc(
        'dismiss_challenge_result',
        params: {'p_habit_id': habitId},
      );

      print('🟢 BrandChallengeService: Challenge result dismissed');
    } catch (e) {
      print('🔴 BrandChallengeService: Error dismissing result: $e');
    }
  }

  /// React to a pulse post. Handles toggle + switch.
  Future<Map<String, dynamic>> reactToPulsePost({
    required String postId,
    required String reaction,
    String? currentReaction,
  }) async {
    try {
      print(
        '🔵 React to pulse: postId=$postId, reaction=$reaction, currentReaction=$currentReaction',
      );

      final response = await supabaseClient.rpc(
        'react_to_pulse_post',
        params: {'p_post_id': postId, 'p_reaction': reaction},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print(
        '✅ Backend response: success=${data['success']}, reaction=${data['reaction']}, reactions=${data['reactions']}',
      );
      if (data['success'] != true) throw Exception(data['code']);

      return {
        'success': true,
        'reaction': data['reaction'] as String?,
        'reactions': data['reactions'] as Map<String, dynamic>? ?? {},
      };
    } catch (e) {
      print('🔴 BrandChallengeService: Error reacting to pulse post: $e');
      return {'success': false, 'reaction': currentReaction};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SNAPS — Upload & Actions
  // ═══════════════════════════════════════════════════════════════════════

  /// Generate a signed URL for a snap's media.
  Future<String?> getSnapSignedUrl(
    String storagePath, {
    String bucket = 'snaps',
  }) async {
    try {
      final url = await supabaseClient.storage
          .from(bucket)
          .createSignedUrl(storagePath, 60);
      return url;
    } catch (e) {
      print('🔴 BrandChallengeService: Error generating signed URL: $e');
      return null;
    }
  }

  /// Upload snap media to Supabase Storage.
  Future<String?> uploadSnapMedia(
    File file,
    String userId, {
    required String challengeId,
    String bucket = 'snaps',
  }) async {
    try {
      final ext = file.path.endsWith('.mp4') ? 'mp4' : 'jpg';
      final contentType = ext == 'mp4' ? 'video/mp4' : 'image/jpeg';
      final storagePath =
          'challenges/$challengeId/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      print('🔵 BrandChallengeService: Uploading snap to $storagePath...');

      await supabaseClient.storage
          .from(bucket)
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      print('🟢 BrandChallengeService: Snap uploaded');
      return storagePath;
    } catch (e) {
      print('🔴 BrandChallengeService: Error uploading snap: $e');
      return null;
    }
  }

  /// Send a snap to the challenge community via RPC.
  /// Returns response data including snap_id, expires_at, snaps_today, snaps_remaining
  Future<Map<String, dynamic>?> sendChallengeSnap({
    required String challengeId,
    required String storagePath,
    String? caption,
  }) async {
    try {
      print('🔵 BrandChallengeService: Sending challenge snap...');

      final response = await supabaseClient.rpc(
        'send_brand_snap',
        params: {
          'p_challenge_id': challengeId,
          'p_storage_path': storagePath,
          'p_caption': caption,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] == true) {
        print('🟢 BrandChallengeService: Snap sent');
        // Extract all response fields including NEW snaps_today and snaps_remaining
        return {
          'snap_id': data['snap_id'],
          'expires_at': data['expires_at'],
          'snap_date': data['snap_date'],
          'snaps_today': data['snaps_today'],
          'snaps_remaining': data['snaps_remaining'],
        };
      }
      // Error case also has the limit info
      if (data['code'] == 'SNAP_LIMIT_REACHED') {
        return {
          'success': false,
          'code': 'SNAP_LIMIT_REACHED',
          'snaps_today': data['snaps_today'],
          'snaps_remaining': data['snaps_remaining'],
        };
      }
      return null;
    } catch (e) {
      print('🔴 BrandChallengeService: Error sending snap: $e');
      return null;
    }
  }

  /// Open a snap: records the view and returns the signed media URL + metadata.
  /// Now includes my_reaction field (null if user hasn't reacted)
  Future<Map<String, dynamic>?> viewBrandSnap(
    String snapId, {
    String bucket = 'brand-snaps',
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'view_brand_snap',
        params: {'p_snap_id': snapId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) {
        throw Exception(data['code']);
      }

      final sender =
          data['sender'] is Map
              ? Map<String, dynamic>.from(data['sender'] as Map)
              : const <String, dynamic>{};

      final signedUrl = await getSnapSignedUrl(
        data['storage_path'],
        bucket: bucket,
      );
      if (signedUrl == null) throw Exception('Failed to get signed URL');

      return {
        'signedUrl': signedUrl,
        'caption': data['caption'],
        'sender': sender,
        'sender_id': sender['id'] ?? data['sender_id'],
        'sender_display_name': sender['display_name'],
        'sender_avatar_key': sender['avatar_key'],
        'sender_photo_key': sender['photo_key'],
        'expires_at': data['expires_at'],
        'reactions': data['reactions'],
        'my_reaction': data['my_reaction'], // NEW: user's reaction (nullable)
      };
    } catch (e) {
      print('🔴 BrandChallengeService: Error viewing snap: $e');
      return null;
    }
  }

  /// Toggle a reaction on a snap via RPC.
  Future<Map<String, dynamic>?> reactToBrandSnap({
    required String snapId,
    required String reaction,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'react_to_brand_snap',
        params: {'p_snap_id': snapId, 'p_reaction': reaction},
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) throw Exception(data['code']);

      return {
        'added': data['added'],
        'reaction': data['reaction'],
        'reactions': data['reactions'],
      };
    } catch (e) {
      print('🔴 BrandChallengeService: Error toggling snap reaction: $e');
      return null;
    }
  }

  /// Remove your own snap via RPC.
  Future<Map<String, dynamic>> removeMyChallengeSnap(String snapId) async {
    try {
      print('🔵 BrandChallengeService: Removing snap $snapId...');

      final response = await supabaseClient.rpc(
        'delete_brand_snap',
        params: {'p_snap_id': snapId},
      );

      final data = Map<String, dynamic>.from(response as Map);

      // Immediately remove media from storage; do not wait for cleanup cron.
      final storagePath = data['storage_path'] as String?;
      if (data['success'] == true &&
          storagePath != null &&
          storagePath.isNotEmpty) {
        await supabaseClient.storage.from('brand-snaps').remove([storagePath]);
      }

      print('🟢 BrandChallengeService: delete_brand_snap response: $data');
      return data;
    } catch (e) {
      print('🔴 BrandChallengeService: Error removing snap: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Failed to remove snap: ${e.toString()}',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COUPONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Redeem a coupon via RPC.
  Future<Map<String, dynamic>> redeemCoupon(String couponId) async {
    try {
      print('🔵 BrandChallengeService: Redeeming coupon $couponId...');

      final response = await supabaseClient.rpc(
        'mark_coupon_used',
        params: {'p_coupon_id': couponId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 BrandChallengeService: mark_coupon_used response: $data');
      return data;
    } catch (e) {
      print('🔴 BrandChallengeService: Error redeeming coupon: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Failed to redeem coupon: ${e.toString()}',
      };
    }
  }

  /// Get the user's past completed/failed challenges (history).
  Future<List<Map<String, dynamic>>> getChallengeHistory(String userId) async {
    try {
      print(
        '🔵 BrandChallengeService: Fetching challenge history for $userId...',
      );

      final response = await supabaseClient.rpc(
        'get_challenge_history',
        params: {'p_user_id': userId},
      );

      if (response == null) return [];
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching history: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Remove a realtime channel subscription.
  Future<void> removeChannel(RealtimeChannel channel) async {
    try {
      await supabaseClient.removeChannel(channel);
    } catch (e) {
      print('🟡 BrandChallengeService: Error removing channel: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REWARDS & MILESTONES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all user's enrolled challenges with milestones and earned status.
  /// Call this on the Rewards tab/screen to show all challenges' rewards.
  Future<UserRewardsListModel> getMyRewards() async {
    try {
      print('🔵 BrandChallengeService: Fetching all my rewards...');

      final response = await supabaseClient.rpc('get_my_rewards');

      if (response == null || (response as List).isEmpty) {
        return UserRewardsListModel(challenges: []);
      }

      final model = UserRewardsListModel.fromJson(response);
      print(
        '🟢 BrandChallengeService: Fetched ${model.totalChallenges} challenges with rewards',
      );
      return model;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching my rewards: $e');
      return UserRewardsListModel(challenges: []);
    }
  }

  /// Get a single challenge's milestones with earned/locked status.
  /// Call this when user navigates into a challenge's dedicated rewards page.
  Future<ChallengeRewardsModel?> getChallengeRewards(String challengeId) async {
    try {
      print(
        '🔵 BrandChallengeService: Fetching rewards for challenge $challengeId...',
      );

      final response = await supabaseClient.rpc(
        'get_challenge_rewards',
        params: {'p_challenge_id': challengeId},
      );

      if (response == null) return null;

      final model = ChallengeRewardsModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      print(
        '🟢 BrandChallengeService: Fetched ${model.totalMilestones} milestones (${model.earnedCount} earned)',
      );
      return model;
    } catch (e) {
      print('🔴 BrandChallengeService: Error fetching challenge rewards: $e');
      return null;
    }
  }
}
