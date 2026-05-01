import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'delete_account_sheet.dart';

class AccountSettingsMenu extends StatelessWidget {
  const AccountSettingsMenu({super.key});

  /// Show the account settings menu from anywhere
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountSettingsMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Account Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Support Option
            _SettingsOption(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFF6B6BE0),
              iconBg: const Color(0xFF6B6BE0).withValues(alpha: 0.1),
              title: 'Contact Support',
              subtitle: 'Get help with your account',
              onTap: () {
                // Capture the messenger before popping so we don't use a deactivated context
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                // TODO: Implement contact support functionality
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Opening support...'),
                    backgroundColor: AppTheme.onSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Manage Account Option
            _SettingsOption(
              icon: Icons.settings_outlined,
              iconColor: const Color(0xFF9575CD),
              iconBg: const Color(0xFF9575CD).withValues(alpha: 0.1),
              title: 'Manage Account',
              subtitle: 'Privacy, data, and more',
              onTap: () {
                // Don't pop here to keep context alive for the child sheet
                // Navigator.of(context).pop();
                _showManageAccountMenu(context);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Show the manage account submenu
  static void _showManageAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Back Button + Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                      },
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.onBackground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Manage Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Delete Account Option (Danger Zone)
              _SettingsOption(
                icon: Icons.delete_forever_rounded,
                iconColor: AppTheme.accentRed,
                iconBg: AppTheme.accentRed.withValues(alpha: 0.1),
                title: 'Delete Account',
                subtitle: 'Permanently remove your account',
                isDestructive: true,
                onTap: () {
                  // Show delete sheet on top of current sheet using valid sheetContext
                  DeleteAccountSheet.show(sheetContext);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.accentRed.withValues(alpha: 0.02)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: isDestructive
              ? Border.all(
                  color: AppTheme.accentRed.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? AppTheme.accentRed
                          : AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
