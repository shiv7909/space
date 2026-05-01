import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeaderWrapper extends StatelessWidget {
  final String userName;
  final int scheduled;
  final int done;
  final int remaining;
  final ValueChanged<int> onTabChanged;

  const HomeHeaderWrapper({
    super.key,
    required this.userName,
    required this.scheduled,
    required this.done,
    required this.remaining,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EFF4), // background beneath
      child: Column(
        children: [
          Stack(
            children: [
              HeroHeader(
                name: userName,
                scheduled: scheduled,
                done: done,
                remaining: remaining,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24, // Height of the overlap curve
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EFF4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: const Color(0xFFF0EFF4),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: HabitTabSelector(
              tabs: const ['all', 'solo', 'duo', 'squad'],
              onTabChanged: onTabChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroHeader extends StatelessWidget {
  final String name;
  final int scheduled;
  final int done;
  final int remaining;

  const HeroHeader({
    super.key,
    required this.name,
    required this.scheduled,
    required this.done,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = scheduled == 0 ? 0 : done / scheduled;

    return Stack(
      children: [
        // Base container
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF5C4AE4),
            borderRadius: BorderRadius.zero,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 20, // SafeArea substitute
            20,
            56, // Padding bottom increased to accommodate the visual overlap below
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA89BF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(102), // 0.4 opacity
                        width: 2.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Icons right
                  Row(
                    children: [
                      _buildIconButton(Icons.notifications_none_rounded),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.person_outline_rounded),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. GREETING
              Text(
                "welcome back",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withAlpha(153), // 0.6 opacity
                  letterSpacing: 0.5,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Hi, ",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: "$name 👋",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC4BBFF),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. PROGRESS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TODAY'S PROGRESS",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withAlpha(153),
                      letterSpacing: 1.0,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$done",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: " / $scheduled habits",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withAlpha(128), // 0.5 opacity
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, _) {
                  return Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38), // 0.15 opacity
                      borderRadius: BorderRadius.circular(99),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230), // 0.9 opacity
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 3 stat blocks
              Row(
                children: [
                  _buildStatBlock('$scheduled', 'scheduled', Colors.white),
                  const SizedBox(width: 8),
                  _buildStatBlock('$done', 'done', const Color(0xFF9EFFD0)),
                  const SizedBox(width: 8),
                  _buildStatBlock('$remaining', 'remaining', const Color(0xFFFFB347)),
                ],
              ),
            ],
          ),
        ),

        // DECORATIVE CIRCLES
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18), // 0.07 opacity
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13), // 0.05 opacity
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38), // 0.15 opacity
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildStatBlock(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26), // 0.10 opacity
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withAlpha(128), // 0.5 opacity
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitTabSelector extends StatefulWidget {
  final List<String> tabs;
  final ValueChanged<int> onTabChanged;

  const HabitTabSelector({
    super.key,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  State<HabitTabSelector> createState() => _HabitTabSelectorState();
}

class _HabitTabSelectorState extends State<HabitTabSelector> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEDF8),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isActive = index == _selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onTabChanged(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF5C4AE4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.tabs[index].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: isActive ? Colors.white : const Color(0xFF999999),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
