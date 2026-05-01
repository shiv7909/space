import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/discover_models.dart';

class SpacePreviewSheet extends StatelessWidget {
  final DiscoverSpace space;
  final VoidCallback onJoin;

  const SpacePreviewSheet({
    super.key,
    required this.space,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Handle
           Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.spaceName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onBackground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       space.spaceType == 'couple' ? 'Couple Space' : 'Group Space',
                       style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Habits Section
          Text(
            'HABITS IN THIS SPACE',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),

          if (space.habitPreviews.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Text('No habits added yet.', style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant)),
             ),

          ...space.habitPreviews.map((habit) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                 Container(
                   width: 40, height: 40,
                   alignment: Alignment.center,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(10),
                   ),
                   child: Text(habit.emoji ?? '📲', style: const TextStyle(fontSize: 20)),
                 ),
                 const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    habit.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onBackground),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 24),

          // Join Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onJoin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Join Space',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

