import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_helpers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../services/snap_service.dart';
import '../../../models/snap_model.dart';
import '../../../models/snap_tray_model.dart';
import '../../../models/snap_sender_response.dart';
import 'snap_state.dart';

/// 📸 SNAP CUBIT — Tray-based architecture
///
/// Flow:
///   1. loadSnaps(spaceId) → calls get_space_snaps_tray → emits SnapTrayLoaded
///   2. UI shows one bubble per sender in the tray
///   3. User taps bubble → loadSenderSnaps() → returns snaps for the viewer
///   4. Viewer calls viewSnap() fire-and-forget + reactToSnap()
class SnapCubit extends Cubit<SnapState> {
  final SnapService _snapService;
  final String userId;
  static const Duration _trayCacheTtl = Duration(seconds: 45);
  static final Map<String, _SenderSnapsCacheEntry> _senderSnapsCache = {};

  static const Map<String, dynamic> _emptyViewersPage = {
    'viewers': <Map<String, dynamic>>[],
    'view_count': 0,
    'has_more': false,
    'next_cursor': null,
    'success': false,
  };

  String? _activeSpaceId;
  String? get activeSpaceId => _activeSpaceId;
  bool _isHomeTray = false;
  bool get isHomeTray => _isHomeTray;

  SnapTrayResponse? _homeTrayCache;
  DateTime? _homeTrayCachedAt;
  final Map<String, SnapTrayResponse> _spaceTrayCache = {};
  final Map<String, DateTime> _spaceTrayCachedAt = {};

  // ── Signed-URL cache: snapId → { url, expiresAt (midnight) } ──
  final Map<String, _CachedUrl> _urlCache = {};

  SnapCubit(this._snapService, {required this.userId}) : super(SnapInitial());

  /// Returns the DateTime of the next midnight in local time.
  static DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
  }

  /// Whether a cached URL is still valid (before midnight).
  bool _isCacheValid(_CachedUrl cached) =>
      DateTime.now().isBefore(cached.expiresAt);

  bool _isTrayFresh(DateTime? cachedAt) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < _trayCacheTtl;
  }

  String _senderSnapsCacheKey({
    String? spaceId,
    String? challengeId,
    required String senderId,
  }) {
    final contextType = challengeId != null ? 'challenge' : 'space';
    final contextId = challengeId ?? spaceId ?? 'unknown';
    return '$userId|$contextType|$contextId|$senderId';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD TRAY
  // ═══════════════════════════════════════════════════════════════════════

  /// Load the snap tray for a space — one bubble per sender.
  Future<void> loadSnaps(String spaceId, {bool forceRefresh = false}) async {
    _activeSpaceId = spaceId;

    if (!forceRefresh &&
        _spaceTrayCache.containsKey(spaceId) &&
        _isTrayFresh(_spaceTrayCachedAt[spaceId])) {
      if (!isClosed) {
        emit(
          SnapTrayLoaded(
            trayResponse: _spaceTrayCache[spaceId]!,
            spaceId: spaceId,
          ),
        );
      }
      return;
    }

    // Only show spinner on first load
    if (state is! SnapTrayLoaded) emit(SnapLoading());
    try {
      final trayResponse = await _snapService.getSpaceSnapsTray(spaceId);
      _spaceTrayCache[spaceId] = trayResponse;
      _spaceTrayCachedAt[spaceId] = DateTime.now();
      if (!isClosed) {
        emit(SnapTrayLoaded(trayResponse: trayResponse, spaceId: spaceId));
      }
    } catch (e) {
      if (!isClosed) emit(SnapError(message: userMessage(e), spaceId: spaceId));
    }
  }

  /// Silent refresh — keeps current tray visible.
  Future<void> refreshSnaps() async {
    if (_isHomeTray) {
      try {
        final trayResponse = await _snapService.getHomeTray();
        _homeTrayCache = trayResponse;
        _homeTrayCachedAt = DateTime.now();
        if (!isClosed) {
          emit(SnapTrayLoaded(trayResponse: trayResponse, spaceId: 'home'));
        }
      } catch (_) {}
      return;
    }
    if (_activeSpaceId == null) return;
    try {
      final trayResponse = await _snapService.getSpaceSnapsTray(
        _activeSpaceId!,
      );
      _spaceTrayCache[_activeSpaceId!] = trayResponse;
      _spaceTrayCachedAt[_activeSpaceId!] = DateTime.now();
      if (!isClosed) {
        emit(
          SnapTrayLoaded(trayResponse: trayResponse, spaceId: _activeSpaceId!),
        );
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD HOME TRAY — aggregated cross-space story tray
  // ═══════════════════════════════════════════════════════════════════════

  /// Load the home snap tray — one bubble per sender across all spaces.
  Future<void> loadHomeTray({bool forceRefresh = false}) async {
    _isHomeTray = true;
    _activeSpaceId = null;

    if (!forceRefresh && _homeTrayCache != null && _isTrayFresh(_homeTrayCachedAt)) {
      if (!isClosed) {
        emit(SnapTrayLoaded(trayResponse: _homeTrayCache!, spaceId: 'home'));
      }
      return;
    }

    if (state is! SnapTrayLoaded) emit(SnapLoading());
    try {
      final trayResponse = await _snapService.getHomeTray();
      _homeTrayCache = trayResponse;
      _homeTrayCachedAt = DateTime.now();
      if (!isClosed) {
        emit(SnapTrayLoaded(trayResponse: trayResponse, spaceId: 'home'));
      }
    } catch (e) {
      if (!isClosed) emit(SnapError(message: userMessage(e), spaceId: 'home'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD SENDER SNAPS — called when user taps a story bubble
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads all snaps from a specific sender. Returns null on error.
  /// The stories viewer uses this to display per-sender snaps.
  Future<SenderSnapsResult?> loadSenderSnaps({
    String? spaceId,
    String? challengeId,
    required String senderId,
    SnapSenderInfo? knownSender,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _senderSnapsCacheKey(
      spaceId: spaceId,
      challengeId: challengeId,
      senderId: senderId,
    );

    if (!forceRefresh) {
      final cached = _senderSnapsCache[cacheKey];
      if (cached != null && _isTrayFresh(cached.cachedAt)) {
        return cached.result;
      }
    }

    try {
      final result = await _snapService.fetchSenderSnaps(
        spaceId: spaceId,
        challengeId: challengeId,
        senderId: senderId,
        knownSender: knownSender,
      );

      _senderSnapsCache[cacheKey] = _SenderSnapsCacheEntry(
        result: result,
        cachedAt: DateTime.now(),
      );

      return result;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error loading sender snaps', error: e);
      return null;
    }
  }

  void clearSenderSnapsCache({
    String? senderId,
    String? spaceId,
    String? challengeId,
  }) {
    if (senderId == null && spaceId == null && challengeId == null) {
      _senderSnapsCache.clear();
      return;
    }

    _senderSnapsCache.removeWhere((key, _) {
      final senderMatch = senderId == null || key.endsWith('|$senderId');
      final contextMatch =
          (spaceId == null || key.contains('|space|$spaceId|')) &&
          (challengeId == null || key.contains('|challenge|$challengeId|'));
      return senderMatch && contextMatch;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SEND SNAP
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> sendSnap({
    required String spaceId,
    required File imageFile,
    String? habitId,
    String? caption,
  }) async {
    _activeSpaceId = spaceId;

    SnapTrayResponse? previousTray;
    if (state is SnapTrayLoaded) {
      previousTray = (state as SnapTrayLoaded).trayResponse;
    } else if (state is SnapError) {
      previousTray = (state as SnapError).previousTray;
    }
    final emptyTray = SnapTrayResponse(
      tray: [],
      iPostedToday: false,
      totalActiveSnaps: 0,
      unseenCount: 0,
    );
    emit(
      SnapSending(trayResponse: previousTray ?? emptyTray, spaceId: spaceId),
    );

    try {
      // 1. Upload to Storage
      final storagePath = await _snapService.uploadSnapImage(
        imageFile: imageFile,
        spaceId: spaceId,
      );

      // 2. Create snap row via RPC
      final result = await _snapService.sendSnap(
        spaceId: spaceId,
        storagePath: storagePath,
        habitId: habitId,
        caption: caption,
      );
      final success = result['success'] == true;
      if (!success) {
        await _snapService.deleteFromStorage(storagePath);
        final msg = result['message'] ?? 'Failed to send snap';
        if (!isClosed) {
          emit(
            SnapError(
              message: msg,
              previousTray: previousTray,
              spaceId: spaceId,
            ),
          );
        }
        return false;
      }

      // 3. Refresh tray
      final trayResponse = await _snapService.getSpaceSnapsTray(spaceId);
      clearSenderSnapsCache(spaceId: spaceId);
      if (!isClosed) {
        emit(SnapSent(trayResponse: trayResponse, spaceId: spaceId));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          SnapError(
            message: userMessage(e),
            previousTray: previousTray,
            spaceId: spaceId,
          ),
        );
      }
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  VIEW SNAP — fire and forget (records view + returns signed URL)
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a signed URL for viewing a snap.
  /// - Own snaps: signed directly from storagePath.
  /// - Others: calls view_snap RPC; cached until midnight.
  Future<String?> viewSnap({
    required String snapId,
    required String storagePath,
    required bool isMine,
    bool isChallengeSnap = false,
  }) async {
    // ── Check cache first ──
    final cached = _urlCache[snapId];
    if (cached != null && _isCacheValid(cached)) {
      // Fire-and-forget the view RPC in background for non-own snaps
      if (!isMine) {
        final viewCall = isChallengeSnap
            ? _snapService.viewBrandSnap(snapId)
            : _snapService.viewSnap(snapId);
        viewCall.catchError((_) => <String, dynamic>{});
      }
      return cached.url;
    }

    try {
      String? signedUrl;
      final bucket = isChallengeSnap ? 'brand-snaps' : 'habit-snaps';

      if (isMine) {
        signedUrl = await _snapService.getSnapImageUrl(
          storagePath,
          bucket: bucket,
        );
      } else {
        // Fire the view RPC — but don't block on its result for the URL
        final viewCall = isChallengeSnap
            ? _snapService.viewBrandSnap(snapId)
            : _snapService.viewSnap(snapId);
        viewCall.catchError((_) => <String, dynamic>{});
        signedUrl = await _snapService.getSnapImageUrl(
          storagePath,
          bucket: bucket,
        );
      }

      // ── Store in cache until midnight ──
      _urlCache[snapId] = _CachedUrl(
        url: signedUrl,
        expiresAt: _nextMidnight(),
      );

      return signedUrl;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error viewing snap', error: e);
      return null;
    }
  }

  /// Clears the URL cache — call when snaps are refreshed at midnight.
  void clearUrlCache() => _urlCache.clear();

  // ═══════════════════════════════════════════════════════════════════════
  //  GET SNAP VIEWERS (PAGINATED) — supports both habit & brand snaps
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch a page of snap viewers with optional cursor for pagination.
  /// 
  /// Params:
  ///   - snapId: snap to fetch viewers for
  ///   - isBrandSnap: true to fetch from brand_challenge_snaps table, false for habit_snaps (default)
  ///   - limit: page size (default 20)
  ///   - afterViewedAt: cursor for next page (null for first page)
  /// 
  /// Returns: {
  ///   viewers: [...],
  ///   view_count: total,
  ///   has_more: bool,
  ///   next_cursor: timestamp or null,
  ///   success: bool,
  /// }
  Future<Map<String, dynamic>> getSnapViewers(
    String snapId, {
    bool isBrandSnap = false,
    int limit = 20,
    String? afterViewedAt,
  }) async {
    try {
      return await _snapService.getSnapViewers(
        snapId,
        isBrandSnap: isBrandSnap,
        limit: limit,
        afterViewedAt: afterViewedAt,
      );
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error fetching snap viewers', error: e);
      return _emptyViewersPage;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REACT
  // ═══════════════════════════════════════════════════════════════════════

  /// React to a snap — called from the stories viewer.
  /// Returns the server response for optimistic UI updates in the viewer.
  Future<Map<String, dynamic>?> reactToSnap(
    String snapId,
    SnapReaction reaction,
    {
    bool isChallengeSnap = false,
  }
  ) async {
    try {
      final result = await _snapService.reactToSnap(
        snapId: snapId,
        reaction: reaction.value,
        isChallengeSnap: isChallengeSnap,
      );
      return result;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error reacting to snap', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  DELETE
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> deleteSnap(
    String snapId, {
    bool isChallengeSnap = false,
  }) async {
    try {
      final result = await _snapService.deleteSnap(
        snapId,
        isChallengeSnap: isChallengeSnap,
      );
      final success = result['success'] == true;
      if (success) {
        clearSenderSnapsCache();
        // Refresh tray to remove the deleted snap's sender if no snaps left
        await refreshSnaps();
      }
      return success;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error deleting snap', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  REPORT
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> reportSnap({
    required String snapId,
    required String reason,
    String? details,
  }) async {
    try {
      final result = await _snapService.reportSnap(
        snapId: snapId,
        reason: reason,
        details: details,
      );
      return result['success'] == true;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error reporting snap', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BLOCK / UNBLOCK
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> blockUser(String blockedId) async {
    try {
      final result = await _snapService.blockUser(blockedId);
      if (result['success'] == true) {
        clearSenderSnapsCache();
        await refreshSnaps();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error blocking user', error: e);
      return false;
    }
  }

  Future<bool> unblockUser(String blockedId) async {
    try {
      final result = await _snapService.unblockUser(blockedId);
      if (result['success'] == true) {
        clearSenderSnapsCache();
        await refreshSnaps();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error unblocking user', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  GET MY BLOCKS
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getMyBlocks() async {
    try {
      return await _snapService.getMyBlocks();
    } catch (e) {
      AppLogger.error('SnapCubit', 'Error fetching block list', error: e);
      return [];
    }
  }
}

/// Cached URL entry: value object for URL cache.
class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl({required this.url, required this.expiresAt});
}

class _SenderSnapsCacheEntry {
  final SenderSnapsResult result;
  final DateTime cachedAt;

  _SenderSnapsCacheEntry({required this.result, required this.cachedAt});
}
