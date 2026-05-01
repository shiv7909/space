import 'package:flutter/material.dart';

/// Legacy premium badge widget — preserved as an empty widget
/// to avoid breaking any stray imports.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, double size = 14});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
