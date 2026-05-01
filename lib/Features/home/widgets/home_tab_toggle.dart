import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Animated sliding tab toggle for Today / Discover.
class HomeTabToggle extends StatefulWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const HomeTabToggle({
    super.key,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  State<HomeTabToggle> createState() => _HomeTabToggleState();
}

class _HomeTabToggleState extends State<HomeTabToggle>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['Today', 'Discover'];
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.activeIndex == 1 ? 1.0 : 0.0, // sync initial value
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(HomeTabToggle old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) {
      // Stop any in-flight animation first to prevent stacking
      _controller.stop();
      if (widget.activeIndex == 1) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / _tabs.length;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.outline.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // ── Sliding white pill ──
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, _) {
                  return Positioned(
                    top: 3,
                    bottom: 3,
                    left: 3 + _slideAnimation.value * (tabWidth - 3),
                    width: tabWidth - 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Labels ──
              Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = widget.activeIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.activeIndex == i) return; // already on this tab
                        HapticFeedback.selectionClick();
                        widget.onChanged(i);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w600,
                            color:
                                isActive
                                    ? AppTheme.onBackground
                                    : AppTheme.onSurfaceVariant,
                            letterSpacing: -0.2,
                          ),
                          child: Text(_tabs[i]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
