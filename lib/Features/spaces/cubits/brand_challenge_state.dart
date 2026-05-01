
import '../../../models/brand_challenge_models.dart';

abstract class BrandChallengeState {}

class BrandChallengeInitial extends BrandChallengeState {}

class BrandChallengeLoading extends BrandChallengeState {}

// Emitted as soon as header + journey load (above the fold)
class BrandChallengeAboveFoldLoaded extends BrandChallengeState {
  final ChallengeHeaderModel  header;
  final ChallengeJourneyModel journey;
  final bool isActiveMember;
  final int exitedDaysCompleted;
  final int exitedRewardsUnlocked;

  BrandChallengeAboveFoldLoaded({
    required this.header,
    required this.journey,
    this.isActiveMember = true,
    this.exitedDaysCompleted = 0,
    this.exitedRewardsUnlocked = 0,
  });
}

// Emitted when all 5 RPCs have returned
class BrandChallengeFullyLoaded extends BrandChallengeState {
  final ChallengeHeaderModel  header;
  final ChallengeJourneyModel journey;
  final bool isActiveMember;
  final int exitedDaysCompleted;
  final int exitedRewardsUnlocked;
  final PulsePostModel?       pulse;
  final ChallengeStoriesResponse stories;
  final List<BrandProductModel> products;
  final List<ChallengeCouponModel> coupons;
  final bool isSendingSnap; // NEW: tracks if a snap is currently uploading

  BrandChallengeFullyLoaded({
    required this.header,
    required this.journey,
    this.isActiveMember = true,
    this.exitedDaysCompleted = 0,
    this.exitedRewardsUnlocked = 0,
    required this.pulse,
    required this.stories,
    required this.products,
    required this.coupons,
    this.isSendingSnap = false,
  });

  // Copy with updated sending state
  BrandChallengeFullyLoaded copyWithSendingSnap(bool isSending) {
    return BrandChallengeFullyLoaded(
      header:        header,
      journey:       journey,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      pulse:         pulse,
      products:      products,
      coupons:       coupons,
      stories:       stories,
      isSendingSnap: isSending,
    );
  }



  // Copy with updated journey (after mark done)
  BrandChallengeFullyLoaded copyWithJourney(ChallengeJourneyModel j) {
    return BrandChallengeFullyLoaded(
      header:        header,
      journey:       j,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      pulse:         pulse,
      stories:       stories,
      products:      products,
      coupons:       coupons,
      isSendingSnap: isSendingSnap,
    );
  }

  // Generic copyWith for silent partial updates
  BrandChallengeFullyLoaded copyWith({
    ChallengeStoriesResponse? stories,
  }) {
    return BrandChallengeFullyLoaded(
      header:        header,
      journey:       journey,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      pulse:         pulse,
      stories:       stories ?? this.stories,
      products:      products,
      coupons:       coupons,
      isSendingSnap: isSendingSnap,
    );
  }

  // Copy with updated coupon (after mark as used)
  BrandChallengeFullyLoaded copyWithCouponUsed(String couponId) {
    return BrandChallengeFullyLoaded(
      header:        header,
      journey:       journey,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      pulse:         pulse,
      stories:       stories,
      products:      products,
      isSendingSnap: isSendingSnap,
      coupons: coupons.map((c) {
        if (c.id != couponId) return c;
        return ChallengeCouponModel(
          id: c.id,
          code: c.code,
          isUsed: true, // Mark used optimistically
          isExpired: c.isExpired,
          expiresAt: c.expiresAt,
          earnedAt: c.earnedAt,
          reward: c.reward,
          brand: c.brand,
        );
      }).toList(),
    );
  }

  // Copy with updated pulse reaction
  BrandChallengeFullyLoaded copyWithPulseReaction(String postId, String? reaction, [PulseReactions? newReactions]) {
    PulsePostModel? updatedPulse = pulse;
    if (updatedPulse != null && updatedPulse.id == postId) {
      PulseReactions updatedReactions = newReactions ?? updatedPulse.reactions;

      if (newReactions == null) {
        final oldReaction = updatedPulse.myReaction;
        if (oldReaction != reaction) {
          int newFire = updatedReactions.fire;
          int newFlex = updatedReactions.flex;
          int newHeart = updatedReactions.heart;

          if (oldReaction == 'fire') newFire = (newFire - 1).clamp(0, 999999);
          if (oldReaction == 'flex') newFlex = (newFlex - 1).clamp(0, 999999);
          if (oldReaction == 'heart') newHeart = (newHeart - 1).clamp(0, 999999);

          if (reaction == 'fire') newFire += 1;
          if (reaction == 'flex') newFlex += 1;
          if (reaction == 'heart') newHeart += 1;

          updatedReactions = PulseReactions(fire: newFire, flex: newFlex, heart: newHeart);
        }
      }

      updatedPulse = PulsePostModel(
        id:              updatedPulse.id,
        mediaUrl:        updatedPulse.mediaUrl,
        mediaType:       updatedPulse.mediaType,
        thumbnailUrl:    updatedPulse.thumbnailUrl,
        durationSeconds: updatedPulse.durationSeconds,
        caption:         updatedPulse.caption,
        postDate:        updatedPulse.postDate,
        productUrl:      updatedPulse.productUrl,
        reactions:       updatedReactions,
        myReaction:      reaction,
      );
    }

    return BrandChallengeFullyLoaded(
      header:        header,
      journey:       journey,
      isActiveMember: isActiveMember,
      exitedDaysCompleted: exitedDaysCompleted,
      exitedRewardsUnlocked: exitedRewardsUnlocked,
      products:      products,
      stories:       stories,
      coupons:       coupons,
      isSendingSnap: isSendingSnap,
      pulse:         updatedPulse,
    );
  }
}

class BrandChallengeError extends BrandChallengeState {
  final String message;
  BrandChallengeError(this.message);
}

// ── REWARDS STATES ──────────────────────────────────────────

class RewardsLoading extends BrandChallengeState {}

class AllRewardsLoaded extends BrandChallengeState {
  final UserRewardsListModel rewards;

  AllRewardsLoaded({required this.rewards});
}

class ChallengeRewardsLoaded extends BrandChallengeState {
  final ChallengeRewardsModel rewards;

  ChallengeRewardsLoaded({required this.rewards});
}

class RewardsError extends BrandChallengeState {
  final String message;
  RewardsError(this.message);
}
