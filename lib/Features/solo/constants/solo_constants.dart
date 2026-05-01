import 'package:flutter/widgets.dart';
import '../../../core/utils/responsive_helpers.dart';

class SoloConstants {
  static String categoryEmoji(String category) {
    switch (category) {
      case 'first_completion':
        return '🌱';
      case 'comeback':
        return '💪';
      case 'milestone':
        return '🏆';
      case 'personal_best':
        return '⭐';
      case 'challenge_complete':
        return '🎯';
      case 'streak_progress':
      default:
        return '🔥';
    }
  }
}

extension SoloResponsiveSize on num {
  /// Scales down the value visually by 15% (0.85 factor) and ensures layout
  /// is responsive across devices
  double rs(BuildContext context) => Responsive.sp(context, this * 0.96);
}
