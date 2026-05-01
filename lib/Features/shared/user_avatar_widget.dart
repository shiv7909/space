import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/profile_service.dart';
import '../../../services/image_cache_service.dart';

/// Reusable avatar widget used everywhere a user's profile image is shown.
///
/// Priority: real photo → preset avatar → initials fallback.
///
/// Usage:
/// ```dart
/// UserAvatarWidget(
///   photoKey:  profile.photoKey,   // null if using avatar
///   avatarUrl: avatarUrl,          // already-resolved avatar signed URL
///   name:      'John',
///   size:      48,
/// )
/// ```
class UserAvatarWidget extends StatefulWidget {
  /// Storage key from `profile_photos.photo_key` (e.g. "uid/uid.jpg").
  /// If non-null, the widget fetches a signed URL from the `profile-photos` bucket.
  final String? photoKey;

  /// Already-resolved signed URL for a preset avatar (from the Avatars bucket).
  /// Used as fallback when [photoKey] is null.
  final String? avatarUrl;

  /// Already-resolved signed URL for a real photo.
  /// If provided, skips the signed-URL fetch for [photoKey].
  final String? photoUrl;

  /// User display name — first character used as fallback initial.
  final String? name;

  /// Diameter of the circle avatar.
  final double size;

  /// Background color for the initials fallback.
  final Color? backgroundColor;

  /// Text color for the initials fallback.
  final Color? initialsColor;

  const UserAvatarWidget({
    super.key,
    this.photoKey,
    this.avatarUrl,
    this.photoUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.initialsColor,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  String? _resolvedPhotoUrl;
  bool _isLoadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _resolvePhotoUrl();
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoKey != widget.photoKey ||
        oldWidget.photoUrl != widget.photoUrl) {
      _resolvePhotoUrl();
    }
  }

  void _resolvePhotoUrl() {
    // If a pre-resolved photoUrl is supplied, use it directly
    if (widget.photoUrl != null) {
      if (mounted) setState(() => _resolvedPhotoUrl = widget.photoUrl);
      return;
    }

    // If there's a photoKey, resolve it synchronously (public URL — no async needed)
    if (widget.photoKey != null) {
      final profileService = context.read<ProfileService>();
      final url = profileService.getProfilePhotoUrl(widget.photoKey!);
      if (mounted) setState(() => _resolvedPhotoUrl = url);
    } else {
      if (mounted) {
        setState(() {
          _resolvedPhotoUrl = null;
          _isLoadingPhoto = false;
        });
      }
    }
  }

  String get _initial {
    if (widget.name != null && widget.name!.isNotEmpty) {
      return widget.name![0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.grey[100]!;
    final txtColor = widget.initialsColor ?? const Color(0xFF18181B);
    final radius = widget.size / 2;

    // The display URL: real photo first, then avatar
    final displayUrl = _resolvedPhotoUrl ?? widget.avatarUrl;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child:
          _isLoadingPhoto
              ? _buildShimmer(radius, bgColor)
              : displayUrl != null
              ? _buildImage(displayUrl, radius, bgColor, txtColor)
              : _buildInitials(radius, bgColor, txtColor),
    );
  }

  Widget _buildShimmer(double radius, Color bgColor) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(radius: radius, backgroundColor: bgColor),
    );
  }

  Widget _buildImage(String url, double radius, Color bgColor, Color txtColor) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder:
          (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            backgroundImage: imageProvider,
          ),
      cacheManager: ImageCacheService().cacheManager,
      httpHeaders: const {'Accept': 'image/*', 'Connection': 'keep-alive'},
      placeholder: (_, __) => _buildShimmer(radius, bgColor),
      errorWidget: (_, __, ___) => _buildInitials(radius, bgColor, txtColor),
    );
  }

  Widget _buildInitials(double radius, Color bgColor, Color txtColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _initial,
        style: GoogleFonts.plusJakartaSans(
          color: txtColor,
          fontWeight: FontWeight.w900,
          fontSize: widget.size * 0.38,
        ),
      ),
    );
  }
}
