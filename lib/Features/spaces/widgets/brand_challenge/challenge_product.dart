// ════════════════════════════════════════════════════════════════════
// challenge_product.dart — Product card section
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/brand_challenge_models.dart';
import '../../../../models/brand_theme_data.dart';
import 'challenge_helpers.dart';

class ChallengeProductCard extends StatelessWidget {
  final BrandProductModel product;
  final BrandThemeData theme;
  final double s;

  const ChallengeProductCard({super.key, required this.product, required this.theme, required this.s});

  @override
  Widget build(BuildContext context) {
    final accent = theme.colors.accent;
    final radius = theme.components.cardRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionLabel('EXCLUSIVE DROP', s),
        SizedBox(height: 10 * s),
        Container(
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(radius + 4),
            border: Border.all(color: AppTheme.onBackground.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 84 * s, height: 84 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(colors: [accent.withOpacity(0.08), const Color(0xFF0D0D0D).withOpacity(0.04)]),
                    ),
                    child: product.imageUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Center(child: Icon(Icons.shopping_bag_rounded))))
                        : const Center(child: Text('👟', style: TextStyle(fontSize: 40))),
                  ),
                  SizedBox(width: 14 * s),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: GoogleFonts.plusJakartaSans(fontSize: 18 * s, fontWeight: FontWeight.w900, color: AppTheme.onBackground, height: 1.1, letterSpacing: -0.3)),
                      SizedBox(height: 10 * s),
                      Row(children: [
                        Text(product.formattedPrice, style: GoogleFonts.plusJakartaSans(fontSize: 18 * s, fontWeight: FontWeight.w900, color: AppTheme.onBackground)),
                        SizedBox(width: 8 * s),
                        Text(product.formattedOriginal, style: GoogleFonts.plusJakartaSans(fontSize: 13 * s, color: AppTheme.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                        SizedBox(width: 8 * s),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                          decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(product.discountLabel, style: GoogleFonts.plusJakartaSans(fontSize: 10 * s, fontWeight: FontWeight.w800, color: accent)),
                        ),
                      ]),
                      SizedBox(height: 4 * s),
                      Text(product.stockLabel, style: GoogleFonts.plusJakartaSans(fontSize: 11 * s, fontWeight: FontWeight.w600, color: product.inStock ? AppTheme.onSurfaceVariant : AppTheme.accentRed)),
                    ],
                  )),
                ],
              ),
              if (product.isExclusive) ...[
                SizedBox(height: 12 * s),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  decoration: BoxDecoration(color: accent.withOpacity(0.07), border: Border.all(color: accent.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
                  child: Text('🔥 Exclusive for challenge members', style: GoogleFonts.plusJakartaSans(fontSize: 11 * s, fontWeight: FontWeight.w700, color: accent)),
                ),
              ],
              SizedBox(height: 12 * s),
              SizedBox(
                width: double.infinity, height: 42 * s,
                child: ElevatedButton(
                  onPressed: product.inStock && product.storeUrl != null ? () { /* launch url */ } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.onBackground, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('View Product →', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15 * s, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
