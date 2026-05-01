import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../services/image_cache_service.dart';
import 'cubit/activity_cubit.dart';
import 'cubit/activity_state.dart';
import 'cubit/activity_badge_cubit.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ActivityCubit>().loadAll();
    // Mark as seen so the red dot disappears
    context.read<ActivityBadgeCubit>().markAsSeen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 6. NAVIGATION AFTER ACCEPTING
  void navigateToSpace(String spaceId, String spaceType) {
    // Navigate back to home/main navigation
    // The spaces will be loaded automatically there
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => route.isFirst,
    );
  }

  // WRAPPER TO REFRESH BADGE AFTER ACTIONS
  Future<void> _performAction(Future<void> Function() action) async {
    HapticFeedback.mediumImpact();
    await action();
    if (mounted) {
      context.read<ActivityBadgeCubit>().refreshBadgeCount();
    }
  }

  // 5. CONFLICT WARNING DIALOG
  Future<void> _handleConflict(
    BuildContext context,
    ActivityState state,
  ) async {
    final cubit = context.read<ActivityCubit>();
    final item = state.conflictItem!;
    final isOwner = state.conflictIsOwner == true;
    final message = state.conflictMessage ?? 'Conflict detected';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Text('⚠️'),
                const SizedBox(width: 8),
                Text(
                  'Heads up',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onBackground,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwner ? Colors.red : Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isOwner ? 'Delete my space' : 'Leave current space',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (state.conflictType == 'join_request') {
        cubit.acceptJoinRequest(item, force: true);
      } else {
        cubit.acceptInvite(item, force: true);
      }
      if (mounted) context.read<ActivityBadgeCubit>().refreshBadgeCount();
    }
    cubit.clearConflict();
  }

  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityCubit, ActivityState>(
      listener: (context, state) {
        // Handle Errors / Toasts
        if (state.errorMessage != null) {
          if (state.errorMessage!.startsWith('SUCCESS_MSG:')) {
            showSuccessSnackbar(state.errorMessage!.substring(12));
          } else {
            showToast(state.errorMessage!);
          }
        }

        // Handle Conflicts
        if (state.conflictItem != null) {
          _handleConflict(context, state);
        }

        // Handle Auto-Navigation on Join
        if (state.joinedSpaceId != null && state.joinedSpaceType != null) {
          navigateToSpace(state.joinedSpaceId!, state.joinedSpaceType!);
          // Reset navigation state to prevent double firing
          context.read<ActivityCubit>().resetNavigation();
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == ActivityStatus.loading &&
            state.forYouItems.isEmpty &&
            state.sentRequests.isEmpty;

        // HIGH-END "BILLION DOLLAR" DESIGN
        // Unified white background, crisp typography, segmented tabs
        return Scaffold(
          backgroundColor:
              AppTheme.background, // Match Solo Dashboard (Light Grey)
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── BILLION DOLLAR HEADER ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12,
                  ), // Reduced padding
                  child: Row(
                    children: [
                      // Circular Back Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 36,
                          height: 36, // Slightly smaller
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surface, // Start white on grey bg
                            border: Border.all(
                              color: AppTheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: AppTheme.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Large Title
                      Text(
                        'Activity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, // Compact title
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── SEGMENTED CONTROL TABS ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 44, // sleek height
                  decoration: BoxDecoration(
                    color: AppTheme.surface, // White container
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      // We have White Track. Let's do a soft tint Thumb or Brand Thumb.
                      // Let's go with Brand Primary for active text, and a light tint bg.
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primaryColor, // Active color
                    unselectedLabelColor: AppTheme.onSurfaceVariant,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: const [Tab(text: 'For You'), Tab(text: 'Sent')],
                  ),
                ),

                const SizedBox(height: 12), // Reduced Gap
                // ── CONTENT ──
                Expanded(
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          )
                          : TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildForYouTab(state),
                              _buildSentTab(state),
                            ],
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Removed _buildAppBar as it is now integrated into body

  Widget _buildForYouTab(ActivityState state) {
    // 1. Action Needed
    final actionNeeded = state.forYouItems;

    // 2. Recently Accepted
    final recentlyAcceptedRequests = state.sentRequests.where(
      (e) => e['status'] == 'accepted',
    );

    final recentlyAcceptedInvites = state.sentInvites.where(
      (e) => e['status'] == 'accepted',
    );

    final recentlyAccepted = [
      ...recentlyAcceptedRequests,
      ...recentlyAcceptedInvites,
    ];

    if (actionNeeded.isEmpty && recentlyAccepted.isEmpty) {
      return _buildForYouEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        40,
      ), // Tighter top padding (4px)
      physics: const BouncingScrollPhysics(),
      children: [
        if (actionNeeded.isNotEmpty) ...[
          _buildSectionHeader('PENDING REQUESTS', count: actionNeeded.length),
          ...actionNeeded.map((item) {
            if (item['_type'] == 'incoming_request') {
              return _buildIncomingRequestCard(context, item);
            } else {
              return _buildIncomingInviteCard(context, item);
            }
          }),
          const SizedBox(height: 16), // Reduced section gap
        ],

        if (recentlyAccepted.isNotEmpty) ...[
          _buildSectionHeader('RECENT ACTIVITY'),
          ...recentlyAccepted.map((item) => _buildRecentlyAcceptedItem(item)),
        ],
      ],
    );
  }

  Widget _buildSentTab(ActivityState state) {
    final visibleRequests = state.sentRequests;
    final visibleInvites = state.sentInvites;

    if (visibleRequests.isEmpty && visibleInvites.isEmpty) {
      return _buildSentEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        if (visibleRequests.isNotEmpty) ...[
          _buildSectionHeader('REQUESTS SENT'),
          ...visibleRequests.map((item) {
            return _buildSentItemCard(context, item, isInvite: false);
          }),
          const SizedBox(height: 16),
        ],

        if (visibleInvites.isNotEmpty) ...[
          _buildSectionHeader('INVITES SENT'),
          ...visibleInvites.map((item) {
            return _buildSentItemCard(context, item, isInvite: true);
          }),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8), // Reduced bottom
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, // Smaller, tighter
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // CARD BUILDERS
  // ════════════════════════════════════════════════

  // 3.2 Card type A — Incoming join request
  Widget _buildIncomingRequestCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                url:
                    item['requester_photo_key'] ?? item['requester_avatar_key'],
                isPremium: item['requester_is_premium'] == true,
                size: 52,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.onBackground,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: '${item['requester_name']} ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'wants to join ',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: '${item['space_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Meta info row
                    Row(
                      children: [
                        _buildTag(
                          label: (item['space_type'] as String).toUpperCase(),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${_timeAgo(item['created_at'])}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    if (item['message'] != null &&
                        (item['message'] as String).isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '"${item['message']}"',
                          style: GoogleFonts.plusJakartaSans(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Accept',
                  isPrimary: true,
                  onPressed:
                      () => _performAction(
                        () => context.read<ActivityCubit>().acceptJoinRequest(
                          item,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Decline',
                  isPrimary: false,
                  onPressed:
                      () => _performAction(
                        () => context.read<ActivityCubit>().declineJoinRequest(
                          item,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3.3 Card type B — Incoming invite
  Widget _buildIncomingInviteCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    return _BaseCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                url:
                    item['invited_by_photo_key'] ??
                    item['invited_by_avatar_key'],
                isPremium: item['invited_by_is_premium'] == true,
                size: 52,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.onBackground,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: '${item['invited_by_name']} ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'invited you to ',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: '${item['space_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['member_count']} members',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${_timeAgo(item['created_at'])}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Join Space',
                  isPrimary: true,
                  onPressed:
                      () => _performAction(
                        () => context.read<ActivityCubit>().acceptInvite(item),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Decline',
                  isPrimary: false,
                  onPressed:
                      () => _performAction(
                        () => context.read<ActivityCubit>().declineInvite(item),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for tags
  Widget _buildTag({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // 3.4 Recently accepted section
  Widget _buildRecentlyAcceptedItem(Map<String, dynamic> item) {
    String text = '';
    bool isRequest = item.containsKey('request_id');
    if (isRequest) {
      text = 'You joined ${item['space_name']}';
    } else {
      text = '${item['invited_name']} accepted your invite';
    }

    return _BaseCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _timeAgo(item['updated_at']),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isRequest)
            TextButton(
              onPressed:
                  () => navigateToSpace(item['space_id'], item['space_type']),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'OPEN',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4. Unified Sent Item Builder (Requests & Invites)
  Widget _buildSentItemCard(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isInvite,
  }) {
    final status = item['status'];
    final isPending = status == 'pending';

    // Avatar logic
    String? photo, avatar;
    bool isPremium = false;
    String title = '';
    String subtitle = '';

    if (isInvite) {
      photo = item['invited_photo_key'];
      avatar = item['invited_avatar_key'];
      isPremium = item['invited_is_premium'] == true;
      title = item['invited_name'] ?? 'Unknown User';
      subtitle = 'Invited to ${item['space_name']}';
    } else {
      // Sent Request
      photo = item['owner_photo_key'];
      avatar = item['owner_avatar_key'];
      isPremium = item['owner_is_premium'] == true;
      title = item['space_name']; // For requests, we show space name as title
      subtitle = 'Owner: ${item['owner_name'] ?? 'Unknown'}';
    }

    return _BaseCard(
      child: Opacity(
        opacity: isPending ? 1.0 : 0.7, // Fade out completed items slightly
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(url: photo ?? avatar, isPremium: isPremium, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: AppTheme.background),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // STATUS INDICATOR
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPending
                            ? AppTheme.accentAmber.withValues(
                              alpha: 0.1,
                            ) // Amber tint
                            : AppTheme.secondaryColor.withValues(
                              alpha: 0.1,
                            ), // Green tint
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending
                            ? Icons.access_time_filled_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color:
                            isPending
                                ? AppTheme.accentAmber
                                : AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPending
                            ? 'Pending Approval'
                            : (isInvite
                                ? 'Invite Accepted'
                                : 'Request Accepted'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isPending
                                  ? AppTheme.accentAmber
                                  : AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTION
                if (isPending)
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isInvite) {
                          _performAction(
                            () => context.read<ActivityCubit>().revokeInvite(
                              item,
                            ),
                          );
                        } else {
                          _performAction(
                            () => context.read<ActivityCubit>().revokeRequest(
                              item,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: AppTheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'Undo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                // If space is accessible, show Open button
                if (!isInvite) // For requests you joined, you can open the space
                  TextButton(
                    onPressed:
                        () => navigateToSpace(
                          item['space_id'],
                          item['space_type'],
                        ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(
                      'Open Space',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36, // Compact
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.onBackground : AppTheme.surface,
          foregroundColor: isPrimary ? Colors.white : AppTheme.onBackground,
          elevation: 0,
          shadowColor: Colors.transparent,
          side:
              isPrimary
                  ? null
                  : BorderSide(color: AppTheme.outline.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13, // Smaller text
          ),
        ),
      ),
    );
  }

  // Empty states
  Widget _buildForYouEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 60,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new\nrequests and invites.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 60,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No sent items',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your sent requests and invites\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp);
    return timeago.format(date, allowFromNow: true);
  }
}

class _BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _BaseCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    // Flat, sleek design on grey/custom background or white surface
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      padding: padding ?? const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: AppTheme.surface, // Keep white
        borderRadius: BorderRadius.circular(20), // Slightly tighter radius
        // Removed border for cleaner look if on grey bg, or keep very subtle
        // border: Border.all(color: AppTheme.outline.withValues(alpha: 0.4)),
        boxShadow: [
          // Stronger but dispersed shadow for "float" effect on grey
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool isPremium;
  final double size;
  const _Avatar({this.url, this.isPremium = false, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // Exact Logic for Avatar/Photo:
    // Priority: photo first, avatar as fallback
    // If photoKey is present:
    //   - It's a key in 'profile-photos' bucket.
    //   - Use getPublicUrl (faster/simpler than signedUrl for public avatars, assuming public bucket).
    //   - OR createSignedUrl if bucket is private. Based on prior code, we used getPublicUrl.
    // If photoKey is null, use avatarKey:
    //   - It's a filename in 'assets/avatars/'.
    //   - Load via Image.asset.

    // 1. Determine which key to use
    // The "url" prop passed to this widget is actually the Key from the RPC result.
    // We need to differentiate if it was the photo_key or the avatar_key passed in?
    // The parent widgets pass: url: item['xxx_photo_key'] ?? item['xxx_avatar_key']

    // So 'url' holds the non-null value.
    // If item['xxx_photo_key'] was not null, 'url' acts as photoKey.
    // If item['xxx_photo_key'] was null, 'url' acts as avatarKey.

    // How to distinguish?
    // - Photo keys are paths: "userid/userid.jpg" (contain '/')
    // - Avatar keys are filenames: "Number=18.webp" (no '/')

    // Let's implement the logic based on this distinction.

    if (url == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: AppTheme.onSurfaceVariant,
            size: size * 0.5,
          ),
        ),
      );
    }

    final isPhoto = url!.contains('/');
    final imageUrl =
        isPhoto
            ? Supabase.instance.client.storage
                .from('profile-photos')
                .getPublicUrl(url!)
            : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
              border: Border.all(
                color: AppTheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: ClipOval(
              child:
                  isPhoto && imageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        cacheKey: url,
                        cacheManager: ImageCacheService().cacheManager,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        httpHeaders: {
                          'Accept': 'image/*',
                          'Connection': 'keep-alive',
                        },
                        placeholder:
                            (context, url) => Container(
                              color: AppTheme.background,
                              child: Icon(
                                Icons.person,
                                color: AppTheme.onSurfaceVariant,
                                size: size * 0.3,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Icon(
                              Icons.person,
                              color: AppTheme.onSurfaceVariant,
                              size: size * 0.5,
                            ),
                      )
                      : CachedNetworkImage(
                        imageUrl: Supabase.instance.client.storage
                            .from('Avatars')
                            .getPublicUrl(url!),
                        cacheKey: 'avatar_\$url',
                        cacheManager: ImageCacheService().cacheManager,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        httpHeaders: const {
                          'Accept': 'image/*',
                          'Connection': 'keep-alive',
                        },
                        placeholder:
                            (context, u) => Container(
                              color: AppTheme.background,
                              child: Icon(
                                Icons.person,
                                color: AppTheme.onSurfaceVariant,
                                size: size * 0.3,
                              ),
                            ),
                        errorWidget:
                            (context, u, error) => Icon(
                              Icons.person,
                              color: AppTheme.onSurfaceVariant,
                              size: size * 0.5,
                            ),
                      ),
            ),
          ),
          if (isPremium)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child: SvgPicture.asset(
                  'assets/Svg/blue-verified-badge.svg',
                  width: size * 0.35,
                  height: size * 0.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
