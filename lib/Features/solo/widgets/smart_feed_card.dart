import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dashboard_model.dart';
import '../constants/solo_constants.dart';

class SmartFeedCard extends StatefulWidget {
  final DashboardAlert alert;
  final VoidCallback onDismiss;

  const SmartFeedCard({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  @override
  State<SmartFeedCard> createState() => _SmartFeedCardState();
}

class _SmartFeedCardState extends State<SmartFeedCard> {
  // ✅ Handle dismissal
  void _handleDismiss() {
    HapticFeedback.mediumImpact();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardContent();
  }

  Widget _buildCardContent() {
    final isWarning = widget.alert.type == DashboardAlertType.warning;
    return Dismissible(
      key: Key(widget.alert.id),
      direction: DismissDirection.up,
      onDismissed: (_) => _handleDismiss(),
      child: Container(
        width: 280.rs(context),
        margin: EdgeInsets.only(right: 12.rs(context)),
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // ── Left accent bar for urgency (warnings/breaks) ──
            if (isWarning ||
                widget.alert.type == DashboardAlertType.breakStreak)
              Container(
                width: 4.rs(context),
                height: 88.rs(context),
                decoration: BoxDecoration(
                  color: _getTextColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  (isWarning ||
                          widget.alert.type == DashboardAlertType.breakStreak)
                      ? 14.rs(context)
                      : 18.rs(context),
                  16.rs(context),
                  18.rs(context),
                  16.rs(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getIcon(),
                          style: TextStyle(fontSize: 20.rs(context)),
                        ),
                        SizedBox(width: 8.rs(context)),
                        Expanded(
                          child: Text(
                            widget.alert.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.rs(context),
                              fontWeight: FontWeight.w700,
                              color: _getTextColor(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.rs(context)),
                    Text(
                      widget.alert.message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5.rs(context),
                        fontWeight: FontWeight.w400,
                        color: _getSubTextColor(),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor() {
    switch (widget.alert.type) {
      case DashboardAlertType.breakStreak:
        return const Color(0xFF2D2D3A);
      case DashboardAlertType.warning:
        return const Color(0xFFFCECEC);
      case DashboardAlertType.recovery:
        return const Color(0xFFFFF7ED);
      case DashboardAlertType.nudge:
        return AppTheme.surfaceVariant;
      case DashboardAlertType.milestone:
        return const Color(0xFFFFF9EE);
      case DashboardAlertType.completion:
        return AppTheme.surface;
    }
  }

  Color _getTextColor() {
    switch (widget.alert.type) {
      case DashboardAlertType.breakStreak:
        return const Color(0xFFE8838A);
      case DashboardAlertType.warning:
        return const Color(0xFFB54248);
      case DashboardAlertType.recovery:
        return const Color(0xFFA06B2A);
      case DashboardAlertType.nudge:
        return AppTheme.onBackground;
      case DashboardAlertType.milestone:
        return const Color(0xFF8B6914);
      case DashboardAlertType.completion:
        return AppTheme.accentGreen;
    }
  }

  Color _getSubTextColor() {
    switch (widget.alert.type) {
      case DashboardAlertType.breakStreak:
        return const Color(0xFFA0A0AD);
      case DashboardAlertType.warning:
        return const Color(0xFF8A5055);
      case DashboardAlertType.recovery:
        return const Color(0xFF8A6A3D);
      case DashboardAlertType.nudge:
        return AppTheme.onSurfaceVariant;
      case DashboardAlertType.milestone:
        return const Color(0xFF8B6914);
      case DashboardAlertType.completion:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _getIcon() {
    switch (widget.alert.type) {
      case DashboardAlertType.breakStreak:
        return '💔';
      case DashboardAlertType.warning:
        return '🚨';
      case DashboardAlertType.recovery:
        return '🛡️';
      case DashboardAlertType.nudge:
        return '👋';
      case DashboardAlertType.milestone:
        return '🏆';
      case DashboardAlertType.completion:
        return '🎉';
    }
  }
}
