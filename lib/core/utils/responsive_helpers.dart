import 'package:flutter/widgets.dart';

/// Responsive scaling utility.
///
/// Uses the screen height to derive a scale factor so that UI elements
/// designed on a 6.7″ reference device (Motorola Edge Fusion, ~915 lp tall)
/// scale down gracefully on smaller phones (6.0″–6.5″).
///
/// On the reference device and larger, [scale] returns **1.0** — zero visual
/// change. On smaller screens the factor drops proportionally, clamped to a
/// minimum of 0.82 so text never becomes unreadably small.
class Responsive {
  Responsive._();

  /// Logical-pixel height of the 6.7″ reference device.
  static const double _referenceHeight = 915.0;

  /// Returns a 0.82–1.0 multiplier based on screen height.
  static double scale(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= _referenceHeight) return 1.0;
    return (screenHeight / _referenceHeight).clamp(0.82, 1.0);
  }

  /// Convenience: multiply [value] by the current scale factor.
  static double sp(BuildContext context, double value) =>
      value * scale(context);
}
