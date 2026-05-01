import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/discover_models.dart';

/// Bottom sheet that lets the user pick one of their spaces to invite someone to.
class InviteSpacePicker extends StatelessWidget {
  final List<InvitableSpace> spaces;
  final void Function(String spaceId) onSelect;

  const InviteSpacePicker({
    super.key,
    required this.spaces,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Invite to which space?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            ...spaces.map((s) => ListTile(
              leading: Text(
                s.categoryEmoji ?? '🏠',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                s.spaceName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
              subtitle: Text(
                '${s.spaceType} · ${s.spotsLeft} members',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              onTap: () => onSelect(s.spaceId),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

