import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/space_visibility.dart';
import '../../core/theme/app_theme.dart';

/// A row of three tappable chips — Private / Public / Nearby —
/// that lets the user set the visibility of a Space.
class VisibilityPicker extends StatelessWidget {
  final SpaceVisibility selected;
  final ValueChanged<SpaceVisibility> onChanged;

  const VisibilityPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: SpaceVisibility.values.map((v) {
            final isSelected = v == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: v != SpaceVisibility.values.last ? 8 : 0,
                ),
                child: _VisibilityChip(
                  visibility: v,
                  isSelected: isSelected,
                  onTap: () => onChanged(v),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            selected.description,
            key: ValueKey(selected),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final SpaceVisibility visibility;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityChip({
    required this.visibility,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.onBackground : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.onBackground : AppTheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(visibility.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              visibility.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

