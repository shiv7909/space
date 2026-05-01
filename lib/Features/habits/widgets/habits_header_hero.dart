import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

// ─── MINIMAL TAB SELECTOR ─────────────────────────────
class HabitTabSelector extends StatelessWidget {
  final List<String> tabs;
  final ValueChanged<int> onTabChanged;
  final TabController tabController;

  const HabitTabSelector({
    super.key,
    required this.tabs,
    required this.onTabChanged,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final selected = tabController.index;
        return SizedBox(
          height: 34,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = i == selected;
              final label = _format(tabs[i]);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 7),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabChanged(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color:
                            active
                                ? AppTheme.primaryColor
                                : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppTheme.onSurface,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _format(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}
