import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../solo/cubit/solo_dashboard_cubit.dart';
import '../../habits/widgets/add_habit_sheet.dart';
import 'hero_illustration.dart';
import 'step_card_carousel.dart';

/// The "Start your journey" empty state — shown when the user has no habits.
class EmptyTodayGuide extends StatelessWidget {
  const EmptyTodayGuide({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed theme usage to match specific Solo Dashboard styling

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Hero illustration area ──
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const HeroIllustration(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Start Your Journey',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                          letterSpacing: -1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Small steps lead to big changes.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Step cards cycling carousel ──
          const StepCardCarousel(),

          const SizedBox(height: 24),

          // ── CTA Button ──
          SizedBox(
                // width: 240, // Removed fixed width to prevent overflow on smaller screens/larger fonts
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _openAddHabitFromHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.onBackground, // Match Solo
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32), // Add horizontal padding instead
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Hug content
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 22),
                      const SizedBox(width: 10),
                      Flexible( // Allow text to shrink if absolutely necessary
                        child: Text(
                          'Create First Habit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 700.ms, duration: 500.ms)
              .slideY(
                begin: 0.08,
                end: 0,
                delay: 700.ms,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),

          // ── Spacer to push search bar down ──
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _openAddHabitFromHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitSheet(),
    ).then((result) {
      if (result == true && context.mounted) {
        try {
          context.read<SoloDashboardCubit>().loadDashboard();
        } catch (_) {}
      }
    });
  }
}
