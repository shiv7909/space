import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/onboarding_cubit.dart';

class NameInputScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  const NameInputScreen({super.key, this.firstName, this.lastName});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Question text
              Text(
                "What's your name?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 60),

              // First name input
              TextField(
                controller: _firstNameController,
                focusNode: _firstNameFocusNode,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'First name',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  _lastNameFocusNode.requestFocus();
                },
              ),

              const SizedBox(height: 30),

              // Last name input
              TextField(
                controller: _lastNameController,
                focusNode: _lastNameFocusNode,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'Last name',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canProceed) {
                    _handleContinue();
                  }
                },
              ),

              const Spacer(),

              // Continue button
              if (_canProceed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C4AE4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    context.read<OnboardingCubit>().proceedToAvatarSelection(
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    );
  }
}
