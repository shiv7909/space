// filepath: d:\habitz\lib\Features\discover\widgets\discover_search_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class DiscoverSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const DiscoverSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<DiscoverSearchBar> createState() => _DiscoverSearchBarState();
}

class _DiscoverSearchBarState extends State<DiscoverSearchBar> {
  Timer? _debounce;

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value.trim());
    });
    // Trigger rebuild for clear button visibility
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: TextField(
        controller: widget.controller,
        onChanged: _onTextChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.onBackground,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search spaces or habits...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon:
              widget.controller.text.isNotEmpty
                  ? GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.onSurfaceVariant,
                      size: 18,
                    ),
                  )
                  : null,
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD4D4D8), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD4D4D8), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
