import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/space_visibility.dart';
import '../../../models/category_model.dart';
import '../../../services/category_service.dart';
import '../../../services/space_service.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
// import '../screens/premium_upgrade_screen.dart';
import '../../shared/visibility_picker.dart';
import '../../../core/utils/profanity_checker.dart';
import 'add_member_dialog.dart';

// ── Public helper — call this instead of showDialog ───────────────────────
Future<bool?> showCreateSpaceSheet(
  BuildContext context, {
  String? spaceType,
  VoidCallback? onSpaceCreated,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder:
        (_) => RepositoryProvider.value(
          value: context.read<SpaceService>(),
          child: CreateSpaceSheet(
            spaceType: spaceType,
            onSpaceCreated: onSpaceCreated,
          ),
        ),
  );
}

class CreateSpaceDialog extends StatelessWidget {
  final String? spaceType;
  final VoidCallback? onSpaceCreated;

  const CreateSpaceDialog({super.key, this.spaceType, this.onSpaceCreated});

  @override
  Widget build(BuildContext context) {
    // Legacy wrapper — just opens the sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCreateSpaceSheet(
        context,
        spaceType: spaceType,
        onSpaceCreated: onSpaceCreated,
      );
    });
    return const SizedBox.shrink();
  }
}

// ── The actual sheet widget ─────────────────────────────────────��─────────
class CreateSpaceSheet extends StatefulWidget {
  final String? spaceType;
  final VoidCallback? onSpaceCreated;

  const CreateSpaceSheet({super.key, this.spaceType, this.onSpaceCreated});

  @override
  State<CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends State<CreateSpaceSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();
  late String selectedType;
  final List<String> memberEmails = [];
  final List<String> memberIds = [];
  bool isCreating = false;
  SpaceVisibility _selectedVisibility = SpaceVisibility.private;

  String? _errorMessage;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    selectedType = widget.spaceType ?? 'couple';
    _nameController.addListener(_clearError);
    _descriptionController.addListener(_clearError);
    _loadCategories();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _loadCategories() async {
    final service = CategoryService(
      supabaseClient: context.read<SpaceService>().supabaseClient,
    );
    final cats = await service.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _categoriesLoading = false;
      });
    }
  }

  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getSheetTitle() {
    if (widget.spaceType == 'couple') return 'New Duo Space 💖';
    if (widget.spaceType == 'group') return 'New Squad 🚀';
    if (widget.spaceType == 'solo') return 'Personal Goal 🌱';
    return 'Create Space ✨';
  }

  String _getDescriptionText() {
    if (selectedType == 'couple')
      return 'Create a shared space for you and your partner. You can add shared habits inside!';
    if (selectedType == 'group')
      return 'Create a squad space to challenge friends. You can add group habits inside!';
    if (selectedType == 'solo')
      return 'Create a personal space for your own goals. This is where your habits live.';
    return 'Create a space to organize your habits and track progress.';
  }

  String _getNameHint() {
    if (selectedType == 'couple') return 'e.g. Us Against World ❤️';
    if (selectedType == 'group') return 'e.g. Gym Bros 💪';
    if (selectedType == 'solo') return 'e.g. My Morning Routine ☀️';
    return 'e.g. Healthy Habits';
  }

  // Ensure visibility is always valid when type changes
  void _onTypeChanged(String type) {
    setState(() {
      selectedType = type;
      if (type == 'solo') _selectedVisibility = SpaceVisibility.private;
    });
  }

  /// Called when user picks a visibility chip.
  /// If they pick Nearby, we request location permission first.
  /// Only updates state if permission is granted (or was already granted).
  Future<void> _onVisibilityChanged(SpaceVisibility v) async {
    if (v != SpaceVisibility.nearby) {
      setState(() => _selectedVisibility = v);
      return;
    }

    // ── Nearby selected — check / request permission ──
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // Already granted
      setState(() => _selectedVisibility = SpaceVisibility.nearby);
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      // Can't ask again — send user to app settings
      if (mounted) _showLocationPermanentlyDeniedDialog();
      return;
    }

    // Request permission now
    permission = await Geolocator.requestPermission();

    if (!mounted) return;

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() => _selectedVisibility = SpaceVisibility.nearby);
    } else if (permission == LocationPermission.deniedForever) {
      _showLocationPermanentlyDeniedDialog();
    } else {
      // Denied — show a brief explanation and stay on current selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '📍 Location permission needed for Nearby spaces.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Allow',
            onPressed: _onVisibilityChangedNearbyRetry,
          ),
        ),
      );
    }
  }

  Future<void> _onVisibilityChangedNearbyRetry() async {
    final permission = await Geolocator.requestPermission();
    if (!mounted) return;
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() => _selectedVisibility = SpaceVisibility.nearby);
    } else if (permission == LocationPermission.deniedForever) {
      _showLocationPermanentlyDeniedDialog();
    }
  }

  void _showLocationPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('📍 Location required'),
            content: const Text(
              'You\'ve permanently denied location access.\n\n'
              'To create a Nearby space, please enable location for this app in your device Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTypeFixed = widget.spaceType != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4D4D8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // ── Scrollable body ──
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getSheetTitle(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18181B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF71717A),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescriptionText(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF71717A),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NAME
                  Text('NAME', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF18181B),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: _getNameHint(),
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF4F4F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),

                  // DESCRIPTION
                  const SizedBox(height: 20),
                  Text('DESCRIPTION', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF18181B),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What\'s this space about?',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF4F4F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),

                  // TYPE
                  if (!isTypeFixed) ...[
                    const SizedBox(height: 24),
                    Text('TYPE', style: _labelStyle),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SpaceTypeButton(
                            icon: Icons.person_outline_rounded,
                            label: 'Solo',
                            isSelected: selectedType == 'solo',
                            onTap: () => _onTypeChanged('solo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SpaceTypeButton(
                            icon: Icons.favorite_border_rounded,
                            label: 'Couple',
                            isSelected: selectedType == 'couple',
                            onTap: () => _onTypeChanged('couple'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SpaceTypeButton(
                            icon: Icons.groups_outlined,
                            label: 'Group',
                            isSelected: selectedType == 'group',
                            onTap: () => _onTypeChanged('group'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // VISIBILITY
                  const SizedBox(height: 24),
                  Text('VISIBILITY', style: _labelStyle),
                  const SizedBox(height: 10),
                  if (selectedType == 'solo')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Solo spaces are always Private',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    VisibilityPicker(
                      selected: _selectedVisibility,
                      onChanged: _onVisibilityChanged,
                    ),

                  // CATEGORY
                  const SizedBox(height: 24),
                  Text('CATEGORY', style: _labelStyle),
                  const SizedBox(height: 10),
                  if (_categoriesLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_categories.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No categories available',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _categories.map((cat) {
                            final isSelected = _selectedCategory?.id == cat.id;
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () =>
                                        _selectedCategory =
                                            isSelected ? null : cat,
                                  ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFF18181B)
                                          : const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF18181B)
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cat.emoji,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : const Color(0xFF18181B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                  // MEMBERS
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MEMBERS', style: _labelStyle),
                      InkWell(
                        onTap: _showAddMemberDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xFF18181B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add Person',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (memberEmails.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_disabled,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No members yet',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: memberEmails.length,
                        separatorBuilder:
                            (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFE4E4E7),
                            ),
                        itemBuilder: (context, index) {
                          final label = memberEmails[index];
                          final initial =
                              label.isNotEmpty ? label[0].toUpperCase() : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF18181B),
                              radius: 16,
                              child: Text(
                                initial,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: const Color(0xFF71717A),
                              onPressed:
                                  () => setState(() {
                                    memberEmails.removeAt(index);
                                    memberIds.removeAt(index);
                                  }),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ERROR MESSAGE
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child:
                        _errorMessage == null
                            ? const SizedBox.shrink()
                            : Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD1242F,
                                ).withValues(alpha: 0.06),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD1242F,
                                  ).withValues(alpha: 0.18),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFD1242F,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Color(0xFFD1242F),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Inappropriate Content',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFD1242F),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _errorMessage!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(
                                              0xFFD1242F,
                                            ).withValues(alpha: 0.85),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),

                  // CREATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCreating ? null : _createSpace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child:
                          isCreating
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'CREATE SPACE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF71717A),
    letterSpacing: 0.5,
  );

  void _showAddMemberDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMemberDialog(),
    );
    if (result != null) {
      setState(() {
        final email = result['email'] as String? ?? '';
        final displayName = result['displayName'] as String? ?? 'User';
        memberEmails.add(email.isNotEmpty ? email : displayName);
        memberIds.add(result['userId'] as String);
      });
    }
  }

  void _createSpace() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a space name');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a space description');
      return;
    }

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category');
      _scrollToError();
      return;
    }

    final nameHasProfanity = ProfanityChecker.containsProfanity(
      _nameController.text.trim(),
    );
    final descHasProfanity = ProfanityChecker.containsProfanity(
      _descriptionController.text.trim(),
    );

    if (nameHasProfanity || descHasProfanity) {
      setState(
        () =>
            _errorMessage =
                nameHasProfanity
                    ? 'Your space name contains inappropriate language. Please choose a different name.'
                    : 'Your description contains inappropriate language. Please reword it.',
      );
      _scrollToError();
      return;
    }

    /*
    if (selectedType == 'couple' || selectedType == 'group') {
      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded && !profileState.profile.isPremium) {
        if (mounted) {
          final upgraded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumUpgradeScreen()),
          );
          if (upgraded != true) return;
        }
      }
    }
    */

    setState(() => isCreating = true);

    try {
      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        final spaceService = context.read<SpaceService>();

        final space = await spaceService.createSpace(
          name: _nameController.text.trim(),
          type: selectedType,
          visibility: _selectedVisibility.value,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategory?.id,
        );

        int invitesSent = 0;
        for (final memberId in memberIds) {
          try {
            final result = await spaceService.sendInviteByScan(
              userId: memberId,
              spaceId: space.id,
            );
            if (result['success'] == true) invitesSent++;
          } catch (e) {
            print('🟡 Failed to send invite to $memberId: $e');
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
          final message =
              memberIds.isEmpty
                  ? 'Space "${_nameController.text.trim()}" created! 🎉'
                  : invitesSent > 0
                  ? 'Space created! $invitesSent invite${invitesSent > 1 ? 's' : ''} sent 🕐'
                  : 'Space created! 🎉';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF18181B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create space: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }
}

class _SpaceTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SpaceTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF71717A),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF71717A),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
