import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import '../../core/theme/app_theme.dart';
import '../../models/invite_model.dart';
import '../../services/profile_service.dart';
import 'cubit/invite_cubit.dart';
import 'cubit/invite_state.dart';

/// 📬 Pending Invites Screen
///
/// Shows all pending space invites for the current user.
/// Accept → joins the space instantly.
/// Reject → removes the invite.
class PendingInvitesScreen extends StatefulWidget {
  const PendingInvitesScreen({super.key});

  @override
  State<PendingInvitesScreen> createState() => _PendingInvitesScreenState();
}

class _PendingInvitesScreenState extends State<PendingInvitesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  // Keys to reach each card's state so we can reset the spinner on cancel
  final Map<String, GlobalKey<_InviteCardState>> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Refresh invites when screen opens
    context.read<InviteCubit>().loadInvites();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOut,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: BlocConsumer<InviteCubit, InviteState>(
                  listener: (context, state) {
                    if (state is InviteAccepted) {
                      HapticFeedback.heavyImpact();
                      _showSuccessSnackBar(context, state.message);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (context.mounted) Navigator.of(context).pop(true);
                      });
                    }
                    if (state is InviteRejected) {
                      HapticFeedback.lightImpact();
                      _showInfoSnackBar(context, state.message);
                    }
                    if (state is InviteConflict) {
                      _showConflictDialog(context, state);
                    }
                    if (state is InviteError) {
                      // Reset any in-progress accept buttons
                      setState(() {});
                      _showErrorSnackBar(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is InviteLoading) {
                      return _buildLoadingState();
                    }

                    if (state is InviteLoaded) {
                      if (state.invites.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildInvitesList(context, state.invites);
                    }

                    if (state is InviteError) {
                      return _buildErrorState(context, state.message);
                    }

                    return _buildEmptyState();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.onBackground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Invites',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.onBackground,
            ),
          ),
          const Spacer(),
          BlocBuilder<InviteCubit, InviteState>(
            builder: (context, state) {
              final count =
                  state is InviteLoaded ? state.invites.length : 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6BE0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count pending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B6BE0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOADING STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF6B6BE0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checking for invites...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6B6BE0).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📭', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Invites',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'When someone invites you to their Duo or Squad space, it\'ll show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<InviteCubit>().loadInvites(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B6BE0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVITES LIST
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildInvitesList(BuildContext context, List<InviteModel> invites) {
    return RefreshIndicator(
      onRefresh: () => context.read<InviteCubit>().loadInvites(),
      color: const Color(0xFF6B6BE0),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: invites.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Text(
                'You have ${invites.length} pending invite${invites.length > 1 ? 's' : ''}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final invite = invites[index - 1];
          // Create or reuse a GlobalKey for this invite
          final cardKey = _cardKeys.putIfAbsent(
            invite.inviteId,
            () => GlobalKey<_InviteCardState>(),
          );
          return _InviteCard(
            key: cardKey,
            invite: invite,
            onAccept: () {
              HapticFeedback.mediumImpact();
              context.read<InviteCubit>().acceptInvite(invite.inviteId);
            },
            onReject: () {
              _showRejectConfirmation(context, invite);
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REJECT CONFIRMATION
  // ═══════════════════════════════════════════════════════════════════════
  void _showRejectConfirmation(BuildContext context, InviteModel invite) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.accentRed,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Decline Invite?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Decline the invite from ${invite.invitedByName} to join "${invite.spaceName}"?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<InviteCubit>().rejectInvite(invite.inviteId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Decline',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SNACKBARS
  // ═════════════════════════════════════════════════════════════���═════════
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: AppTheme.onBackground,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: AppTheme.onSurfaceVariant,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: AppTheme.accentRed,
      duration: const Duration(seconds: 4),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONFLICT DIALOG
  // ═══════════════════════════════════════════════════════════════════════
  void _showConflictDialog(BuildContext context, InviteConflict state) {
    final isOwner = state.code == 'CONFLICT_OWNER';
    final spaceName = state.conflictSpaceName;
    final title = isOwner ? 'Delete your space?' : 'Leave your current space?';
    final message = isOwner
        ? '"$spaceName" will be permanently deleted — all habits, logs, and history '
          'for every member will be gone forever. This cannot be undone.'
        : 'You will be removed from "$spaceName" and lose all your habit history there. '
          'This cannot be undone.';
    final confirmLabel = isOwner ? 'Delete & Join' : 'Leave & Join';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onBackground)),
            ),
          ],
        ),
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // ✅ Reset the spinner on the card that triggered this dialog
              _cardKeys[state.inviteId]?.currentState?.resetActioning();
            },
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<InviteCubit>().forceAcceptInvite(state.inviteId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(confirmLabel, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INVITE CARD — Premium-feel card with glassmorphism + swipe actions
// ═══════════════════════════════════════════════════════════════════════════

class _InviteCard extends StatefulWidget {
  final InviteModel invite;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InviteCard({
    super.key, // ← allows GlobalKey to be passed
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isActioning = false;

  /// Called externally (via widget.onCancelConflict) to reset the spinner.
  void resetActioning() {
    if (mounted) setState(() => _isActioning = false);
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Color get _spaceTypeColor {
    switch (widget.invite.spaceType) {
      case 'couple':
        return const Color(0xFFFF6B6B);
      case 'group':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFF6B6BE0);
    }
  }

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.outline.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                // ── Top: Invite info ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inviter avatar
                      _buildAvatar(),
                      const SizedBox(width: 14),
                      // Invite details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Inviter name
                            Text(
                              widget.invite.invitedByName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Invite message
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'invited you to join '),
                                  TextSpan(
                                    text: '"${widget.invite.spaceName}"',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Space type badge + time
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _spaceTypeColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.invite.spaceTypeEmoji,
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.invite.spaceTypeLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _spaceTypeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _timeAgo(widget.invite.createdAt),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Divider ──
                Container(
                  height: 1,
                  color: AppTheme.outline.withValues(alpha: 0.4),
                ),

                // ── Bottom: Action buttons ──
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isActioning ? null : widget.onReject,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRed
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Decline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Accept button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _isActioning
                              ? null
                              : () {
                                  setState(() => _isActioning = true);
                                  widget.onAccept();
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6B6BE0),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B6BE0)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isActioning
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Accept & Join',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
  }

  Widget _buildAvatar() {
    final avatarId = widget.invite.invitedByAvatar;
    final photoKey = widget.invite.invitedByPhotoKey;
    final avatarKey = widget.invite.invitedByAvatarKey;

    // Priority: real photo → avatar key → avatar ID → fallback
    if (photoKey != null && photoKey.isNotEmpty) {
      final url = context.read<ProfileService>().getProfilePhotoUrl(photoKey);
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _spaceTypeColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: _spaceTypeColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => _buildFallbackAvatar(),
            errorWidget: (_, __, ___) => _buildFallbackAvatar(),
          ),
        ),
      );
    }

    if (avatarKey != null && avatarKey.isNotEmpty) {
      return FutureBuilder<String?>(
        future: context.read<ProfileService>().getAvatarUrl(avatarKey),
        builder: (context, snapshot) {
          final avatarUrl = snapshot.data;
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _spaceTypeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: _spaceTypeColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildFallbackAvatar(),
                      errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          );
        },
      );
    }

    return FutureBuilder<String?>(
      future: avatarId != null
          ? context.read<ProfileService>().getAvatarUrlById(avatarId)
          : Future.value(null),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _spaceTypeColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: _spaceTypeColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildFallbackAvatar(),
                    errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Text(
        widget.invite.invitedByName.isNotEmpty
            ? widget.invite.invitedByName[0].toUpperCase()
            : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _spaceTypeColor,
        ),
      ),
    );
  }
}
