import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';

/// 📷 SNAP CAPTURE SCREEN
///
/// Opens camera (or gallery) → lets user pick a habit → optional caption → returns data.
/// Returns a map: { 'image': File, 'habitId': String?, 'caption': String? }
class SnapCaptureScreen extends StatefulWidget {
  final List<DashboardHabit> habits;
  final String spaceId;
  final String? preSelectedHabitId;
  final ImageSource? initialSource;

  const SnapCaptureScreen({
    super.key,
    required this.habits,
    required this.spaceId,
    this.preSelectedHabitId,
    this.initialSource,
  });

  @override
  State<SnapCaptureScreen> createState() => _SnapCaptureScreenState();
}

class _SnapCaptureScreenState extends State<SnapCaptureScreen> {
  File? _imageFile;
  String? _selectedHabitId;
  final _captionController = TextEditingController();
  bool _isCapturing = false;
  late ImageSource _activeSource;

  @override
  void initState() {
    super.initState();
    // Pre-select habit if provided (from habit card "+" button)
    _selectedHabitId = widget.preSelectedHabitId;
    // Open the selected source immediately on launch
    _activeSource = widget.initialSource ?? ImageSource.camera;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeSource == ImageSource.gallery) {
        _pickFromGallery();
      } else {
        _captureImage();
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _activeSource = ImageSource.camera;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (picked == null) {
        // User cancelled camera — go back
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        _imageFile = File(picked.path);
        _isCapturing = false;
      });
    } catch (e) {
      print('🔴 SnapCapture: Camera error: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        // Try gallery as fallback
        _pickFromGallery();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _activeSource = ImageSource.gallery);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (picked == null) {
        if (mounted && _imageFile == null) Navigator.pop(context);
        return;
      }

      setState(() => _imageFile = File(picked.path));
    } catch (e) {
      print('🔴 SnapCapture: Gallery error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  /// Re-opens whatever source was last used (camera → retake, gallery → pick again)
  void _retakeOrRepick() {
    setState(() => _imageFile = null);
    if (_activeSource == ImageSource.gallery) {
      _pickFromGallery();
    } else {
      _captureImage();
    }
  }

  void _sendSnap() {
    if (_imageFile == null) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, {
      'image': _imageFile!,
      'habitId': _selectedHabitId,
      'caption': _captionController.text.trim().isEmpty
          ? null
          : _captionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _imageFile == null ? _buildLoadingState() : _buildPreviewState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Opening camera...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    final isGallery = _activeSource == ImageSource.gallery;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Image preview ──
        Positioned.fill(
          child: Image.file(
            _imageFile!,
            fit: BoxFit.contain,
          ),
        ),

        // ── Gradient overlays ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top bar: close | [gallery switcher] [retake/repick] ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  // Switch to gallery (always visible)
                  if (!isGallery)
                    _buildTopButton(
                      icon: Icons.photo_library_rounded,
                      onTap: _pickFromGallery,
                    ),
                  if (!isGallery) const SizedBox(width: 8),
                  // Retake (camera) or Pick again (gallery)
                  _buildTopButton(
                    icon: isGallery
                        ? Icons.photo_library_rounded   // pick different photo
                        : Icons.camera_alt_rounded,      // retake with camera
                    label: isGallery ? 'Change' : 'Retake',
                    onTap: _retakeOrRepick,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Bottom: habit picker + caption + send ──
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Habit picker chips
              if (widget.habits.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.habits.length,
                    itemBuilder: (context, index) {
                      final habit = widget.habits[index];
                      final isSelected = _selectedHabitId == habit.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedHabitId =
                                  isSelected ? null : habit.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(habit.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  habit.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Caption input + Send
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: _captionController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLength: 100,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendSnap,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5C4AE4),
                            Color(0xFF8B7DFF),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onTap,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: label != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
    );
  }
}
