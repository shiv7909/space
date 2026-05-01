// filepath: d:\habitz\lib\Features\discover\widgets\feed_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class FeedHeader extends StatelessWidget {
  final String filter;
  final int totalResults;

  const FeedHeader({
    super.key,
    required this.filter,
    this.totalResults = 0,
  });

  String get _label => switch (filter) {
        'all' => 'All Spaces',
        'nearby' => 'Nearby Spaces',
        'trending' => 'Trending Spaces',
        'crews' => 'Crew Spaces',
        'challenges' => 'Challenge Spaces',
        _ => 'Spaces',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: -0.1,
            ),
          ),
          if (totalResults > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalResults',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
