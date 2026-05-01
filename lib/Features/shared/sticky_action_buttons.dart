import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/image_cache_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../profile/profile_popup.dart';
import '../../gen/assets.gen.dart';
import '../qr/qr_scanner_view.dart';
import '../couple/cubit/spaces_cubit.dart';
import '../couple/cubit/spaces_state.dart';
import '../spaces/screens/rewards_screen.dart';
import '../../models/space_model.dart';
import '../profile/cubit/profile_cubit.dart';
import '../activity/cubit/activity_badge_cubit.dart';

enum SpaceType { solo, couple, group }

/// Full-width Instagram-style app bar
class StickyActionButtons extends StatefulWidget {
  final SpaceType spaceType;
  final ProfileModel profile;

  /// The resolved display URL — real photo takes priority over preset avatar.
  /// Pass `profileState.displayUrl` from [ProfileLoaded].
  final String? displayUrl;
  final ScrollController scrollController;

  /// When true, the app bar uses a darker blended style to merge into
  /// a dark hero/header background.
  final bool blendWithDarkHeader;

  const StickyActionButtons({
    super.key,
    required this.spaceType,
    required this.profile,
    required this.displayUrl,
    required this.scrollController,
    this.blendWithDarkHeader = false,
  });

  @override
  State<StickyActionButtons> createState() => _StickyActionButtonsState();
}

class _StickyActionButtonsState extends State<StickyActionButtons>
    with TickerProviderStateMixin {
  Color get _accentColor {
    switch (widget.spaceType) {
      case SpaceType.couple:
        return const Color(0xFFFF6B6B);
      case SpaceType.group:
        return const Color(0xFF4ECDC4);
      case SpaceType.solo:
        return const Color(0xFF6B6BE0);
    }
  }

  Future<void> _showProfilePopup(BuildContext context) async {
    // displayUrl already has photo priority (photo ?? avatar)
    String? finalDisplayUrl = widget.displayUrl;
    if (finalDisplayUrl == null && widget.profile.avatarId != null) {
      finalDisplayUrl = await context.read<ProfileService>().getAvatarUrlById(
        widget.profile.avatarId!,
      );
    }
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final userEmail = currentUser?.email ?? 'No email';

    final tempUser = UserModel(
      id: widget.profile.id,
      email: userEmail,
      displayName: widget.profile.displayName,
      avatarUrl: finalDisplayUrl,
      createdAt: widget.profile.updatedAt,
    );

    if (context.mounted) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder:
            (context) => Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: ProfilePopup(
                user: tempUser,
                profile: widget.profile,
                // Pass the photo URL separately so ProfilePopup shows it correctly
                avatarUrl: widget.profile.hasPhoto ? null : finalDisplayUrl,
                photoUrl: widget.profile.hasPhoto ? finalDisplayUrl : null,
                onEditAvatar: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRouter.onboarding);
                },
                onScanQR: () => _showSpaceSelectorAndScan(context),
              ),
            ),
      );
      if (result == true && context.mounted) {
        // Only reload if user actually made changes (result is true)
        // result is only true if ProfilePopup saved changes
        context.read<ProfileCubit>().loadProfile();
      }
    }
  }

  void _showSpaceSelectorAndScan(BuildContext context) async {
    final spacesState = context.read<SpacesCubit>().state;
    if (spacesState is! SpacesLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while spaces are loading...'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }
    final List<SpaceModel> spaces =
        widget.spaceType == SpaceType.couple
            ? spacesState.coupleSpaces
            : spacesState.groupSpaces;
    if (spaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No ${widget.spaceType.name} spaces found. Create one first!',
          ),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
      return;
    }

    // If there's only one space, skip the selector and go straight to scanner
    final SpaceModel selectedSpace;
    if (spaces.length == 1) {
      selectedSpace = spaces.first;
    } else {
      final picked = await showDialog<SpaceModel>(
        context: context,
        builder: (context) => _SpaceSelectorDialog(spaces: spaces),
      );
      if (picked == null || !context.mounted) return;
      selectedSpace = picked;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerView(spaceId: selectedSpace.id),
      ),
    );
    if (result != null && result['success'] == true && context.mounted) {
      context.read<SpacesCubit>().loadSpaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.profile.displayName ?? 'User';
    final bool useDarkBlend = widget.blendWithDarkHeader;
    final Color titleColor =
      useDarkBlend
          ? AppColors.midnightPrimaryPale.withValues(alpha: 0.94)
          : AppTheme.onBackground;
    final Color actionChipColor =
      useDarkBlend
          ? AppColors.midnightPrimary.withValues(alpha: 0.24)
          : Colors.black.withValues(alpha: 0.06);
    final Color svgColor =
      useDarkBlend
          ? AppColors.midnightPrimaryPale.withValues(alpha: 0.95)
          : AppTheme.onBackground;
    final Color avatarBorderColor =
      useDarkBlend
          ? AppColors.midnightPrimaryPale.withValues(alpha: 0.52)
          : _accentColor.withValues(alpha: 0.35);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: useDarkBlend ? Colors.transparent : AppTheme.background,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "SPACE",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: 1.2,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showProfilePopup(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarBorderColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child:
                      widget.displayUrl != null
                          ? CachedNetworkImage(
                            imageUrl: widget.displayUrl!,
                            fit: BoxFit.cover,
                            cacheManager: ImageCacheService().cacheManager,
                            httpHeaders: const {
                              'Accept': 'image/*',
                              'Connection': 'keep-alive',
                            },
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    _buildFallbackAvatar(userName),
                          )
                          : _buildFallbackAvatar(userName),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBellWithBadge(context),
                const SizedBox(width: 4),
                _buildRewardsButton(context),
                if (widget.spaceType == SpaceType.couple ||
                    widget.spaceType == SpaceType.group) ...[
                  const SizedBox(width: 4),
                  _buildIconBtn(
                    svgAsset: Assets.svg.scandashedRegular,
                    actionChipColor: actionChipColor,
                    svgColor: svgColor,
                    onTap: () => _showSpaceSelectorAndScan(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bell icon with a red badge showing pending invite count.
  Widget _buildBellWithBadge(BuildContext context) {
    final bool useDarkBlend = widget.blendWithDarkHeader;
    final Color actionChipColor =
      useDarkBlend
        ? AppColors.midnightPrimary.withValues(alpha: 0.24)
        : Colors.black.withValues(alpha: 0.06);
    final Color svgColor =
      useDarkBlend
        ? AppColors.midnightPrimaryPale.withValues(alpha: 0.95)
        : AppTheme.onBackground;

    return BlocBuilder<ActivityBadgeCubit, ActivityBadgeState>(
      builder: (context, badgeState) {
        final count = badgeState.count;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/activity');
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: actionChipColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      Assets.svg.bellRegular,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardsButton(BuildContext context) {
    final bool useDarkBlend = widget.blendWithDarkHeader;
    final Color actionChipColor =
        useDarkBlend
            ? AppColors.midnightPrimary.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.06);
    final Color iconColor =
        useDarkBlend
            ? AppColors.midnightPrimaryPale.withValues(alpha: 0.95)
            : AppTheme.onBackground;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AllRewardsScreen()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: actionChipColor, shape: BoxShape.circle),
        child: Center(
          child: Icon(Icons.workspace_premium_rounded, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildIconBtn({
    required String svgAsset,
    required Color actionChipColor,
    required Color svgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: actionChipColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            svgAsset,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String userName) {
    return Container(
      color: _accentColor,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SpaceSelectorDialog extends StatelessWidget {
  final List<SpaceModel> spaces;
  const _SpaceSelectorDialog({required this.spaces});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Space',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 20),
            ...spaces.map(
              (space) => GestureDetector(
                onTap: () => Navigator.pop(context, space),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    space.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
