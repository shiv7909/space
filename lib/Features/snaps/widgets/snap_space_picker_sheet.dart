import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/snap_service.dart';

/// Shows a bottom sheet to pick a space to send a snap to.
/// Returns the selected space's `space_id` or null if cancelled.
Future<String?> showSnapSpacePicker(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const SnapSpacePickerSheet(),
  );
}

class SnapSpacePickerSheet extends StatefulWidget {
  const SnapSpacePickerSheet({super.key});

  @override
  State<SnapSpacePickerSheet> createState() => _SnapSpacePickerSheetState();
}

class _SnapSpacePickerSheetState extends State<SnapSpacePickerSheet> {
  List<Map<String, dynamic>>? _spaces;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final snapService = context.read<SnapService>();
      final spaces = await snapService.getMySnapSpaces();
      if (mounted) {
        setState(() {
          _spaces = spaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Space',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading spaces',
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
              ),
            )
          else if (_spaces == null || _spaces!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'You don\'t have any spaces to post to.',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant),
                ),
              )
            else
              ..._spaces!.map((space) {
                final spaceName = space['space_name'] as String? ?? 'Space';
                final spaceType = space['space_type'] as String? ?? 'couple';
                final spaceId = space['space_id'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, spaceId),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outline),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: spaceType == 'couple' 
                                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.1)
                                  : const Color(0xFF5C4AE4).withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              spaceType == 'couple' ? Icons.favorite_rounded : Icons.group_rounded,
                              color: spaceType == 'couple' ? const Color(0xFFFF6B6B) : const Color(0xFF5C4AE4),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spaceName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  spaceType == 'couple' ? 'Couple Space' : 'Group Space',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
