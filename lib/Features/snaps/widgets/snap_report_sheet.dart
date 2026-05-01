import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/snap_model.dart';

/// 🚨 SNAP REPORT / BLOCK SHEET
///
/// Bottom sheet for reporting a snap or blocking a user.
/// Shown when tapping options on someone else's snap.
class SnapReportSheet extends StatefulWidget {
  final SnapModel snap;
  final Future<void> Function(String reason, String? details) onReport;
  final Future<void> Function() onBlock;

  const SnapReportSheet({
    super.key,
    required this.snap,
    required this.onReport,
    required this.onBlock,
  });

  @override
  State<SnapReportSheet> createState() => _SnapReportSheetState();
}

class _SnapReportSheetState extends State<SnapReportSheet> {
  bool _showReportForm = false;
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  /// Display label → backend key mapping.
  static const _reasons = {
    'Inappropriate content': 'inappropriate_content',
    'Harassment or bullying': 'harassment',
    'Spam or misleading': 'spam',
    'Other': 'other',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: _showReportForm ? _buildReportForm() : _buildMainMenu(),
      ),
    );
  }

  Widget _buildMainMenu() {
    final userName = widget.snap.senderName;
    final alreadyReported = widget.snap.iReported;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Report option
          _buildOption(
            icon: alreadyReported ? Icons.flag_rounded : Icons.flag_outlined,
            iconColor: AppTheme.accentAmber,
            label: alreadyReported ? 'Already Reported' : 'Report this snap',
            subtitle: alreadyReported
                ? 'You\'ve already flagged this snap'
                : 'Flag for review by our team',
            onTap: alreadyReported
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _showReportForm = true);
                  },
            disabled: alreadyReported,
          ),
          const SizedBox(height: 8),

          // Block option
          _buildOption(
            icon: Icons.block_rounded,
            iconColor: AppTheme.accentRed,
            label: 'Block $userName',
            subtitle: 'You won\'t see their snaps anymore',
            onTap: () => _confirmBlock(userName),
          ),
          const SizedBox(height: 12),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportForm() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Back + title
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showReportForm = false),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.onBackground, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Report Snap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Why are you reporting this snap?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Reason chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.keys.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedReason = reason);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.outline,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    reason,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Optional details
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            child: TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null || _submitting
                  ? null
                  : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.outline,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Report',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(String userName) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.block_rounded,
                    color: AppTheme.accentRed, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Block $userName?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You won\'t see their snaps in any space. They won\'t be notified.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBlock();
            },
            child: Text(
              'Block',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    setState(() => _submitting = true);

    final details = _detailsController.text.trim().isEmpty
        ? null
        : _detailsController.text.trim();

    // Send the backend key, not the display label
    final backendKey = _reasons[_selectedReason!] ?? 'other';
    await widget.onReport(backendKey, details);

    if (mounted) setState(() => _submitting = false);
  }
}
