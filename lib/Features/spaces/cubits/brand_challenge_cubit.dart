import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/brand_challenge_service.dart';
import '../../../models/brand_challenge_models.dart';
import 'brand_challenge_state.dart';

class BrandChallengeCubit extends Cubit<BrandChallengeState> {
  final BrandChallengeService _service;
  bool _isReactingPulse = false;
  final Map<String, String?> _lastQueuedReaction = {};
  final Map<String, String?> _lastSentReactionBase = {};
  final Map<String, Future<void>> _inFlightLoads = {};
  final Map<String, int> _latestRequestIdByChallenge = {};
  static final Map<String, _ChallengeCacheEntry> _memoryCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  BrandChallengeCubit(this._service) : super(BrandChallengeInitial());

  // ── LOAD SCREEN ──────────────────────────────────────────

  Future<void> loadChallenge(
    String challengeId, {
    bool forceRefresh = false,
  }) async {
    final inFlight = _inFlightLoads[challengeId];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final requestId = (_latestRequestIdByChallenge[challengeId] ?? 0) + 1;
    _latestRequestIdByChallenge[challengeId] = requestId;

    final loadFuture = _loadChallengeInternal(
      challengeId,
      forceRefresh: forceRefresh,
      requestId: requestId,
    );
    _inFlightLoads[challengeId] = loadFuture;

    try {
      await loadFuture;
    } finally {
      if (identical(_inFlightLoads[challengeId], loadFuture)) {
        _inFlightLoads.remove(challengeId);
      }
    }
  }

  Future<void> _loadChallengeInternal(
    String challengeId, {
    required bool forceRefresh,
    required int requestId,
  }) async {
    final cached = _memoryCache[challengeId];
    final hasFreshCache =
        !forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) <= _cacheTtl;

    if (hasFreshCache) {
      emit(cached.state.copyWithSendingSnap(false));
      unawaited(
        _loadChallengeFromNetwork(
          challengeId,
          emitLoading: false,
          requestId: requestId,
        ),
      );
      return;
    }

    await _loadChallengeFromNetwork(
      challengeId,
      emitLoading: true,
      requestId: requestId,
    );
  }

  bool _isLatestRequest(String challengeId, int requestId) {
    return _latestRequestIdByChallenge[challengeId] == requestId;
  }

  Future<void> _loadChallengeFromNetwork(
    String challengeId, {
    required bool emitLoading,
    required int requestId,
  }) async {
    if (!_isLatestRequest(challengeId, requestId)) return;

    if (emitLoading) {
      emit(BrandChallengeLoading());
    }

    // Step 1: load above-the-fold in parallel — show UI immediately
    final aboveFold = await Future.wait([
      _service.getChallengeHeader(challengeId),
      _service.getChallengeJourney(challengeId),
    ]);

    final header  = aboveFold[0] as ChallengeHeaderModel?;
    final journey = aboveFold[1] as ChallengeJourneyModel?;

    if (!_isLatestRequest(challengeId, requestId)) return;

    if (header == null || journey == null) {
      if (emitLoading) {
        emit(BrandChallengeError('Failed to load challenge'));
      }
      return;
    }

    final status = await _service.getChallengeUserStatus(challengeId);
    final memberStatus = _readString(status, const [
      'member_status',
      'memberStatus',
      'status',
    ])?.toLowerCase();
    final isExitedMember = memberStatus == 'left';
    final isActiveMember = !isExitedMember;
    final exitedDaysCompleted =
        _readInt(status, const [
          'days_completed',
          'daysCompleted',
          'total_logs',
          'totalLogs',
          'user_day',
          'userDay',
        ]) ??
        journey.progress.totalLogs;
    final exitedRewardsUnlocked =
        _readInt(status, const [
          'rewards_unlocked',
          'rewardsUnlocked',
          'earned_rewards',
          'earnedRewards',
          'rewards_earned',
        ]) ??
        _countUnlockedRewards(journey);

    final effectiveHeader = isExitedMember ? _asNotJoinedHeader(header) : header;
    final effectiveJourney = isExitedMember ? _asExitedJourney(journey) : journey;

    // Emit above-fold immediately so hero + milestone map appear
    if (emitLoading) {
      emit(
        BrandChallengeAboveFoldLoaded(
          header: effectiveHeader,
          journey: effectiveJourney,
          isActiveMember: isActiveMember,
          exitedDaysCompleted: exitedDaysCompleted,
          exitedRewardsUnlocked: exitedRewardsUnlocked,
        ),
      );
    }

    // Step 2: load below-the-fold in parallel — no blocking
    final belowFold = await Future.wait([
      _service.getChallengePulse(challengeId),
      _service.getChallengeStories(challengeId),
      _service.getChallengeProducts(challengeId),
      _service.getChallengeCoupons(challengeId),
    ]);

    if (!_isLatestRequest(challengeId, requestId)) return;

    final loadedPulse = belowFold[0] as PulsePostModel?;
    
    // Initialize reaction tracking state for this post
    if (loadedPulse != null) {
      _lastSentReactionBase[loadedPulse.id] = loadedPulse.myReaction;
      _lastQueuedReaction[loadedPulse.id] = loadedPulse.myReaction;
    }
    
    final loaded = BrandChallengeFullyLoaded(
      header:    effectiveHeader,
      journey:   effectiveJourney,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      pulse:     loadedPulse,
      stories:   belowFold[1] as ChallengeStoriesResponse,
      products:  belowFold[2] as List<BrandProductModel>,
      coupons:   belowFold[3] as List<ChallengeCouponModel>,
    );

    _memoryCache[challengeId] = _ChallengeCacheEntry(
      state: loaded,
      fetchedAt: DateTime.now(),
    );
    emit(loaded);
  }

  ChallengeHeaderModel _asEnrolledHeader(ChallengeHeaderModel h) {
    return ChallengeHeaderModel(
      id: h.id,
      title: h.title,
      durationDays: h.durationDays,
      startsAt: h.startsAt,
      endsAt: h.endsAt,
      isActive: h.isActive,
      bannerUrl: h.bannerUrl,
      brand: h.brand,
      habit: h.habit,
      stats: h.stats,
      myEnrollment: MyEnrollment(status: 'active', enrolledAt: DateTime.now()),
      daysLeft: h.daysLeft,
      myStats: h.myStats,
      heroConfig: h.heroConfig,
      milestones: h.milestones,
      rewardPoolText: h.rewardPoolText,
      titleSegments: h.titleSegments,
      descriptionSegments: h.descriptionSegments,
      challengeDescription: h.challengeDescription,
    );
  }

  void _markStateAsEnrolled(String challengeId) {
    final current = state;
    if (current is BrandChallengeAboveFoldLoaded && !current.header.isEnrolled) {
      emit(
        BrandChallengeAboveFoldLoaded(
          header: _asEnrolledHeader(current.header),
          journey: current.journey,
          isActiveMember: true,
          exitedDaysCompleted: current.exitedDaysCompleted,
          exitedRewardsUnlocked: current.exitedRewardsUnlocked,
        ),
      );
      return;
    }

    if (current is BrandChallengeFullyLoaded && !current.header.isEnrolled) {
      final updated = BrandChallengeFullyLoaded(
        header: _asEnrolledHeader(current.header),
        journey: current.journey,
        isActiveMember: true,
        exitedDaysCompleted: current.exitedDaysCompleted,
        exitedRewardsUnlocked: current.exitedRewardsUnlocked,
        pulse: current.pulse,
        stories: current.stories,
        products: current.products,
        coupons: current.coupons,
        isSendingSnap: current.isSendingSnap,
      );

      _memoryCache[challengeId] = _ChallengeCacheEntry(
        state: updated,
        fetchedAt: DateTime.now(),
      );
      emit(updated);
    }
  }

  ChallengeHeaderModel _asNotJoinedHeader(ChallengeHeaderModel h) {
    return ChallengeHeaderModel(
      id: h.id,
      title: h.title,
      durationDays: h.durationDays,
      startsAt: h.startsAt,
      endsAt: h.endsAt,
      isActive: h.isActive,
      bannerUrl: h.bannerUrl,
      brand: h.brand,
      habit: h.habit,
      stats: h.stats,
      myEnrollment: null,
      daysLeft: h.daysLeft,
      myStats: h.myStats,
      heroConfig: h.heroConfig,
      milestones: h.milestones,
      rewardPoolText: h.rewardPoolText,
      titleSegments: h.titleSegments,
      descriptionSegments: h.descriptionSegments,
      challengeDescription: h.challengeDescription,
    );
  }

  ChallengeJourneyModel _asExitedJourney(ChallengeJourneyModel j) {
    return ChallengeJourneyModel(
      progress: ChallengeProgress(
        currentStreak: 0,
        totalLogs: 0,
        userDay: 0,
        durationDays: j.progress.durationDays,
        doneToday: false,
        lastCompleted: null,
        progressPct: 0,
      ),
      milestones: j.milestones,
      energy: j.energy,
    );
  }

  int _countUnlockedRewards(ChallengeJourneyModel journey) {
    final earnedRewards = journey.milestones
        .expand((m) => m.rewards)
        .where((r) => r.earned)
        .length;
    if (earnedRewards > 0) return earnedRewards;
    return journey.milestones.where((m) => m.isDone).length;
  }

  int? _readInt(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  // ── LOAD MORE STORIES ──────────────────────────────────────
  Future<void> loadMoreStories(String challengeId) async {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) return;
    if (!current.stories.hasMore) return;

    final nextPage = current.stories.page + 1;
    final nextStories = await _service.getChallengeStories(
      challengeId,
      page: nextPage,
      limit: current.stories.limit,
    );

    if (state is BrandChallengeFullyLoaded) {
      emit((state as BrandChallengeFullyLoaded).copyWith(
        stories: current.stories.appendPage(nextStories),
      ));
    }
  }

  // SEND SNAP
  Future<String?> sendSnap({
    required String challengeId,
    required File imageFile,
    String? caption,
  }) async {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) return 'Challenge not loaded';
    
    // Set UI to loading state
    emit(current.copyWithSendingSnap(true));

    try {
      // 1. Get userId
      final userId = _service.supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 2. Upload photo to Supabase storage
      final storagePath = await _service.uploadSnapMedia(
        imageFile,
        userId,
        challengeId: challengeId,
        bucket: 'brand-snaps', // We store them in the brand bucket
      );

      if (storagePath == null) throw Exception('Failed to upload image');

      // 3. Register snap via RPC
      final result = await _service.sendChallengeSnap(
        challengeId: challengeId,
        storagePath: storagePath,
        caption:     caption,
      );

      if (result != null && result['success'] != false) {
        // Success: refresh everything to get the snap accurately, or re-run specific RPCs
        await loadChallenge(challengeId);
        // The loadChallenge sets isSendingSnap to false because it makes a new instance
        return null; // Success = no error
      } else {
        // Handle snap limit or error
        final code = result?['code'];
        final err = code == 'SNAP_LIMIT_REACHED'
            ? 'Daily snap limit reached for this challenge'
            : 'Failed to post snap';
        
        emit((state as BrandChallengeFullyLoaded).copyWithSendingSnap(false));
        return err;
      }
    } catch (e) {
      if (state is BrandChallengeFullyLoaded) {
        emit((state as BrandChallengeFullyLoaded).copyWithSendingSnap(false));
      }
      return 'Error uploading snap: $e';
    }
  }

  // ── MARK HABIT DONE ──────────────────────────────────────

  Future<Map<String, dynamic>> markHabitDone(String challengeId) async {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) {
      return {
        'success': false,
        'code': 'CHALLENGE_NOT_LOADED',
        'message': 'Challenge not loaded yet',
      };
    }

    // Optimistic update — flip doneToday immediately
    final optimisticJourney = ChallengeJourneyModel(
      progress: ChallengeProgress(
        currentStreak: current.journey.progress.currentStreak + 1,
        totalLogs:     current.journey.progress.totalLogs + 1,
        userDay:       current.journey.progress.userDay + 1,
        durationDays:  current.journey.progress.durationDays,
        doneToday:     true,
        lastCompleted: DateTime.now().toIso8601String(),
        progressPct:   current.journey.progress.progressPct,
      ),
      milestones: current.journey.milestones,
      energy:     current.journey.energy,
    );
    emit(current.copyWithJourney(optimisticJourney));

    try {
      final result = await _service.completeBrandHabit(challengeId);
      if (result['success'] == true) {
        // Refresh journey with real data from server
        final freshJourney = await _service.getChallengeJourney(challengeId);
        if (freshJourney != null && state is BrandChallengeFullyLoaded) {
          emit((state as BrandChallengeFullyLoaded).copyWithJourney(freshJourney));
        }
        return result;
      }

      // Revert optimistic state on backend rejection
      final freshJourney = await _service.getChallengeJourney(challengeId);
      if (freshJourney != null && state is BrandChallengeFullyLoaded) {
        emit((state as BrandChallengeFullyLoaded).copyWithJourney(freshJourney));
      } else if (state is BrandChallengeFullyLoaded) {
        emit((state as BrandChallengeFullyLoaded).copyWithJourney(current.journey));
      }
      return result;
    } catch (e) {
      // Revert optimistic state on unexpected failure
      if (state is BrandChallengeFullyLoaded) {
        emit((state as BrandChallengeFullyLoaded).copyWithJourney(current.journey));
      }
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Something went wrong, try again',
      };
    }
  }

  // Strategy: "last-wins" — the UI updates optimistically every tap,
  // but we only send ONE backend call: always reflecting the final state.
  // Any in-flight call is superseded by the latest reaction.
  //
  // This prevents the double-count bug that occurs when a queue sends
  // stale `currentReaction` values captured at tap time.

  void reactToPulse(
    String postId,
    String reaction,
    String? currentReaction,
  ) {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) return;

    // Compute the new desired reaction (toggle off if same)
    final desiredReaction = currentReaction == reaction ? null : reaction;

    // 1. Instant optimistic UI — always correct immediately
    emit(current.copyWithPulseReaction(postId, desiredReaction));

    // 2. Record what we want the backend to store (per-post)
    _lastQueuedReaction[postId] = desiredReaction;

    // 3. If a backend call is already in-flight, it will pick up
    //    _lastQueuedReaction when it finishes — no extra call needed
    if (!_isReactingPulse) {
      _isReactingPulse = true;
      _flushReactionToBackend(postId);
    }
  }

  Future<void> _flushReactionToBackend(String postId) async {
    // Keep looping until there is no more pending change
    while (true) {
      final targetReaction = _lastQueuedReaction[postId];

      try {
        // Send the final desired reaction to backend
        // The backend RPC handles toggle/switch/unreact correctly based on user's stored reaction
        final reactionToSend = targetReaction ?? '';
        final result = await _service.reactToPulsePost(
          postId: postId,
          reaction: reactionToSend,
          currentReaction: _lastSentReactionBase[postId],
        );

        if (result['success'] == true) {
          final freshReaction = result['reaction'] as String?;
          final Map<String, dynamic> rawReactions = result['reactions'] ?? {};
          _lastSentReactionBase[postId] = freshReaction;

          print('🟢 Reaction Success: postId=$postId, freshReaction=$freshReaction, rawReactions=$rawReactions');

          // Only update state if no new tap came in while we awaited
          if (_lastQueuedReaction[postId] == targetReaction && state is BrandChallengeFullyLoaded) {
            emit((state as BrandChallengeFullyLoaded).copyWithPulseReaction(
              postId,
              freshReaction,
              PulseReactions.fromJson(rawReactions),
            ));
          }
        }
      } catch (_) {
        // On error, if no new tap came in, revert to what backend knows
        if (_lastQueuedReaction[postId] == targetReaction && state is BrandChallengeFullyLoaded) {
          emit((state as BrandChallengeFullyLoaded).copyWithPulseReaction(
            postId, _lastSentReactionBase[postId],
          ));
        }
      }

      // If a new tap arrived while we were awaiting, loop and send again
      if (_lastQueuedReaction[postId] != targetReaction) {
        continue;
      }

      // No more pending changes — we're done
      break;
    }

    _isReactingPulse = false;
  }

  // ── ENROLL IN CHALLENGE ────────────────────────────────────

  Future<void> enrollInChallenge(String challengeId) async {
    final result = await _service.enrollInChallenge(challengeId);
    final isSuccess = result['success'] == true || result['already_enrolled'] == true;
    if (isSuccess) {
      _markStateAsEnrolled(challengeId);
      // Reload everything with fresh enrollment data
      await loadChallenge(challengeId, forceRefresh: true);
    }
  }

  Future<Map<String, dynamic>> exitChallenge(String challengeId) async {
    final result = await _service.exitChallengeSelf(challengeId);
    if (result['success'] == true) {
      await loadChallenge(challengeId, forceRefresh: true);
    }
    return result;
  }

  // ── REDEEM COUPON ──────────────────────────────────────────

  Future<void> redeemCoupon(String couponId) async {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) return;

    // Optimistic update
    emit(current.copyWithCouponUsed(couponId));

    // Call service
    final result = await _service.redeemCoupon(couponId);
    if (result['success'] != true) {
      // If error, we should ideally revert, but a simple reload works well
      // OR we can just restore the old state
      emit(current);
    }
  }

  // ── REFRESH (pull to refresh) — shows loading spinner ───────
  Future<void> refresh(String challengeId) =>
      loadChallenge(challengeId, forceRefresh: true);

  // ── SILENT REFRESH after snap viewer — no loading flash ──────
  // Only refreshes the stories (the only thing that changes after viewing)
  Future<void> silentRefreshStories(String challengeId) async {
    final current = state;
    if (current is! BrandChallengeFullyLoaded) return;
    try {
      final freshStories = await _service.getChallengeStories(challengeId);
      if (state is BrandChallengeFullyLoaded) {
        emit((state as BrandChallengeFullyLoaded).copyWith(stories: freshStories));
      }
    } catch (_) {
      // Silent — ignore errors, keep showing current state
    }
  }

  // ── REWARDS ──────────────────────────────────────────────────
  /// Load all user's enrolled challenges with their milestones.
  /// Call this on the Rewards/Milestones main screen.
  Future<void> loadAllRewards() async {
    emit(RewardsLoading());
    try {
      final rewards = await _service.getMyRewards();
      emit(AllRewardsLoaded(rewards: rewards));
    } catch (e) {
      print('🔴 BrandChallengeCubit: Error loading all rewards: $e');
      emit(RewardsError('Failed to load rewards: ${e.toString()}'));
    }
  }

  /// Load a single challenge's milestones and rewards.
  /// Call this when user navigates to a specific challenge's rewards page.
  Future<void> loadChallengeRewards(String challengeId) async {
    emit(RewardsLoading());
    try {
      final rewards = await _service.getChallengeRewards(challengeId);
      if (rewards != null) {
        emit(ChallengeRewardsLoaded(rewards: rewards));
      } else {
        emit(RewardsError('Challenge rewards not found'));
      }
    } catch (e) {
      print('🔴 BrandChallengeCubit: Error loading challenge rewards: $e');
      emit(RewardsError('Failed to load challenge rewards: ${e.toString()}'));
    }
  }
}

class _ChallengeCacheEntry {
  final BrandChallengeFullyLoaded state;
  final DateTime fetchedAt;

  _ChallengeCacheEntry({
    required this.state,
    required this.fetchedAt,
  });
}
