import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/solo_constants.dart';

/// 📊 TODAY'S HABIT PROGRESS WIDGET
class TodayProgressWidget extends StatefulWidget {
  final int totalScheduled;
  final int completed;
  final int remaining;
  final String? label;
  final Color? accentColor;

  const TodayProgressWidget({
    super.key,
    required this.totalScheduled,
    required this.completed,
    required this.remaining,
    this.label,
    this.accentColor,
  });

  @override
  State<TodayProgressWidget> createState() => _TodayProgressWidgetState();
}

class _TodayProgressWidgetState extends State<TodayProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _updateProgress();
    _controller.forward();
  }

  @override
  void didUpdateWidget(TodayProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completed != widget.completed ||
        oldWidget.totalScheduled != widget.totalScheduled) {
      _updateProgress();
      _controller.forward(from: 0.0);
    }
  }

  void _updateProgress() {
    double endValue =
        widget.totalScheduled > 0
            ? widget.completed / widget.totalScheduled
            : 0.0;
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: endValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = 1.0.rs(context);
    const Color darkText = Color(0xFF1A1A2E);
    const Color subduedText = Color(0xFF8E8E9A);
    const Color defaultAccent = Color(0xFF5C4AE4);
    const Color successColor = Color(0xFF2DA44E);

    final Color accentColor = widget.accentColor ?? defaultAccent;

    final bool isComplete =
        widget.totalScheduled > 0 && widget.completed >= widget.totalScheduled;
    final Color barColor = isComplete ? successColor : accentColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.rs(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + percentage ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label ?? "Today's Progress",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5 * s,
                      fontWeight: FontWeight.w600,
                      color: subduedText,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 4.rs(context)),
                  Text(
                    isComplete
                        ? 'Crushed it! 🔥'
                        : '${widget.remaining} left to do',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15 * s,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              // ── Percentage ──
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    final animatedPct =
                        (_progressAnimation.value * 100).round();
                    return Text(
                      '$animatedPct%',
                      style: GoogleFonts.outfit(
                        fontSize: 22 * s,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: barColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.rs(context)),
          // ── Animated progress bar ──
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return Container(
                  height: 6 * s,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              if (!isComplete)
                                BoxShadow(
                                  color: barColor.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14.rs(context)),
          // ── Bottom stats row ──
          Row(
            children: [
              _buildStatItem(
                widget.totalScheduled.toString(),
                "Scheduled",
                subduedText,
              ),
              _buildDivider(),
              _buildStatItem(widget.completed.toString(), "Done", subduedText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.rs(context),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3D3D4E),
          ),
        ),
        SizedBox(width: 6.rs(context)),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.rs(context),
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Container(
    height: 14.rs(context),
    width: 1.rs(context),
    margin: EdgeInsets.symmetric(horizontal: 14.rs(context)),
    color: const Color(0xFFEDEDF2),
  );
}
