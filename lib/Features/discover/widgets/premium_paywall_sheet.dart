import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom sheet shown when a non-premium user tries to join a space.
class PremiumPaywallSheet extends StatelessWidget {
  const PremiumPaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // ── Icon ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C4AE4), Color(0xFFAA96FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Text(
            'Upgrade to Premium',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // ── Subtitle ──
          Text(
            'Joining spaces is a premium feature.\nUpgrade to connect with crews around the world.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // ── Perks list ──
          _PerkRow(icon: Icons.group_add_rounded, label: 'Join unlimited spaces'),
          const SizedBox(height: 10),
          _PerkRow(icon: Icons.bolt_rounded, label: 'Early access to new features'),
          const SizedBox(height: 10),
          _PerkRow(icon: Icons.star_rounded, label: 'Premium badge on your profile'),
          const SizedBox(height: 32),

          // ── CTA button ──
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                // TODO: navigate to your in-app purchase / upgrade screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Premium upgrade coming soon! 🚀'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C4AE4), Color(0xFFAA96FA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Upgrade Now ✨',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Dismiss ──
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe later',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PerkRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onBackground,
          ),
        ),
      ],
    );
  }
}

