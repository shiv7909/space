import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/space_service.dart';
import '../../../services/profile_service.dart';
import '../../qr/qr_scanner_view.dart';
// import '../screens/premium_upgrade_screen.dart';

class AddMemberDialog extends StatefulWidget {
  final String? spaceId;
  const AddMemberDialog({super.key, this.spaceId});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();
  bool isSearching = false;
  bool isAdding = false;
  String? errorMessage;
  Map<String, dynamic>? _foundUser;

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isInviteMode = widget.spaceId != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInviteMode ? 'Invite Member' : 'Add Member',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (isInviteMode) ...[
                        const SizedBox(height: 2),
                        Text(
                          'They\'ll receive an invite to accept',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E8E9A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8E8E9A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Scan QR tile ──
            GestureDetector(
              onTap: _scanQRCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6BE0).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B6BE0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan QR Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B6BE0),
                            ),
                          ),
                          Text(
                            isInviteMode ? 'Scan their QR to send invite' : 'Scan user\'s QR to add',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF8E8E9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8E8E9A)),
                  ],
                ),
              ),
            ),

            // ── OR divider ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: const Color(0xFFF0F0F5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or invite by email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB0B0C0),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: const Color(0xFFF0F0F5))),
                ],
              ),
            ),

            // ── Email field ──
            TextField(
              controller: _emailController,
              focusNode: _focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => (isSearching || isAdding) ? null : _handleAction(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Enter email address...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: const Color(0xFFB0B0C0),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F7FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6B6BE0), width: 1.5),
                ),
                errorText: errorMessage,
                errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.red),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
              onChanged: (_) {
                if (errorMessage != null) setState(() => errorMessage = null);
                if (_foundUser != null) setState(() => _foundUser = null);
              },
            ),

            // ── User preview card ──
            if (_foundUser != null) ...[
              const SizedBox(height: 12),
              _buildUserPreview(),
            ],

            const SizedBox(height: 20),

            // ── Action button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (isSearching || isAdding) ? null : _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B6BE0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF6B6BE0).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: (isSearching || isAdding)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _getButtonLabel(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Determine button label based on state ──
  String _getButtonLabel() {
    if (_foundUser != null && widget.spaceId != null) {
      return 'Send Invite 🕐';
    }
    if (_foundUser != null && widget.spaceId == null) {
      return 'Add Member';
    }
    return 'Search';
  }

  // ── Handle button tap: search first, then invite ──
  void _handleAction() {
    if (_foundUser == null) {
      // Step 1: search by email
      _searchByEmail();
    } else if (widget.spaceId != null) {
      // Step 2a: send invite via RPC
      _sendInviteByEmail();
    } else {
      // Step 2b: return found user to caller (creation mode)
      Navigator.pop(context, {
        'userId': _foundUser!['user_id'] as String,
        'email': _emailController.text.trim(),
        'displayName': _foundUser!['display_name'] ?? 'User',
        'avatarUrl': _foundUser!['avatar_url'],
      });
    }
  }

  // ── Email validation helper ──
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w\-.]+$');
    return regex.hasMatch(email);
  }

  // ── Step 1: Search for user by email ──
  void _searchByEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => errorMessage = 'Please enter an email');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    try {
      final spaceService = context.read<SpaceService>();
      final result = await spaceService.searchUserByEmail(email);

      if (!mounted) return;

      if (result['success'] == true) {
        // ── Resolve best avatar URL: photo_key → avatar_key → avatar_id ──
        String? avatarUrl;
        final photoKey = result['photo_key'] as String?;
        final avatarKey = result['avatar_key'] as String?;
        final avatarId = result['avatar_id'] as String?;
        if (photoKey != null && photoKey.isNotEmpty) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = profileService.getProfilePhotoUrl(photoKey);
          } catch (_) {}
        } else if (avatarKey != null && avatarKey.isNotEmpty) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = await profileService.getAvatarUrl(avatarKey);
          } catch (_) {}
        } else if (avatarId != null) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = await profileService.getAvatarUrlById(avatarId);
          } catch (_) {}
        }

        setState(() {
          _foundUser = {
            ...result,
            'avatar_url': avatarUrl, // inject resolved URL
          };
          isSearching = false;
        });
      } else {
        final code = result['code'] as String?;
        String message;

        switch (code) {
          case 'USER_NOT_FOUND':
            message = 'No user found with that email';
            break;
          case 'CANNOT_ADD_SELF':
            message = 'You cannot add yourself';
            break;
          default:
            message = result['message'] as String? ?? 'User not found';
        }

        setState(() {
          errorMessage = message;
          _foundUser = null;
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
          isSearching = false;
        });
      }
    }
  }

  // ── Step 2a: Send invite via send_invite_by_email RPC ──
  void _sendInviteByEmail() async {
    setState(() => isAdding = true);

    try {
      final spaceService = context.read<SpaceService>();
      final result = await spaceService.sendInviteByEmail(
        email: _emailController.text.trim(),
        spaceId: widget.spaceId!,
      );

      if (!mounted) return;

      final bool success = result['success'] == true;
      final String message = result['message'] as String? ?? 'Unknown error';
      final String? code = result['code'] as String?;

      if (success) {
        // Show snackbar BEFORE popping so there's no white flash
        final displayName = result['display_name'] as String? ?? 'User';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Invite sent to $displayName 🕐',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, {'success': true, 'invite_sent': true});
      } else if (code == 'NOT_PREMIUM') {
        // Payment required — premium removed currently
        setState(() => isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium upgrade currently unavailable.')),
        );
      } else {
        // All other error codes
        setState(() {
          errorMessage = message;
          isAdding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
          isAdding = false;
        });
      }
    }
  }

  // ── User preview card ──
  Widget _buildUserPreview() {
    final displayName = _foundUser!['display_name'] as String? ?? 'User';
    final avatarUrl = _foundUser!['avatar_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B6BE0).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
            backgroundImage:
                avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B6BE0),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailController.text.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF5A5A5A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── QR code scan flow ──
  void _scanQRCode() async {
    final spaceId = widget.spaceId;

    // In invite mode: scanner returns userId, then we send invite via RPC.
    // In creation mode: scanner returns userId for search.
    // Always use searchOnly — we handle the invite ourselves.
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerView(
          searchOnly: true, // always search-only — we handle invite ourselves
        ),
      ),
    );

    if (result == null || !mounted) return;

    final userId = result['userId'] as String?;
    if (userId == null) return;

    // If we have a spaceId, send invite by scan
    if (spaceId != null) {
      setState(() {
        isAdding = true;
        errorMessage = null;
      });

      try {
        final spaceService = context.read<SpaceService>();
        final scanResult = await spaceService.sendInviteByScan(
          userId: userId,
          spaceId: spaceId,
        );

        if (!mounted) return;

        final bool success = scanResult['success'] == true;
        final String message =
            scanResult['message'] as String? ?? 'Unknown error';
        final String? code = scanResult['code'] as String?;

        if (success) {
          // Show snackbar BEFORE popping so there's no white flash
          final displayName = scanResult['display_name'] as String? ?? 'User';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invite sent to $displayName 🕐',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF18181B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, {'success': true, 'invite_sent': true});
        } else if (code == 'NOT_PREMIUM') {
          setState(() => isAdding = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium upgrade currently unavailable.')),
          );
        } else {
          setState(() {
            errorMessage = message;
            isAdding = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Error: ${e.toString()}';
            isAdding = false;
          });
        }
      }
      return;
    }

    // ── creation mode: scanner returned { userId } — look them up ──
    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    try {
      final spaceService = context.read<SpaceService>();
      final searchResult = await spaceService.searchUserById(userId);

      if (!mounted) return;

      if (searchResult['success'] == true) {
        // Resolve avatar — priority: photo_key → avatar_key → avatar_id
        String? avatarUrl;
        final photoKey = searchResult['photo_key'] as String?;
        final avatarKey = searchResult['avatar_key'] as String?;
        final avatarId = searchResult['avatar_id'] as String?;
        if (photoKey != null && photoKey.isNotEmpty) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = profileService.getProfilePhotoUrl(photoKey);
          } catch (_) {}
        } else if (avatarKey != null && avatarKey.isNotEmpty) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = await profileService.getAvatarUrl(avatarKey);
          } catch (_) {}
        } else if (avatarId != null) {
          try {
            final profileService = context.read<ProfileService>();
            avatarUrl = await profileService.getAvatarUrlById(avatarId);
          } catch (_) {}
        }

        setState(() {
          _foundUser = {
            ...searchResult,
            'avatar_url': avatarUrl,
          };
          _emailController.text =
              searchResult['email'] as String? ?? '';
          isSearching = false;
        });
      } else {
        setState(() {
          errorMessage =
              searchResult['message'] as String? ?? 'User not found';
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
          isSearching = false;
        });
      }
    }
  }
}
