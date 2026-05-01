import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../../shared/user_avatar_widget.dart';

import '../cubit/active_people_cubit.dart';
import '../models/discover_models.dart';
import 'invite_space_picker.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM USER — full profile sheet
// ═══════════════════════════════════════════════════════════════════════════
class PersonBottomSheet extends StatelessWidget {
  final DiscoverPerson person;
  final ActivePeopleCubit cubit;
  const PersonBottomSheet({super.key, required this.person, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Large avatar ──
            _DiscoverAvatar(
              photoKey: person.photoKey,
              avatarKey: person.avatarKey,
              name: person.displayName,
              size: 72,
            ),
            const SizedBox(height: 12),

            // ── Name ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 4),

            // ── Space badge ──
            if (person.hasPublicSpace) ...[
              _buildSpaceBadge(),
              const SizedBox(height: 6),
            ],

            // ── Social proof ──
            if (person.hasStreak)
              Text(
                '🔥 ${person.bestCurrentStreak} day streak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              )
            else if (person.daysOnApp != null)
              Text(
                'Member for ${person.daysOnApp} days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),

            const SizedBox(height: 24),

            // ── Button 1: Request to Join ──
            if (person.hasPublicSpace) ...[
              if (person.iRequested)
                _buildRequestedButton()
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _handleRequestToJoin(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: Text(
                      'Request to Join',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],

            // ── Button 2: Invite to My Space ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showInviteSpacePicker(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Invite to My Space',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildSpaceBadge() {
    final parts = <String>[
      person.spaceType == 'group' ? '👥 Group' : '👫 Couple',
    ];
    if (person.spaceCategory != null) {
      parts.add('${person.spaceCategoryEmoji ?? ''} ${person.spaceCategory!}'.trim());
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        parts.join(' · '),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRequestedButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
        ),
        child: Text(
          '✓ Request Sent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Request to Join ─────────────────────────────────────────────────────

  Future<void> _handleRequestToJoin(
    BuildContext context, {
    bool force = false,
    String? spaceType,
  }) async {
    if (person.hasMultipleSpaces && spaceType == null && !force) {
      final picked = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (_) => SimpleDialog(
          title: Text(
            'Which space to join?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          children: person.availableSpaceTypes.map((t) =>
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  t == 'couple' ? '  Couple Space' : '   Group Space',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
      );
      if (picked != null && context.mounted) {
        _handleRequestToJoin(context, spaceType: picked);
      }
      return;
    }

    final resolvedType = spaceType ?? person.availableSpaceTypes.firstOrNull;
    final result = await cubit.requestToJoin(
      person.userId,
      force: force,
      spaceType: resolvedType,
    );

    if (!context.mounted) return;

    if (result == null) {
      Navigator.pop(context);
      _showSnackbar(context, 'Request sent! 🙌');
      return;
    }

    final parts = result.split('|');
    final code = parts[0];
    final conflictName = parts.length > 1 ? parts[1] : '';

    switch (code) {
      case 'CONFLICT_OWNER':
        final confirmed = await _showConflictDialog(
          context,
          title: 'Your space will be deleted',
          message:
              '"$conflictName" will be permanently deleted — '
              'all habits, logs, and data for every member '
              'will be gone forever if your request gets accepted.',
          confirmLabel: 'Send Request',
          dangerous: true,
        );
        if (confirmed && context.mounted) {
          _handleRequestToJoin(context, force: true, spaceType: resolvedType);
        }
        break;
      case 'CONFLICT_MEMBER':
        final confirmed = await _showConflictDialog(
          context,
          title: 'You\'ll leave your current space',
          message:
              'You\'ll be removed from "$conflictName" and lose '
              'all your history there if your request gets accepted.',
          confirmLabel: 'Send Request',
          dangerous: false,
        );
        if (confirmed && context.mounted) {
          _handleRequestToJoin(context, force: true, spaceType: resolvedType);
        }
        break;
      default:
        Navigator.pop(context);
        _showSnackbar(context, _requestErrorMessage(code));
    }
  }

  // ── Invite to My Space ─────────────────────────────────────────────────

  Future<void> _showInviteSpacePicker(BuildContext context) async {
    final spaces = await cubit.getMyInvitableSpaces(person.userId);
    if (!context.mounted) return;

    if (spaces.isEmpty) {
      _showSnackbar(context, 'No available spaces to invite this person to');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteSpacePicker(
        spaces: spaces,
        onSelect: (spaceId) async {
          Navigator.pop(context);
          Navigator.pop(context);
          if (!context.mounted) return;
          final errorCode = await cubit.sendInvite(person.userId, spaceId);
          if (!context.mounted) return;
          if (errorCode == null) {
            _showSnackbar(context, 'Invite sent! 🕐');
          } else {
            _showSnackbar(context, _inviteErrorMessage(errorCode));
          }
        },
      ),
    );
  }

  // ── Error messages ─────────────────────────────────────────────────────

  String _requestErrorMessage(String code) => switch (code) {
    'NO_JOINABLE_SPACE' => 'This person isn\'t in a public space anymore',

    'ALREADY_MEMBER'    => 'You\'re already in this space',
    'ALREADY_REQUESTED' => 'Request already sent',
    'SPACE_FULL'        => 'This space is full',
    'YOUR_OWN_SPACE'    => 'This is your own space',
    _                   => 'Something went wrong, try again',
  };

  String _inviteErrorMessage(String code) => switch (code) {
    'NOT_OWNER'      => 'You can only invite to spaces you own',

    'SPACE_FULL'     => 'This space is now full',
    'ALREADY_MEMBER' => 'This person is already in your space',
    'INVITE_PENDING' => 'You already invited this person',
    _                => 'Something went wrong, try again',
  };

  // ── Conflict dialog ────────────────────────────────────────────────────

  Future<bool> _showConflictDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool dangerous,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.onBackground,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: dangerous ? AppTheme.accentRed : AppTheme.accentAmber,
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared avatar resolver (used by both sheet variants)
// ═══════════════════════════════════════════════════════════════════════════
class _DiscoverAvatar extends StatefulWidget {
  final String? photoKey;
  final String? avatarKey;
  final String name;
  final double size;

  const _DiscoverAvatar({
    this.photoKey,
    this.avatarKey,
    required this.name,
    required this.size,
  });

  @override
  State<_DiscoverAvatar> createState() => _DiscoverAvatarState();
}

class _DiscoverAvatarState extends State<_DiscoverAvatar> {
  String? _resolvedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _resolveAvatar();
  }

  @override
  void didUpdateWidget(covariant _DiscoverAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarKey != widget.avatarKey ||
        oldWidget.photoKey != widget.photoKey) {
      _resolveAvatar();
    }
  }

  Future<void> _resolveAvatar() async {
    if (widget.photoKey != null) return;
    if (widget.avatarKey != null) {
      final profileService = context.read<ProfileService>();
      final url = await profileService.getAvatarUrl(widget.avatarKey!);
      if (mounted) setState(() => _resolvedAvatarUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatarWidget(
      photoKey: widget.photoKey,
      avatarUrl: _resolvedAvatarUrl,
      name: widget.name,
      size: widget.size,

    );
  }
}
