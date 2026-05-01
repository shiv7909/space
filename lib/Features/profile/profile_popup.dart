import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/image_cache_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../gen/assets.gen.dart';
import '../../models/avatar_model.dart' show AvatarModel;
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import 'cubit/profile_cubit.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helpers.dart';
import '../shared/user_avatar_widget.dart';
import 'widgets/account_settings_menu.dart';

class ProfilePopup extends StatefulWidget {
  final UserModel user;
  final ProfileModel? profile;
  final String? avatarUrl;
  final String? photoUrl; // pre-resolved real photo URL
  final VoidCallback onEditAvatar;
  final VoidCallback onScanQR;

  const ProfilePopup({
    super.key,
    required this.user,
    this.profile,
    this.avatarUrl,
    this.photoUrl,
    required this.onEditAvatar,
    required this.onScanQR,
  });

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  // Global key for capturing the widget as image
  final GlobalKey _qrKey = const GlobalObjectKey('profile_qr_with_avatar');

  // Edit mode state
  bool _isEditMode = false;
  late TextEditingController _nameController;
  String? _selectedAvatarId;
  String? _selectedAvatarUrl;
  String? _selectedPhotoUrl; // signed URL for real photo (or local preview)
  bool _pendingPhotoUpload =
      false; // true when user picked a photo but hasn't saved yet
  File? _pendingPhotoFile;
  bool _pendingPhotoRemoval = false; // true when user chose "Remove Photo"
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _selectedAvatarId = widget.profile?.avatarId;
    _selectedAvatarUrl = widget.avatarUrl ?? widget.user.avatarUrl;
    // Use pre-resolved photo URL if passed in, otherwise fetch it
    _selectedPhotoUrl = widget.photoUrl;
    if (_selectedPhotoUrl == null) _resolveInitialPhotoUrl();
  }

  void _resolveInitialPhotoUrl() {
    if (widget.profile?.hasPhoto == true && widget.profile?.photoKey != null) {
      final profileService = context.read<ProfileService>();
      final url = profileService.getProfilePhotoUrl(widget.profile!.photoKey!);
      if (mounted) setState(() => _selectedPhotoUrl = url);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    // Clean up temporary image files to prevent memory leaks
    if (_pendingPhotoFile != null) {
      try {
        if (_pendingPhotoFile!.existsSync()) {
          _pendingPhotoFile!.deleteSync();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp photo file: $e');
      }
    }

    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditMode && _hasChanges) {
      _showDiscardDialog();
    } else {
      setState(() {
        _isEditMode = !_isEditMode;
        if (!_isEditMode) {
          _nameController.text = widget.user.displayName ?? '';
          _selectedAvatarId = widget.profile?.avatarId;
          _selectedAvatarUrl = widget.avatarUrl ?? widget.user.avatarUrl;
          _pendingPhotoUpload = false;
          _pendingPhotoFile = null;
          _pendingPhotoRemoval = false;
          _hasChanges = false;
          _selectedPhotoUrl = widget.photoUrl;
          if (_selectedPhotoUrl == null) _resolveInitialPhotoUrl();
        }
      });
    }
  }

  void _onNameChanged(String value) {
    setState(() {
      _hasChanges =
          value != widget.user.displayName ||
          _pendingPhotoUpload ||
          _pendingPhotoRemoval ||
          _selectedAvatarId != widget.profile?.avatarId;
    });
  }

  bool get _showLocalPreview =>
      _pendingPhotoUpload && _pendingPhotoFile != null;

  // ─── Photo/Avatar picker bottom sheet ───────────────────────────────────
  void _showPhotoOptions() {
    final hasRealPhoto =
        (widget.profile?.hasPhoto == true && !_pendingPhotoRemoval) ||
        _pendingPhotoUpload;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Profile Picture',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Choose how you want to be seen',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option 1: Upload Photo
                  _PhotoOptionTile(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFF6B6BE0),
                    iconBg: const Color(0xFF6B6BE0).withValues(alpha: 0.1),
                    title: 'Upload Photo',
                    subtitle: 'Take a photo or choose from gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickPhoto();
                    },
                  ),

                  // Option 2: Choose Avatar
                  _PhotoOptionTile(
                    icon: Icons.face_rounded,
                    iconColor: const Color(0xFF9333EA),
                    iconBg: const Color(0xFF9333EA).withValues(alpha: 0.1),
                    title: 'Choose Avatar',
                    subtitle: 'Pick from preset avatars',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAvatarPicker();
                    },
                  ),

                  // Option 3: Remove Photo (only if real photo exists)
                  if (hasRealPhoto)
                    _PhotoOptionTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFE53935),
                      iconBg: const Color(0xFFE53935).withValues(alpha: 0.1),
                      title: 'Remove Photo',
                      subtitle: 'Revert to your avatar',
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmAndRemovePhoto();
                      },
                      isDestructive: true,
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  // ─── Pick a photo from camera or gallery ────────────────────────────────
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PhotoOptionTile(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFF18181B),
                    iconBg: const Color(0xFFF4F4F5),
                    title: 'Camera',
                    subtitle: 'Take a new photo',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  _PhotoOptionTile(
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF18181B),
                    iconBg: const Color(0xFFF4F4F5),
                    title: 'Gallery',
                    subtitle: 'Choose from your photos',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    // Launch cropper for circular cropping
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFF6B6BE0),
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          statusBarColor: const Color(0xFF6B6BE0),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          hideBottomControls: false,
          activeControlsWidgetColor: const Color(0xFF6B6BE0),
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _pendingPhotoFile = File(croppedFile.path);
      _pendingPhotoUpload = true;
      _pendingPhotoRemoval = false;
      _selectedPhotoUrl = null; // will show local preview instead
      _hasChanges = true;
    });
  }

  // ─── Confirm removal ────────────────────────────────────────────────────
  void _confirmAndRemovePhoto() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Remove Photo?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            content: Text(
              'Your preset avatar will be shown instead.',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pendingPhotoRemoval = true;
                    _pendingPhotoUpload = false;
                    _pendingPhotoFile = null;
                    _selectedPhotoUrl = null;
                    _hasChanges = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  // ─── Avatar Picker Sheet Widget ──────────────────────────────────────────
  void _showAvatarPicker() async {
    final selectedAvatarId = await showDialog<String>(
      context: context,
      builder:
          (context) => Dialog(
            child: _AvatarPickerSheet(
              currentAvatarId: _selectedAvatarId,
              onSelect: (id) => Navigator.of(context).pop(id),
            ),
          ),
    );

    if (selectedAvatarId != null) {
      final profileService = context.read<ProfileService>();
      final url = await profileService.getAvatarUrlById(selectedAvatarId);
      setState(() {
        _selectedAvatarId = selectedAvatarId;
        _selectedAvatarUrl = url;
        // Choosing an avatar implicitly removes pending photo
        _pendingPhotoUpload = false;
        _pendingPhotoFile = null;
        _pendingPhotoRemoval =
            widget.profile?.hasPhoto == true; // will remove real photo
        _selectedPhotoUrl = null;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final profileCubit = context.read<ProfileCubit>();

      // 1. Upload photo if pending
      if (_pendingPhotoUpload && _pendingPhotoFile != null) {
        // --- 🛡 NSFW CHECK ---
        try {
          final detector = await NsfwDetector.load(threshold: 0.60);
          final bytes = await _pendingPhotoFile!.readAsBytes();
          final nsfwResult = await detector.detectNSFWFromBytes(bytes);
          detector.close();

          if (nsfwResult == null) {
            if (mounted) {
              setState(() => _isSaving = false);
              _showNsfwDetectorErrorAlert(context);
            }
            return;
          }

          if (nsfwResult.isNsfw) {
            if (mounted) {
              setState(() => _isSaving = false);
              _showGenZNsfwAlert(context);
            }
            return; // Abort the upload
          }
        } catch (e) {
          debugPrint('NSFW Detector failed: $e');
          if (mounted) {
            setState(() => _isSaving = false);
            _showNsfwDetectorErrorAlert(context);
          }
          return;
        }
        // --- END NSFW CHECK ---

        await profileCubit.uploadProfilePhoto(_pendingPhotoFile!);
      }

      // 2. Remove photo if pending
      if (_pendingPhotoRemoval && !_pendingPhotoUpload) {
        await profileCubit.deleteProfilePhoto();
      }

      // 3. Collect combined profile updates (name + avatar)
      String? updatedDisplayName;
      String? updatedAvatarId;

      if (_nameController.text != widget.user.displayName) {
        updatedDisplayName = _nameController.text;
      }

      if (_selectedAvatarId != widget.profile?.avatarId &&
          !_pendingPhotoUpload) {
        updatedAvatarId = _selectedAvatarId;
      }

      // Perform single profile update if either name or avatar changed
      if (updatedDisplayName != null || updatedAvatarId != null) {
        await profileCubit.updateProfile(
          displayName: updatedDisplayName,
          avatarId: updatedAvatarId,
        );
      }

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _hasChanges = false;
          _isSaving = false;
          _pendingPhotoUpload = false;
          _pendingPhotoFile = null;
          _pendingPhotoRemoval = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // ✅ Return false to prevent parent (StickyActionButtons) from completely reloading the profile.
        // The ProfileCubit has already seamlessly emitted the new ProfileLoaded states.
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Discard Changes?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            content: Text(
              'You have unsaved changes. Are you sure you want to discard them?',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditMode = false;
                    _nameController.text = widget.user.displayName ?? '';
                    _selectedAvatarId = widget.profile?.avatarId;
                    _selectedAvatarUrl =
                        widget.avatarUrl ?? widget.user.avatarUrl;
                    _pendingPhotoUpload = false;
                    _pendingPhotoFile = null;
                    _pendingPhotoRemoval = false;
                    _hasChanges = false;
                    _selectedPhotoUrl = widget.photoUrl;
                    if (_selectedPhotoUrl == null) _resolveInitialPhotoUrl();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // QR Code contains ONLY user ID
    final String qrData = widget.user.id;
    final isPremium = widget.profile?.isPremiumFlag ?? false;

    return PopScope(
      canPop: !(_isEditMode && _hasChanges),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isEditMode && _hasChanges) {
          _showDiscardDialog();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROFILE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if (!_isEditMode)
                    GestureDetector(
                      onTap: () {
                        if (_isEditMode && _hasChanges) {
                          _showDiscardDialog();
                        } else {
                          // Return false to indicate no changes were made
                          Navigator.pop(context, false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          Assets.svg.doubleChevronDown,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF18181B),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Main Content Area
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(24 * Responsive.scale(context)),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // 1. Clean Identity Row (Avatar + Name)
                            Row(
                              children: [
                                // ── Profile Image (photo or avatar) ──
                                GestureDetector(
                                  onTap: _isEditMode ? _showPhotoOptions : null,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 72 * Responsive.scale(context),
                                        height: 72 * Responsive.scale(context),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFF4F4F5),
                                            width: 2,
                                          ),
                                        ),
                                        child:
                                            _showLocalPreview
                                                ? ClipOval(
                                                  child: Image.file(
                                                    _pendingPhotoFile!,
                                                    width:
                                                        68 *
                                                        Responsive.scale(
                                                          context,
                                                        ),
                                                    height:
                                                        68 *
                                                        Responsive.scale(
                                                          context,
                                                        ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                : UserAvatarWidget(
                                                  photoUrl:
                                                      _pendingPhotoRemoval
                                                          ? null
                                                          : _selectedPhotoUrl,
                                                  avatarUrl: _selectedAvatarUrl,
                                                  name: _nameController.text,
                                                  size:
                                                      68 *
                                                      Responsive.scale(context),
                                                ),
                                      ),
                                      // Edit Badge
                                      if (_isEditMode)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF18181B),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Name & Email Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child:
                                                !_isEditMode
                                                    ? Text(
                                                      widget.user.displayName ??
                                                          'User',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize:
                                                            20 *
                                                            Responsive.scale(
                                                              context,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                          0xFF18181B,
                                                        ),
                                                        letterSpacing: -0.5,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                    : TextField(
                                                      controller:
                                                          _nameController,
                                                      onChanged: _onNameChanged,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize:
                                                            20 *
                                                            Responsive.scale(
                                                              context,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                          0xFF18181B,
                                                        ),
                                                      ),
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                        isDense: true,
                                                        border:
                                                            const UnderlineInputBorder(),
                                                        enabledBorder:
                                                            const UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Color(
                                                                      0xFFE4E4E7,
                                                                    ),
                                                                  ),
                                                            ),
                                                        focusedBorder:
                                                            const UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Color(
                                                                      0xFF18181B,
                                                                    ),
                                                                    width: 2,
                                                                  ),
                                                            ),
                                                        hintText: 'Name',
                                                        hintStyle:
                                                            GoogleFonts.plusJakartaSans(
                                                              color:
                                                                  Colors
                                                                      .grey[300],
                                                            ),
                                                      ),
                                                    ),
                                          ),
                                          if (!_isEditMode && isPremium) ...[
                                            const SizedBox(width: 4),
                                            SvgPicture.asset(
                                              'assets/Svg/blue-verified-badge.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.user.email,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Color(0xFF71717A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit Button
                                GestureDetector(
                                  onTap: _toggleEditMode,
                                  child: Container(
                                    margin: EdgeInsets.only(left: 4),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE4E4E7),
                                      ),
                                    ),
                                    child: Icon(
                                      _isEditMode
                                          ? Icons.close
                                          : Icons.edit_outlined,
                                      size: 18,
                                      color: const Color(0xFF18181B),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24 * Responsive.scale(context)),

                            // 2. Large QR Section
                            if (!_isEditMode)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 32 * Responsive.scale(context),
                                  horizontal: 24 * Responsive.scale(context),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFE4E4E7,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        16 * Responsive.scale(context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: qrData,
                                        version: QrVersions.auto,
                                        size: 200 * Responsive.scale(context),
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Colors.black,
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                              color: Colors.black,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20 * Responsive.scale(context),
                                    ),
                                    // Minimalist scan text
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          size: 16,
                                          color: Color(0xFF71717A),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'SCAN TO CONNECT',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF71717A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.0,
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
                    ),

                    SizedBox(height: 24 * Responsive.scale(context)),

                    // 3. Social & Share Actions
                    if (!_isEditMode)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _shareQRImage(context, 'general'),
                              child: Container(
                                height: 56 * Responsive.scale(context),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Share Profile',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MinimalSocialBtn(
                            icon: SvgPicture.asset(
                              Assets.svg.whatsApp,
                              width: 22,
                            ),
                            onTap: () => _shareQRImage(context, 'whatsapp'),
                          ),
                          const SizedBox(width: 12),
                          _MinimalSocialBtn(
                            icon: const Icon(
                              Icons.telegram,
                              color: Color(0xFF0088CC),
                              size: 24,
                            ),
                            onTap: () => _shareQRImage(context, 'telegram'),
                          ),
                        ],
                      ),

                    if (_isEditMode)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: double.infinity,
                        height: 56 * Responsive.scale(context),
                        child: ElevatedButton(
                          onPressed:
                              _hasChanges && !_isSaving ? _saveChanges : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'SAVE CHANGES',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                    // Logout Button + Settings Icon Row
                    if (!_isEditMode)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            // Logout Button
                            Expanded(
                              child: Container(
                                height: 56 * Responsive.scale(context),
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoggingOut
                                          ? null
                                          : () async {
                                            final shouldLogout =
                                                await _showLogoutConfirmationDialog();
                                            if (shouldLogout == true &&
                                                mounted) {
                                              setState(
                                                () => _isLoggingOut = true,
                                              );
                                              try {
                                                final authService =
                                                    context.read<AuthService>();
                                                await authService.signOut();
                                                if (mounted) {
                                                  Navigator.of(
                                                    context,
                                                  ).pushNamedAndRemoveUntil(
                                                    AppRouter.auth,
                                                    (route) => false,
                                                  );
                                                }
                                              } catch (_) {
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoggingOut = false,
                                                  );
                                                }
                                              }
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    disabledBackgroundColor: const Color(
                                      0xFFE53935,
                                    ),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child:
                                      _isLoggingOut
                                          ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                          : Text(
                                            'LOG OUT',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Settings Icon Button
                            GestureDetector(
                              onTap: () => AccountSettingsMenu.show(context),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.more_vert_rounded,
                                  size: 22,
                                  color: AppTheme.onSurface,
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
          ],
        ),
      ),
    );
  }

  Future<void> _shareQRImage(BuildContext context, String platform) async {
    try {
      // Capture the widget as image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/habitz_profile_${widget.user.id}.png');
      await file.writeAsBytes(pngBytes);

      // Share message
      final String message =
          'Add me to your Space! Scan my QR code to add me to your group. 🚀';

      if (platform == 'whatsapp' || platform == 'telegram') {
        await Share.shareXFiles([XFile(file.path)], text: message);
      } else {
        // General share
        await Share.shareXFiles([XFile(file.path)], text: message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  Future<bool?> _showLogoutConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF5A5A5A)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ],
          ),
    );
  }
}

// Avatar Picker Sheet Widget
class _AvatarPickerSheet extends StatefulWidget {
  final String? currentAvatarId;
  final ValueChanged<String> onSelect;

  const _AvatarPickerSheet({this.currentAvatarId, required this.onSelect});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  List<AvatarModel> _avatars = [];
  Map<String, String> _avatarUrls = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    try {
      final profileService = context.read<ProfileService>();
      final avatars = await profileService.getAvatars();
      if (mounted) {
        setState(() {
          _avatars = avatars;
          _isLoading = false;
        });
      }

      // ── Load all avatar URLs in PARALLEL (not sequentially) ──
      final urls = <String, String>{};
      try {
        final urlFutures = avatars.map(
          (avatar) => profileService.getAvatarUrlById(avatar.id).then((url) {
            if (url != null) {
              return MapEntry(avatar.id, url);
            }
            return null;
          }),
        );

        // Wait for all requests to complete simultaneously
        final results = await Future.wait(urlFutures);
        for (final entry in results) {
          if (entry != null) {
            urls[entry.key] = entry.value;
          }
        }

        if (mounted) {
          setState(() {
            _avatarUrls = urls;
          });
        }
      } catch (_) {
        // If batch loading fails, continue with empty URLs
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B6BE0).withValues(alpha: 0.1),
                  const Color(0xFF9575CD).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Avatar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pick your favorite avatar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF5A5A5A),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF6B6BE0).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Avatar Grid Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF6B6BE0),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading avatars...',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(
                                  0xFF5A5A5A,
                                ).withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _avatars.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied,
                              size: 64,
                              color: const Color(
                                0xFF5A5A5A,
                              ).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No avatars available',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: const Color(0xFF5A5A5A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                        itemCount: _avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final avatarUrl = _avatarUrls[avatar.id];
                          final isSelected =
                              avatar.id == widget.currentAvatarId;

                          return GestureDetector(
                            onTap: () => widget.onSelect(avatar.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF6B6BE0)
                                          : Colors.transparent,
                                  width: 4,
                                ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6B6BE0,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                              ),
                              child: Stack(
                                children: [
                                  // Avatar image
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[100],
                                    ),
                                    child:
                                        avatarUrl == null
                                            ? Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                            : CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              cacheManager:
                                                  ImageCacheService()
                                                      .cacheManager,
                                              httpHeaders: const {
                                                'Accept': 'image/*',
                                                'Connection': 'keep-alive',
                                              },
                                              imageBuilder:
                                                  (
                                                    context,
                                                    imageProvider,
                                                  ) => Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                              placeholder:
                                                  (
                                                    context,
                                                    url,
                                                  ) => Shimmer.fromColors(
                                                    baseColor:
                                                        Colors.grey[300]!,
                                                    highlightColor:
                                                        Colors.grey[100]!,
                                                    child: Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: const Icon(
                                                      Icons.error_outline,
                                                      color: Color(0xFF5A5A5A),
                                                    ),
                                                  ),
                                            ),
                                  ),
                                  // Check mark for selected avatar
                                  if (isSelected)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6B6BE0),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalSocialBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _MinimalSocialBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE4E4E7), width: 1.5),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PhotoOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
            // Destructive action indicator (red dot)
            if (isDestructive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  NSFW UI - Alerts
// ══════════════════════════════════════════════════════════════════

void _showGenZNsfwAlert(BuildContext context) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              const Text('🛑', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ayo! Hold up.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'We detected some spicy content (nudity) in your profile photo. Let\'s keep it safe and strictly SFW here, respectfully. 🧢',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'My bad, bet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
  );
}

void _showNsfwDetectorErrorAlert(BuildContext context) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scan Failed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Our content scanner hit a snag and couldn\'t verify this image. To keep the community safe, the upload has been blocked. Please try again. 🔒',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.accentRed.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Got it',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentRed,
                ),
              ),
            ),
          ],
        ),
  );
}
