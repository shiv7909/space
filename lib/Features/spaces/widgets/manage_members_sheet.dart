import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/space_visibility.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/space_model.dart';
import '../../../services/profile_service.dart';
import '../../../services/category_service.dart';
import '../../../services/snap_service.dart';
import '../../../services/space_service.dart';
import '../../couple/cubit/spaces_cubit.dart';
import '../../couple/cubit/spaces_state.dart';

import '../../shared/user_avatar_widget.dart';
import '../../shared/visibility_picker.dart';

/// A bottom sheet that lists all members of a space and lets the owner
/// remove any non-owner member via the `remove_space_member` RPC.
class ManageMembersSheet extends StatefulWidget {
  final SpaceModel space;
  final String currentUserId;
  final SpacesCubit spacesCubit;
  final bool isReadOnly;
  final List<Map<String, String>>? habitInfoList;

  const ManageMembersSheet({
    super.key,
    required this.space,
    required this.currentUserId,
    required this.spacesCubit,
    this.isReadOnly = false,
    this.habitInfoList,
  });

  @override
  State<ManageMembersSheet> createState() => _ManageMembersSheetState();
}

class _ManageMembersSheetState extends State<ManageMembersSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;
  String? _removingUserId;

  // ── Category info ──
  String? _categoryName;
  String? _categoryEmoji;

  // ── Visibility state (owner-only) ──
  late SpaceVisibility _spaceVisibility;
  bool _savingVisibility = false;

  // ── Blocked users state ──
  List<Map<String, dynamic>> _blocks = [];
  bool _blocksLoading = true;
  final Set<String> _unblocking = {};
  bool _blocksExpanded = false;

  // ── Description state (editable by owner) ──
  String? _description;

  @override
  void initState() {
    super.initState();
    _description = widget.space.description;
    _spaceVisibility = widget.space.visibility;
    _fetchMembers();
    _fetchBlocks();
    _fetchCategory();
  }

  Future<void> _fetchCategory() async {
    if (widget.space.categoryId == null) return;
    try {
      final categoryService = context.read<CategoryService>();
      final categories = await categoryService.getCategories();
      try {
        final category = categories.firstWhere(
          (c) => c.id == widget.space.categoryId,
        );
        if (mounted) {
          setState(() {
            _categoryName = category.name;
            _categoryEmoji = category.emoji;
          });
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spaceService = context.read<SpaceService>();
      final members = await spaceService.getSpaceMembersWithProfiles(
        widget.space.id,
      );
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchBlocks() async {
    setState(() => _blocksLoading = true);
    try {
      final snapService = context.read<SnapService>();
      final blocks = await snapService.getMyBlocks();
      if (mounted)
        setState(() {
          _blocks = blocks;
          _blocksLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _blocksLoading = false);
    }
  }

  Future<void> _unblockUser(String blockedId, String displayName) async {
    setState(() => _unblocking.add(blockedId));
    try {
      final snapService = context.read<SnapService>();
      await snapService.unblockUser(blockedId);
      if (!mounted) return;
      setState(() {
        _unblocking.remove(blockedId);
        _blocks.removeWhere((b) => b['blocked_id'] == blockedId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ $displayName unblocked',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.onBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _unblocking.remove(blockedId));
    }
  }

  void _confirmUnblock(String blockedId, String displayName) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              'Unblock $displayName?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            content: Text(
              'Their snaps will start appearing in your feed again.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _unblockUser(blockedId, displayName);
                },
                child: Text(
                  'Unblock',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _formatBlockedAt(String? blockedAt) {
    if (blockedAt == null) return '';
    try {
      final dt = DateTime.parse(blockedAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _displayName(Map<String, dynamic> member) {
    final profile = member['profiles'];
    if (profile == null) return 'Unknown';
    final name = profile['display_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : 'Unnamed';
  }

  void _confirmRemove(BuildContext context, Map<String, dynamic> member) {
    final userId = member['user_id'] as String;
    final name = _displayName(member);

    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_remove_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remove Member',
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
              'Remove $name from "${widget.space.name}"?\n\nAll their habit logs and progress in this space will be cleared. They can be re-invited later.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
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
                  Navigator.pop(dialogCtx);
                  _doRemove(userId, name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Remove',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _doRemove(String userId, String name) async {
    setState(() => _removingUserId = userId);

    try {
      await widget.spacesCubit.removeMember(
        spaceId: widget.space.id,
        targetUserId: userId,
      );

      if (mounted) {
        // Remove from local list for instant UI feedback
        setState(() {
          _members.removeWhere((m) => m['user_id'] == userId);
          _removingUserId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name has been removed from the space.',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _editDescription() async {
    final controller = TextEditingController(text: _description);
    final newDesc = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Edit Description',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.onBackground,
              ),
            ),
            content: TextField(
              controller: controller,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'What is this space for?',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );

    if (newDesc != null && newDesc.trim() != _description?.trim()) {
      try {
        final spaceService = context.read<SpaceService>();
        await spaceService.updateSpaceDescription(
          spaceId: widget.space.id,
          description: newDesc.trim(),
        );
        setState(() => _description = newDesc.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Description updated successfully',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update description: $e',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveVisibility(SpaceVisibility newV) async {
    if (newV == _spaceVisibility) return;

    // Show confirmation dialog before changing visibility
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogCtx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.visibility_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Change Visibility?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are about to change this space visibility:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Current visibility
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _spaceVisibility.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From: ${_spaceVisibility.label}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                Text(
                                  _spaceVisibility.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Arrow down
                    Center(
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // New visibility
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(newV.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To: ${newV.label}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                Text(
                                  newV.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Change Visibility',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _spaceVisibility = newV;
      _savingVisibility = true;
    });
    try {
      final spaceService = context.read<SpaceService>();
      await spaceService.updateSpaceVisibility(
        spaceId: widget.space.id,
        visibility: newV.value,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visibility changed to ${newV.label}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visibility: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingVisibility = false);
    }
  }

  // ── Avatar widget: resolves photo or avatar, shows image ──
  Widget _buildAvatarWidget(
    String name,
    String? avatarId,
    String? photoKey,
    String userId,
    bool isOwner,
  ) {
    final bgColor =
        isOwner
            ? const Color(0xFF9333EA).withValues(alpha: 0.12)
            : AppTheme.outline.withValues(alpha: 0.15);
    final color = isOwner ? const Color(0xFF9333EA) : AppTheme.onSurfaceVariant;

    // photo_key comes from the nested profile_photos join — sync public URL, zero extra calls
    if (photoKey != null) {
      final url = context.read<ProfileService>().getProfilePhotoUrl(photoKey);
      return UserAvatarWidget(
        photoUrl: url,
        name: name,
        size: 44,
        backgroundColor: bgColor,
        initialsColor: color,
      );
    }

    return _buildAvatarFallback(name, avatarId, bgColor, color);
  }

  Widget _buildAvatarFallback(
    String name,
    String? avatarId,
    Color bgColor,
    Color color,
  ) {
    final fallback = CircleAvatar(
      radius: 22,
      backgroundColor: bgColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: color,
        ),
      ),
    );

    if (avatarId == null) return fallback;

    return FutureBuilder<String?>(
      future: context.read<ProfileService>().getAvatarUrlById(avatarId),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return fallback;
        return UserAvatarWidget(
          avatarUrl: url,
          name: name,
          size: 44,
          backgroundColor: bgColor,
          initialsColor: color,
        );
      },
    );
  }

  // ── Detail chip in space details header ──
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId == widget.space.createdBy;
    // Provide the cubit via BlocProvider.value so BlocListener works
    // even though this sheet lives in a separate modal route.
    return BlocProvider<SpacesCubit>.value(
      value: widget.spacesCubit,
      child: BlocListener<SpacesCubit, SpacesState>(
        listener: (context, state) {
          if (state is SpacesError && _removingUserId != null) {
            setState(() => _removingUserId = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Space Overview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Text(
                      '${_members.length} ${_members.length == 1 ? 'member' : 'members'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Space details summary (member count, habit count, habit names) ──
              if (widget.habitInfoList != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((_description != null &&
                              _description!.trim().isNotEmpty) ||
                          isOwner) ...[
                        GestureDetector(
                          onTap: isOwner ? _editDescription : null,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (_description == null ||
                                            _description!.trim().isEmpty)
                                        ? 'Add a description...'
                                        : _description!.trim(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontStyle:
                                          (_description == null ||
                                                  _description!.trim().isEmpty)
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                      color:
                                          (_description == null ||
                                                  _description!.trim().isEmpty)
                                              ? AppTheme.onSurfaceVariant
                                                  .withValues(alpha: 0.7)
                                              : AppTheme.onSurface,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Stats row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_categoryName != null) ...[
                              _buildDetailChip(
                                icon: Icons.category_rounded,
                                label: '$_categoryEmoji $_categoryName',
                                color: const Color(0xFFE67E22),
                              ),
                              const SizedBox(width: 10),
                            ],
                            _buildDetailChip(
                              icon: Icons.people_outline_rounded,
                              label:
                                  '${_members.length} ${_members.length == 1 ? 'Member' : 'Members'}',
                              color: const Color(0xFF9333EA),
                            ),
                            const SizedBox(width: 10),
                            _buildDetailChip(
                              icon: Icons.flag_rounded,
                              label:
                                  '${widget.habitInfoList?.length ?? 0} ${(widget.habitInfoList?.length ?? 0) == 1 ? 'Habit' : 'Habits'}',
                              color: const Color(0xFF6B6BE0),
                            ),
                          ],
                        ),
                      ),
                      if (widget.habitInfoList!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Habits',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              widget.habitInfoList!.map((h) {
                                final emoji = h['emoji'] ?? '📌';
                                final name = h['name'] ?? 'Habit';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.outline.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onBackground,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // ── VISIBILITY (owner only) ──
                      if (isOwner) ...[
                        Row(
                          children: [
                            Text(
                              'VISIBILITY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            if (_savingVisibility) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        VisibilityPicker(
                          selected: _spaceVisibility,
                          onChanged: _saveVisibility,
                        ),
                      ],

                      const SizedBox(height: 16),
                      // Section label for members list
                      Text(
                        'Members',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // ── Members list + Blocked section scrollable together ──
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Members body
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF9333EA),
                          ),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load members',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _fetchMembers,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9333EA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_members.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No members found.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _members.length,
                          separatorBuilder:
                              (_, __) => const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final userId = member['user_id'] as String;
                            final name = _displayName(member);
                            final avatarId =
                                (member['profiles'] as Map?)?['avatar_id']
                                    as String?;
                            final photoKey =
                                ((member['profiles'] as Map?)?['profile_photos']
                                        as Map?)?['photo_key']
                                    as String?;
                            final isMe = userId == widget.currentUserId;
                            final isOwner = userId == widget.space.createdBy;
                            final isRemoving = _removingUserId == userId;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: _buildAvatarWidget(
                                name,
                                avatarId,
                                photoKey,
                                userId,
                                isOwner,
                              ),
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isMe ? '$name (you)' : name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onBackground,
                                    ),
                                  ),

                                ],
                              ),
                              subtitle: Text(
                                isOwner ? 'Owner' : 'Member',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isOwner
                                          ? const Color(0xFF9333EA)
                                          : AppTheme.onSurfaceVariant,
                                ),
                              ),
                              trailing:
                                  (!isMe && !isOwner && !widget.isReadOnly)
                                      ? isRemoving
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.redAccent,
                                            ),
                                          )
                                          : IconButton(
                                            onPressed:
                                                () => _confirmRemove(
                                                  context,
                                                  member,
                                                ),
                                            icon: const Icon(
                                              Icons.person_remove_rounded,
                                              size: 20,
                                              color: Colors.redAccent,
                                            ),
                                            tooltip: 'Remove member',
                                            visualDensity:
                                                VisualDensity.compact,
                                          )
                                      : null,
                            );
                          },
                        ),

                      // ── Blocked Users Section ──
                      const Divider(height: 1),
                      InkWell(
                        onTap:
                            () => setState(
                              () => _blocksExpanded = !_blocksExpanded,
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.block_rounded,
                                  size: 16,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Blocked Users',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                              ),
                              if (_blocksLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentRed,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _blocks.isEmpty
                                            ? AppTheme.surfaceVariant
                                            : AppTheme.accentRed.withValues(
                                              alpha: 0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_blocks.length}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _blocks.isEmpty
                                              ? AppTheme.onSurfaceVariant
                                              : AppTheme.accentRed,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                _blocksExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_blocksExpanded) ...[
                        if (_blocksLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                            ),
                          )
                        else if (_blocks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: AppTheme.accentGreen.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'No blocked users',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: _blocks.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final block = _blocks[index];
                              final blockedId =
                                  block['blocked_id'] as String? ?? '';
                              final displayName =
                                  block['display_name'] as String? ?? 'Unknown';
                              final photoKey = block['photo_key'] as String?;
                              final avatarKey = block['avatar_key'] as String?;
                              final avatarId = block['avatar_id'] as String?;
                              final blockedAt = block['blocked_at'] as String?;
                              final isUnblocking = _unblocking.contains(
                                blockedId,
                              );
                              final profileService =
                                  context.read<ProfileService>();

                              Widget avatar;
                              if (photoKey != null && photoKey.isNotEmpty) {
                                avatar = ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profileService.getProfilePhotoUrl(
                                      photoKey,
                                    ),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (_, __) =>
                                            _blockedAvatarFallback(displayName),
                                    errorWidget:
                                        (_, __, ___) =>
                                            _blockedAvatarFallback(displayName),
                                  ),
                                );
                              } else if (avatarKey != null &&
                                  avatarKey.isNotEmpty) {
                                avatar = FutureBuilder<String?>(
                                  future: profileService.getAvatarUrl(
                                    avatarKey,
                                  ),
                                  builder:
                                      (_, snap) =>
                                          snap.data != null
                                              ? ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: snap.data!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (_, __, ___) =>
                                                          _blockedAvatarFallback(
                                                            displayName,
                                                          ),
                                                ),
                                              )
                                              : _blockedAvatarFallback(
                                                displayName,
                                              ),
                                );
                              } else if (avatarId != null &&
                                  avatarId.isNotEmpty) {
                                avatar = FutureBuilder<String?>(
                                  future: profileService.getAvatarUrlById(
                                    avatarId,
                                  ),
                                  builder:
                                      (_, snap) =>
                                          snap.data != null
                                              ? ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: snap.data!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (_, __, ___) =>
                                                          _blockedAvatarFallback(
                                                            displayName,
                                                          ),
                                                ),
                                              )
                                              : _blockedAvatarFallback(
                                                displayName,
                                              ),
                                );
                              } else {
                                avatar = _blockedAvatarFallback(displayName);
                              }

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: avatar,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.onBackground,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (blockedAt != null)
                                            Text(
                                              'Blocked ${_formatBlockedAt(blockedAt)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap:
                                          isUnblocking
                                              ? null
                                              : () => _confirmUnblock(
                                                blockedId,
                                                displayName,
                                              ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isUnblocking
                                                  ? AppTheme.outline
                                                  : AppTheme.primaryColor
                                                      .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child:
                                            isUnblocking
                                                ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color:
                                                            AppTheme
                                                                .primaryColor,
                                                      ),
                                                )
                                                : Text(
                                                  'Unblock',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockedAvatarFallback(String name) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.accentRed.withValues(alpha: 0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppTheme.accentRed,
        ),
      ),
    );
  }
}
