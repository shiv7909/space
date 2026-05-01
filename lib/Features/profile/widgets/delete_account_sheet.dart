import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  /// Call this to show the sheet from anywhere
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => DeleteAccountCubit(Supabase.instance.client),
        child: const DeleteAccountSheet(),
      ),
    );
  }

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: (blocContext, state) {
        // Always ensure the State is still mounted before interacting with navigation
        if (!mounted) return;

        if (state is DeleteAccountSuccess) {
          // Close sheet and navigate to login
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.auth,
            (route) => false,
          );
        }
        if (state is DeleteAccountError) {
          // Capture messenger before popping so we don't use a deactivated context
          final messenger = ScaffoldMessenger.of(context);
          if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // close sheet
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
        builder: (context, state) {
          final isLoading = state is DeleteAccountLoading;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B6BE0).withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: AppTheme.accentRed,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ─────────────────────────────────────────
                Text(
                  'Delete Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Warning text ──────────────────────────────────
                Text(
                  'This will permanently delete your account, all your spaces, habits, logs, and data. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // ── What gets deleted list ────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentRed.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DeleteItem('All your spaces and habits'),
                      _DeleteItem('All habit logs and streaks'),
                      _DeleteItem('Your profile and photo'),
                      _DeleteItem('All connections and requests'),
                      _DeleteItem('Your login account'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Delete button ─────────────────────────────────
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () {
                          context.read<DeleteAccountCubit>().deleteAccount();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isLoading
                          ? AppTheme.accentRed.withValues(alpha: 0.5)
                          : AppTheme.accentRed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Yes, Delete My Account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Cancel button ─────────────────────────────────
                GestureDetector(
                  onTap: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLoading
                          ? AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeleteItem extends StatelessWidget {
  final String text;
  const _DeleteItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline_rounded,
            size: 14,
            color: AppTheme.accentRed,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentRed,
            ),
          ),
        ],
      ),
    );
  }
}
