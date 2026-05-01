// filepath: d:\habitz\lib\Features\discover\widgets\discover_filter_tabs.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class FilterTabItem {
  final String key;
  final String label;
  final IconData? icon;

  const FilterTabItem({required this.key, required this.label, this.icon});
}

class DiscoverFilterTabs extends StatelessWidget {
  final List<FilterTabItem> filters;
  final String active;
  final ValueChanged<String> onTap;

  const DiscoverFilterTabs({
    super.key,
    required this.filters,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    final allFilter = filters.first;
    final otherFilters = filters.sublist(1);

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          const SizedBox(width: 16),
          _buildPill(allFilter, active == allFilter.key),

          // Subtle vertical divider to separate fixed vs scrolling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 1,
              height: 14,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: otherFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final filter = otherFilters[index];
                return _buildPill(filter, active == filter.key);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(FilterTabItem filter, bool isActive) {
    return GestureDetector(
      onTap: () => onTap(filter.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(
                filter.icon,
                size: 14,
                color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              filter.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
