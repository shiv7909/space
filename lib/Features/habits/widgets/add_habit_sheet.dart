import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/habit_emojis.dart';
import '../../../services/space_service.dart';
import '../../../services/category_service.dart';
import '../../../models/space_model.dart';
import '../../../models/habit_model.dart';
import '../../../models/category_model.dart';
import '../../../screens/cinematic_payload.dart';
import '../../../core/utils/profanity_checker.dart';
import '../../../screens/habit_success_cinematic_screen.dart';

class AddHabitSheet extends StatefulWidget {
  final String? spaceId;

  const AddHabitSheet({super.key, this.spaceId});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameController = TextEditingController();
  final _whyController = TextEditingController();
  final _targetDaysController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedEmoji = HabitEmojis.defaultEmoji;
  String _habitMode = 'infinite';
  List<int> _scheduledDays = [];
  String? _selectedSpaceId;
  String _selectedSpaceType = 'solo';

  bool _isLoading = false;
  bool _isValid = false;
  bool _showEmojiPicker = false;
  int _selectedCategoryIndex = 0;

  String? _errorMessage;

  List<SpaceModel> _userSpaces = [];
  bool _loadingSpaces = true;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;

  // ── Design tokens — aligned with AppTheme ──
  static const _dark = AppTheme.onBackground;
  static const _textSecondary = AppTheme.onSurfaceVariant;
  static const _border = AppTheme.outline;
  static const _surfaceVariant = AppTheme.surfaceVariant;
  static const _bg = AppTheme.background;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validate);
    _targetDaysController.addListener(_validate);

    // ── Pre-set space selection if spaceId is provided ──
    if (widget.spaceId != null) {
      _selectedSpaceId = widget.spaceId;
    }

    _loadSpaces();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final service = CategoryService(
        supabaseClient: context.read<SpaceService>().supabaseClient,
      );
      final cats = await service.getCategories();
      if (mounted)
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadSpaces() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final spaceService = context.read<SpaceService>();
      final spaces = await spaceService.getUserSpaces(userId);
      if (mounted) {
        setState(() {
          _userSpaces = spaces;
          _loadingSpaces = false;

          // ── Priority 1: Use the passed spaceId if provided ──
          if (widget.spaceId != null) {
            _selectedSpaceId = widget.spaceId;
            // Find the space to get its type
            final matchingSpace =
                spaces.where((s) => s.id == widget.spaceId).firstOrNull;
            if (matchingSpace != null) {
              _selectedSpaceType = matchingSpace.type;
            }
          } else {
            // ── Priority 2: Default to solo space if no spaceId provided ──
            final soloSpaces = spaces.where((s) => s.type == 'solo');
            if (soloSpaces.isNotEmpty) {
              _selectedSpaceId = soloSpaces.first.id;
              _selectedSpaceType = 'solo';
            } else if (spaces.isNotEmpty) {
              // Fallback: use first available space
              _selectedSpaceId = spaces.first.id;
              _selectedSpaceType = spaces.first.type;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSpaces = false);
        // Even if spaces fail to load, keep the selected space info
      }
    }
  }

  void _validate() {
    setState(() {
      final isNameValid = _nameController.text.trim().isNotEmpty;
      final isTargetValid =
          _habitMode == 'infinite' ||
          (_targetDaysController.text.trim().isNotEmpty &&
              int.tryParse(_targetDaysController.text.trim()) != null);
      final isDaysValid = _scheduledDays.isNotEmpty;
      final isCategoryValid = _selectedCategory != null;
      _isValid = isNameValid && isTargetValid && isDaysValid && isCategoryValid;
      if (_errorMessage != null) _errorMessage = null;
    });
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

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    final nameHasProfanity = ProfanityChecker.containsProfanity(
      _nameController.text.trim(),
    );
    final whyHasProfanity = ProfanityChecker.containsProfanity(
      _whyController.text.trim(),
    );

    if (nameHasProfanity || whyHasProfanity) {
      setState(() {
        _errorMessage =
            nameHasProfanity
                ? 'Your habit name contains inappropriate language. Please choose a different name.'
                : 'Your motivation text contains inappropriate language. Please reword it.';
        _isLoading = false;
      });
      _scrollToError();
      return;
    }

    try {
      final spaceService = context.read<SpaceService>();
      int? targetDays;
      if (_habitMode == 'challenge') {
        targetDays = int.tryParse(_targetDaysController.text.trim());
      }

      final response = await spaceService.addSmartHabit(
        name: _nameController.text.trim(),
        whyReason:
            _whyController.text.trim().isEmpty
                ? null
                : _whyController.text.trim(),
        emoji: _selectedEmoji,
        mode: _habitMode,
        targetDays: targetDays,
        scheduledDays: _scheduledDays,
        spaceId: _selectedSpaceId,
        categoryId: _selectedCategory?.id,
      );

      if (!mounted) return;

      // Close the sheet first
      Navigator.pop(context, true);

      // Build a HabitModel from the RPC response
      final habitData = response['habit'] as Map<String, dynamic>?;
      final createdHabit = HabitModel(
        id: (habitData?['id'] ?? response['habit_id'] ?? '').toString(),
        name: habitData?['name'] ?? _nameController.text.trim(),
        whyReason: habitData?['why_reason'] ?? _whyController.text.trim(),
        emoji: habitData?['emoji'] ?? _selectedEmoji,
        mode: habitData?['mode'] ?? _habitMode,
        targetDays: habitData?['target_days'] as int? ?? targetDays,
        scheduledDays:
            (habitData?['scheduled_days'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            _scheduledDays,
        spaceId:
            (habitData?['space_id'] ?? response['space_id'] ?? _selectedSpaceId)
                ?.toString(),
        createdAt: DateTime.now(),
      );

      // Always use locally-known space type — backend 'space_type' was previously bugged
      final spaceType = _selectedSpaceType;

      // Launch cinematic SUCCESS screen only
      Navigator.of(context).push(
        HabitSuccessCinematicScreen.route(
          CinematicPayload(
            habit: createdHabit,
            spaceType: spaceType,
            success: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorString = e.toString().replaceFirst('Exception: ', '');

      if (errorString.startsWith('HABIT_LIMIT_REACHED|')) {
        final actualMessage = errorString.split('|').last;
        
        // Show a premium dialog for limit reached
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                Text(
                  'Limit Reached',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              actualMessage,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got it',
                  style: GoogleFonts.plusJakartaSans(
                     color: const Color(0xFFD4B1FF),
                     fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        return; // don't fall through to finally's setState
      }

      // Show a clean SnackBar for other errors — no black screen, no navigation
      final message = errorString;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 4),
        ),
      );
      return; // don't fall through to finally's setState
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whyController.dispose();
    _targetDaysController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_scheduledDays.contains(day)) {
        _scheduledDays.remove(day);
      } else {
        _scheduledDays.add(day);
        _scheduledDays.sort();
      }
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle + Close row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
              child: Row(
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _textSecondary,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══ EMOJI + NAME ROW ═══
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Emoji tap-to-pick button
                        GestureDetector(
                          onTap:
                              () => setState(
                                () => _showEmojiPicker = !_showEmojiPicker,
                              ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _showEmojiPicker ? _dark : _surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showEmojiPicker ? _dark : _border,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _selectedEmoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name input
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            autofocus: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Habit name...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            cursorColor: _dark,
                            cursorWidth: 2.5,
                          ),
                        ),
                      ],
                    ),

                    // ═══ EMOJI PICKER ═══
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildEmojiPicker(),
                      crossFadeState:
                          _showEmojiPicker
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),

                    const SizedBox(height: 20),

                    // ═══ SPACE SELECTOR ═══
                    // Hide when spaceId is pre-set (opened from a specific space)
                    if (widget.spaceId == null) ...[
                      _buildSectionLabel('SPACE'),
                      const SizedBox(height: 8),
                      _buildSpaceSelector(),
                      const SizedBox(height: 20),
                    ],

                    // ═══ WHY / MOTIVATION ═══
                    _buildSectionLabel('WHY THIS HABIT?'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: TextField(
                        controller: _whyController,
                        maxLines: 2,
                        minLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _dark,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'I want to become...',
                          hintStyle: GoogleFonts.inter(
                            color: _textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: _dark,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ═══ MODE SELECTION ═══
                    _buildSectionLabel('MODE'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeChip('Forever', '∞', 'infinite'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildModeChip('Challenge', '🎯', 'challenge'),
                        ),
                      ],
                    ),

                    // Target days (challenge only)
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: TextField(
                            controller: _targetDaysController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'How many days? (e.g. 30)',
                              hintStyle: GoogleFonts.inter(
                                color: _textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            cursorColor: _dark,
                          ),
                        ),
                      ),
                      crossFadeState:
                          _habitMode == 'challenge'
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),

                    const SizedBox(height: 20),

                    // ═══ CATEGORY SELECTOR ═══
                    _buildSectionLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    _buildCategorySelector(),

                    const SizedBox(height: 20),

                    // ═══ FREQUENCY ═══
                    _buildSectionLabel('REPEAT'),
                    const SizedBox(height: 8),
                    _buildDaySelector(),

                    const SizedBox(height: 28),

                    // ═══ ERROR MESSAGE ═══
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
                                  color: AppTheme.accentRed.withValues(
                                    alpha: 0.06,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.accentRed.withValues(
                                      alpha: 0.18,
                                    ),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentRed.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: AppTheme.accentRed,
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
                                              color: AppTheme.accentRed,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _errorMessage!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.accentRed
                                                  .withValues(alpha: 0.85),
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

                    // ═══ SUBMIT BUTTON ═══
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isValid && !_isLoading ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: _surfaceVariant,
                          disabledForegroundColor: _textSecondary,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Create Habit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // SECTION LABEL
  // ────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: _textSecondary,
      ),
    );
  }

  // ────────────────────────────────────────────────
  // EMOJI PICKER — Category tabs + emoji grid
  // ────────────────────────────────────────────────
  Widget _buildEmojiPicker() {
    final categories = HabitEmojis.categories;
    final currentCategory = categories[_selectedCategoryIndex];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children:
                    categories.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cat = entry.value;
                      final isActive = idx == _selectedCategoryIndex;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap:
                              () =>
                                  setState(() => _selectedCategoryIndex = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? _dark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? _dark : _border,
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat.icon,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.white : _dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Emoji grid
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  currentCategory.emojis.map((emoji) {
                    final isSelected = _selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = emoji;
                          _showEmojiPicker = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? _dark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _dark : _border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // SPACE SELECTOR
  // ────────────────────────────────────────────────
  Widget _buildSpaceSelector() {
    if (_loadingSpaces) {
      return Container(
        height: 40,
        alignment: Alignment.centerLeft,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: _textSecondary,
          ),
        ),
      );
    }

    if (_userSpaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, size: 14, color: _textSecondary),
            const SizedBox(width: 6),
            Text(
              'Solo (default)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            _userSpaces.map((space) {
              final isSelected = _selectedSpaceId == space.id;
              final icon = _spaceIcon(space.type);
              final label = space.type == 'solo' ? 'Solo' : space.name;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap:
                      () => setState(() {
                        _selectedSpaceId = space.id;
                        _selectedSpaceType = space.type;
                      }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _dark : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _dark : _border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: isSelected ? Colors.white : _textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  IconData _spaceIcon(String type) {
    switch (type) {
      case 'couple':
        return Icons.favorite_rounded;
      case 'group':
        return Icons.groups_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ────────────────────────────────────────────────
  // MODE CHIP
  // ────────────────────────────────────────────────
  Widget _buildModeChip(String title, String icon, String mode) {
    final isSelected = _habitMode == mode;
    return GestureDetector(
      onTap:
          () => setState(() {
            _habitMode = mode;
            _validate();
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _dark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _dark : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : _dark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // CATEGORY SELECTOR
  // ────────────────────────────────────────────────
  Widget _buildCategorySelector() {
    if (_loadingCategories) {
      return Container(
        height: 40,
        alignment: Alignment.centerLeft,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: _textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? null : category;
                    });
                    _validate();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _dark : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _dark : _border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // DAY SELECTOR
  // ────────────────────────────────────────────────
  Widget _buildDaySelector() {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _scheduledDays.contains(dayIndex);
        return GestureDetector(
          onTap: () => _toggleDay(dayIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? _dark : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _dark : _border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[index],
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : _textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
