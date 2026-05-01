import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressHeroCard extends StatelessWidget {
  final int scheduled;
  final int done;
  final int remaining;

  const ProgressHeroCard({
    super.key,
    required this.scheduled,
    required this.done,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = scheduled == 0 ? 0 : done / scheduled;
    final int pctInt = (pct * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Dark color only
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(15), // Subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7B6EF6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBlock(
                value: '$scheduled',
                label: 'Scheduled',
                valueColor: Colors.white,
              ),
              _StatBlock(
                value: '$done',
                label: 'Done',
                valueColor: const Color(0xFF6FCF97),
              ),
              _StatBlock(
                value: '$remaining',
                label: 'Remaining',
                valueColor: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
