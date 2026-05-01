import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// KEY CONCEPTS ROW — "Name it. Schedule it. Streak it."
// ═══════════════════════════════════════════════════════════════════════════
class StepCardCarousel extends StatelessWidget {
  const StepCardCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    // User requested "small thing name it schedule it streak it three words !!!"
    // and "animation is heary it is bad remove that".
    // This implementation is static and minimal.
    // Changing background to even more subtle or removing container to make it "words".

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSimpleConcept('Name it'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_right_alt_rounded,
            size: 16,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
          ),
        ),
        _buildSimpleConcept('Schedule it'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_right_alt_rounded,
            size: 16,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
          ),
        ),
        _buildSimpleConcept('Streak it'),
      ],
    );
  }

  Widget _buildSimpleConcept(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}
