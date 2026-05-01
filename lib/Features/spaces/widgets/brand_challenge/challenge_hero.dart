import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import 'challenge_helpers.dart';

class ChallengeHeroSection extends StatelessWidget {
  final ChallengeHeaderModel header;
  final BrandThemeData theme;
  final double s;
  final double topOffset;

  const ChallengeHeroSection({
    super.key,
    required this.header,
    required this.theme,
    required this.s,
    required this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    final c = theme.colors;
    final t = theme.typography;
    final vibe = theme.vibe;
    final titleRaw = t.transform(header.title);
    final titleParts = titleRaw.split(' ');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (header.bannerUrl != null && header.bannerUrl!.isNotEmpty) ...[
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: CachedNetworkImage(imageUrl: header.bannerUrl!, fit: BoxFit.cover)),
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.3, 1.0])))),
        ] else ...[
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: Container(color: vibe.isDarkHero ? const Color(0xFF0D0D0D) : c.heroBgStart)),
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: Container(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0.6, -0.5), radius: 1.6, colors: [c.heroGlow.withValues(alpha: 0.12), Colors.transparent])))),
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: Container(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(-0.8, 0.6), radius: 1.6, colors: [c.info.withValues(alpha: 0.04), Colors.transparent])))),
          Positioned(top: -topOffset, left: 0, right: 0, bottom: 0, child: CustomPaint(painter: GridPainter(color: vibe.isDarkHero ? Colors.white.withValues(alpha: 0.025) : c.heroBgEnd.withValues(alpha: 0.5), spacing: 28 * s, thickness: 1.0))),
        ],
        Padding(
          padding: EdgeInsets.only(top: 8 * s, left: 20 * s, right: 20 * s, bottom: 22 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38 * s, height: 38 * s,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10 * s)),
                    child: header.brand.logoUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10 * s), child: Container(color: Colors.white, padding: EdgeInsets.all(5 * s), child: CachedNetworkImage(imageUrl: header.brand.logoUrl!, fit: BoxFit.contain, errorWidget: (_, __, ___) => Center(child: Text(t.transform(brandInitials(header.brand.name)), style: t.headingStyle(size: 11 * s, color: const Color(0xFF0D0D0D)))))))
                        : Center(child: Text(t.transform(brandInitials(header.brand.name)), style: t.headingStyle(size: 11 * s, color: const Color(0xFF0D0D0D)))),
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      t.transform(header.brand.name),
                      style: t.headingStyle(size: 15 * s, color: vibe.isDarkHero ? Colors.white.withValues(alpha: 0.6) : c.textSecondary, letterSpacing: 1.0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18 * s),
              if (header.titleSegments.isNotEmpty) _buildSegmentsTitle(header.titleSegments, c, t, vibe, s)
              else if (header.heroConfig != null && header.heroConfig!.lines.isNotEmpty) _buildHeroTitleWithConfig(header.heroConfig!, c, t, vibe, s)
              else _buildSimpleTitleFallback(titleRaw, titleParts, c, t, vibe, s),
              SizedBox(height: 14 * s),
              Wrap(
                spacing: 7 * s, runSpacing: 7 * s,
                children: [
                  _buildDynamicTag('${header.durationDays} Days', c.accent, Colors.white, Colors.transparent, t, s),
                  _buildDynamicTag(t.transform(header.habit.name), vibe.isDarkHero ? Colors.white.withValues(alpha: 0.1) : c.textPrimary.withValues(alpha: 0.05), vibe.isDarkHero ? Colors.white.withValues(alpha: 0.85) : c.textSecondary, vibe.isDarkHero ? Colors.white.withValues(alpha: 0.15) : c.border, t, s),
                  _buildDynamicTag('Win Rewards', vibe.isDarkHero ? const Color(0xFFFFC107).withValues(alpha: 0.15) : const Color(0xFFFFF8E1), vibe.isDarkHero ? const Color(0xFFFFD54F) : const Color(0xFFF57F17), vibe.isDarkHero ? const Color(0xFFFFC107).withValues(alpha: 0.3) : const Color(0xFFFFCC80), t, s),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTitleFallback(String titleRaw, List<String> titleParts, BrandColors c, BrandTypography t, BrandVibeConfig vibe, double s) {
    return RichText(text: TextSpan(style: t.headingStyle(size: 32 * s, color: vibe.isDarkHero ? Colors.white : c.textPrimary, height: 0.95, letterSpacing: -0.5), children: [if (titleParts.length > 1) ...[TextSpan(text: ' \n'), TextSpan(text: titleParts.last, style: TextStyle(color: c.accent))] else TextSpan(text: titleRaw)]));
  }

  Widget _buildSegmentsTitle(List<TextSegment> segments, BrandColors c, BrandTypography t, BrandVibeConfig vibe, double s) {
    return RichText(text: TextSpan(style: t.headingStyle(size: 32 * s, color: vibe.isDarkHero ? Colors.white : c.textPrimary, height: 0.95, letterSpacing: -0.5), children: segments.map((seg) => TextSpan(text: seg.text, style: TextStyle(color: seg.highlight ? c.accent : (vibe.isDarkHero ? Colors.white : c.textPrimary)))).toList()));
  }

  Widget _buildHeroTitleWithConfig(HeroConfig config, BrandColors c, BrandTypography t, BrandVibeConfig vibe, double s) {
    final lines = <RichText>[];
    for (int lineIdx = 0; lineIdx < config.lines.length; lineIdx++) {
      final line = config.lines[lineIdx];
      final isHighlightLine = lineIdx == config.highlightLine;
      final words = line.split(' ');
      final textSpans = <TextSpan>[];
      for (int wordIdx = 0; wordIdx < words.length; wordIdx++) {
        final word = words[wordIdx];
        final isHighlightWord = isHighlightLine && word == config.highlightWord;
        textSpans.add(TextSpan(text: word, style: TextStyle(color: isHighlightWord ? c.accent : (vibe.isDarkHero ? Colors.white : c.textPrimary), fontWeight: isHighlightWord ? FontWeight.w900 : FontWeight.w700)));
        if (wordIdx < words.length - 1) textSpans.add(const TextSpan(text: ' '));
      }
      lines.add(RichText(text: TextSpan(style: t.headingStyle(size: 28 * s, color: vibe.isDarkHero ? Colors.white : c.textPrimary, height: 0.96, letterSpacing: -0.5), children: textSpans)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines);
  }

  Widget _buildDynamicTag(String text, Color bg, Color textColor, Color borderColor, BrandTypography t, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
      child: Text(text, style: t.bodyStyle(size: 11 * s, weight: FontWeight.w700, color: textColor)),
    );
  }
}
