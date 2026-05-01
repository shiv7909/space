// filepath: d:\habitz\lib\Features\discover\widgets\discover_empty_state.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class DiscoverEmptyState extends StatelessWidget {
  final String filter;
  final String searchQuery;

  const DiscoverEmptyState({
    super.key,
    required this.filter,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _content;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) get _content {
    if (searchQuery.isNotEmpty) {
      return ('🔍', "No spaces match '$searchQuery'");
    }
    return switch (filter) {
      'nearby' => ('📍', 'No spaces near you yet.\nBe the first to create one!'),
      'trending' => ('🔥', 'No trending spaces yet.\nActivity is heating up!'),
      'crews' => ('👥', 'No public crew spaces yet.'),
      'challenges' => ('⚡', 'No challenge spaces found.'),
      _ => ('🌍', 'No public spaces yet.\nBe the first!'),
    };
  }
}

