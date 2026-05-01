import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/avatar_model.dart';
import '../cubit/onboarding_cubit.dart';

class AvatarSelectionScreen extends StatelessWidget {
  final String firstName;
  final String lastName;
  final List<AvatarModel> avatars;
  final String? selectedAvatarId;
  // URLs keyed by avatarKey — signed in parallel by the cubit
  final Map<String, String> avatarUrls;

  const AvatarSelectionScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.avatars,
    this.selectedAvatarId,
    this.avatarUrls = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.read<OnboardingCubit>().startOnboarding(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose your avatar, $firstName!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 40),

              // Avatar grid
              Expanded(
                child: avatars.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No avatars available',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1,
                        ),
                        itemCount: avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = avatars[index];
                          final isSelected = avatar.id == selectedAvatarId;
                          final url = avatarUrls[avatar.avatarKey];

                          return GestureDetector(
                            onTap: () => context
                                .read<OnboardingCubit>()
                                .selectAvatar(avatar.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5C4AE4)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.023),
                                    blurRadius: 9,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Stack(
                                  children: [
                                    // ── Avatar image ──────────────────────
                                    if (url != null)
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                          cacheWidth: 300,
                                          // Show shimmer while the network image loads
                                          loadingBuilder: (ctx, child, prog) {
                                            if (prog == null) return child;
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor:
                                                  Colors.grey[100]!,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          17),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (ctx, _, __) =>
                                              Center(
                                            child: Icon(Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey.shade400),
                                          ),
                                        ),
                                      )
                                    else
                                      // URL not yet signed — shimmer placeholder
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(17),
                                          ),
                                        ),
                                      ),

                                    // ── Selected checkmark ────────────────
                                    if (isSelected)
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF5C4AE4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  children: [
                    if (selectedAvatarId != null)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context
                              .read<OnboardingCubit>()
                              .completeOnboarding(),
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
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (selectedAvatarId == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () =>
                              context.read<OnboardingCubit>().skipAvatar(),
                          child: Text(
                            'Skip for now',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
