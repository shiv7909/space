// ════════════════════════════════════════════════════════════════════
// challenge_join_cta.dart — Sticky bottom JOIN panel
// ════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class JoinCtaPanel extends StatefulWidget {
  final Color accent;
  final String enrolled;
  final int daysLeft;
  final double s;
  final String? topMessage;
  final FutureOr<void> Function() onJoin;

  const JoinCtaPanel({
    super.key,
    required this.accent, required this.enrolled,
    required this.daysLeft, required this.s, this.topMessage, required this.onJoin,
  });

  @override
  State<JoinCtaPanel> createState() => _JoinCtaPanelState();
}

class _JoinCtaPanelState extends State<JoinCtaPanel> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _pressed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final accent = widget.accent;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, bottomPad + 16 * s),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: accent.withValues(alpha: 0.12), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: widget.topMessage != null && widget.topMessage!.trim().isNotEmpty
                      ? Text(
                          widget.topMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5 * s,
                            color: AppTheme.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5 * s, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: widget.enrolled, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.onBackground, fontSize: 13 * s)),
                              const TextSpan(text: ' members joined'),
                            ],
                          ),
                        ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6 * s, height: 6 * s, decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle)),
                    SizedBox(width: 5 * s),
                    Text('${widget.daysLeft}d left', style: GoogleFonts.plusJakartaSans(fontSize: 10.5 * s, fontWeight: FontWeight.w800, color: const Color(0xFFFF3B30))),
                  ]),
                ),
              ]),
              SizedBox(height: 14 * s),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) { setState(() => _pressed = true); HapticFeedback.lightImpact(); },
                onTapUp: (_) => _handleJoinTap(),
                onTapCancel: () => setState(() => _pressed = false),
                child: AnimatedScale(
                  scale: (_pressed && !_isSubmitting) ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      height: 58 * s,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(accent, const Color(0xFF6C63FF), _pulseAnim.value * 0.4)!,
                            Color.lerp(const Color(0xFF5C4AE4), accent, _pulseAnim.value * 0.5)!,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18 * s),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSubmitting)
                            SizedBox(
                              width: 18 * s,
                              height: 18 * s,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            Text(
                              'JOIN CHALLENGE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          SizedBox(width: 10 * s),
                          Container(
                            padding: EdgeInsets.all(4 * s),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16 * s,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoinTap() async {
    setState(() => _pressed = false);
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onJoin();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
