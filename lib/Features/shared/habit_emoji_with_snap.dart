import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'habit_shape_widget.dart';

/// 📸 Habit emoji with a small "+" camera overlay for snaps.
///
/// The "+" badge is shown only when [showSnapAdd] is true (i.e. user hasn't
/// posted a snap for this habit today). Tapping the "+" triggers [onAddSnap].
/// The habit emoji itself is NOT affected — taps on the emoji area still go
/// through to the parent GestureDetector (the habit card).
class HabitEmojiWithSnap extends StatelessWidget {
  final String emoji;
  final double size;
  final bool showSnapAdd;
  final VoidCallback? onAddSnap;

  const HabitEmojiWithSnap({
    super.key,
    required this.emoji,
    this.size = 28,
    this.showSnapAdd = false,
    this.onAddSnap,
  });

  @override
  Widget build(BuildContext context) {
    final containerSize = size * 1.6;

    return SizedBox(
      width: containerSize + 6, // extra space for the badge overflow
      height: containerSize + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Emoji container (same as HabitShapeWidget) ──
          Positioned(
            left: 0,
            top: 3,
            child: HabitShapeWidget(emoji: emoji, size: size),
          ),

          // ── Small "+" camera badge ──
          if (showSnapAdd && onAddSnap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAddSnap!();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5C4AE4),
                        Color(0xFF8B7DFF),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

