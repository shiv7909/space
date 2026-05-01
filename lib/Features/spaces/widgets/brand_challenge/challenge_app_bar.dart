import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import 'challenge_helpers.dart';

class ChallengeAppBar extends StatelessWidget {
  final ChallengeHeaderModel header;
  final BrandThemeData theme;
  final BrandTypography brandTyp;
  final double s;
  final ValueNotifier<double> scrollOffset;
  final VoidCallback? onShareTap;

  const ChallengeAppBar({
    super.key,
    required this.header,
    required this.theme,
    required this.brandTyp,
    required this.s,
    required this.scrollOffset,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      toolbarHeight: 64 * s,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        builder: (ctx, offset, _) {
          final threshold = 120 * s;
          final fadeRange = 50 * s;
          final progress = ((offset - threshold) / fadeRange).clamp(0.0, 1.0);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18 * progress, sigmaY: 18 * progress),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: progress * 0.92),
                  border: Border(bottom: BorderSide(color: AppTheme.onBackground.withValues(alpha: progress * 0.06), width: 0.5)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
                    child: Row(
                      children: [
                        navCircle(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(ctx), s),
                        const Spacer(),
                        // ── Brand name (fades in on scroll) ──
                        Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, (1 - progress) * 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22 * s, height: 22 * s,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6 * s)),
                                  child: header.brand.logoUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6 * s),
                                          child: Container(
                                            color: Colors.white, padding: EdgeInsets.all(3 * s),
                                            child: CachedNetworkImage(imageUrl: header.brand.logoUrl!, fit: BoxFit.contain),
                                          ),
                                        )
                                      : Center(child: Text(brandInitials(header.brand.name), style: TextStyle(fontSize: 7 * s, fontWeight: FontWeight.w900))),
                                ),
                                SizedBox(width: 7 * s),
                                Text(
                                  brandTyp.transform(header.brand.name),
                                  style: brandTyp.headingStyle(size: 14 * s, color: AppTheme.onBackground, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        navCircle(Icons.share_rounded, onShareTap ?? () {}, s),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
