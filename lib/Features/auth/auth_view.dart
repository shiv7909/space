import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';
import '../../core/routes/app_router.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _agreedToTerms = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showTermsRequiredDialog() {
    // Show a sleek snackbar if terms are not accepted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please agree to the Terms of Service & Privacy Policy to continue.',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. OLED Black Background for that infinite canvas feel
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            if (state.needsOnboarding) {
              Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
            } else {
              Navigator.of(context).pushReplacementNamed(AppRouter.home);
            }
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white, // Stark white loader
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App Name - Stark White, tighter letter spacing
                  Text(
                        'SPACE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 42, // Slightly larger
                          fontWeight: FontWeight.w900, // Heavier weight
                          color: Colors.white,
                          letterSpacing:
                              -1.5, // Tighter tracking for modern look
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 200.ms,
                        duration: 600.ms,
                        curve: Curves.easeOutExpo,
                      ),

                  const SizedBox(height: 8),

                  // Tagline - use Space Grotesk to match splash and be consistent
                  Text(
                        'Win your day. Alone or together.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: 350.ms,
                        duration: 600.ms,
                        curve: Curves.easeOutExpo,
                      ),

                  const Spacer(flex: 3),

                  // Premium Solid White Google Sign-In Button
                  SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_agreedToTerms) {
                              context.read<AuthCubit>().signInWithGoogle();
                            } else {
                              _showTermsRequiredDialog();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google logo from SVG asset
                              SvgPicture.asset(
                                'assets/Svg/GOOGLE.svg',
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 500.ms,
                        duration: 600.ms,
                        curve: Curves.easeOutExpo,
                      ),

                  const SizedBox(height: 24),

                  // Terms and Privacy Checkbox - Premium styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color:
                                _agreedToTerms
                                    ? Colors.white
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  _agreedToTerms
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child:
                              _agreedToTerms
                                  ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.black,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap =
                                          () => _launchUrl(
                                            'https://spaceapp.page/terms.html',
                                          ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap =
                                          () => _launchUrl(
                                            'https://spaceapp.page/privacy.html',
                                          ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 650.ms, duration: 600.ms),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
