// filepath: d:\habitz\lib\Features\discover\screens\join_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/user_avatar_widget.dart';
import '../cubit/join_requests_cubit.dart';
import '../cubit/join_requests_state.dart';
import '../models/discover_models.dart';

class JoinRequestsScreen extends StatelessWidget {
  final String spaceId;
  final String spaceName;

  const JoinRequestsScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JoinRequestsCubit(Supabase.instance.client, spaceId: spaceId)
            ..loadRequests(),
      child: _JoinRequestsBody(spaceName: spaceName),
    );
  }
}

class _JoinRequestsBody extends StatelessWidget {
  final String spaceName;
  const _JoinRequestsBody({required this.spaceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
            ),
            Text(
              spaceName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<JoinRequestsCubit, JoinRequestsState>(
        builder: (context, state) {
          if (state.status == JoinRequestsStatus.loading) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.onBackground,
                ),
              ),
            );
          }

          if (state.status == JoinRequestsStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    state.error ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<JoinRequestsCubit>().loadRequests(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New requests will appear here',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<JoinRequestsCubit>().loadRequests(),
            color: AppTheme.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final isProcessing =
                    state.processingIds.contains(request.requestId);
                return _JoinRequestCard(
                  request: request,
                  isProcessing: isProcessing,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequest request;
  final bool isProcessing;

  const _JoinRequestCard({
    required this.request,
    required this.isProcessing,
  });

  Future<void> _handleAction(BuildContext context, String action) async {
    final cubit = context.read<JoinRequestsCubit>();
    final error = await cubit.handleRequest(request.requestId, action);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (error == null && context.mounted) {
      final actionLabel = action == 'accept' ? 'accepted' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${request.requesterName.split(' ').first} $actionLabel'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(request.requestedAt);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isProcessing ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name + time ──
            Row(
              children: [
                UserAvatarWidget(
                  photoKey: request.requesterPhotoKey,
                  name: request.requesterName,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Message ──
            if (request.message != null &&
                request.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${request.message}"',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Accept / Reject buttons ──
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '✗ Reject',
                    color: AppTheme.accentRed,
                    isProcessing: isProcessing,
                    onTap: () => _handleAction(context, 'reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: '✓ Accept',
                    color: AppTheme.accentGreen,
                    filled: true,
                    isProcessing: isProcessing,
                    onTap: () => _handleAction(context, 'accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool isProcessing;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.filled = false,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: isProcessing
            ? SizedBox(
                height: 16,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? Colors.white : color,
                    ),
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
              ),
      ),
    );
  }
}

