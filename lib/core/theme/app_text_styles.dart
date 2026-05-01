import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// SPACE APP — GEN Z TYPOGRAPHY SYSTEM
/// Font: Plus Jakarta Sans (Google Fonts)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AppText {
  AppText._();

  /// Hero progress percentage — 42px w600 white
  static TextStyle heroNumber = GoogleFonts.plusJakartaSans(
    fontSize: 42,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -2,
  );

  /// Hero title (e.g. "left to do") — 26px w500 white
  static TextStyle heroTitle = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: -0.8,
  );

  /// Screen / section headers — 22px w600
  static TextStyle screenTitle = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Card title / habit name — 15px w600
  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Body / subtitle — 13px w400
  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecond,
  );

  /// Label / uppercase tag — 11px w500
  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
  );

  /// Micro / stat label — 10px w400
  static TextStyle micro = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Tab text — active 13px w600 white
  static TextStyle tabActive = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// Tab text — inactive 13px w400 muted
  static TextStyle tabInactive = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Stat block number (inside hero) — 16px w500
  static TextStyle statNumber = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  /// Stat block label (inside hero) — 10px white 50%
  static TextStyle statLabel = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Colors.white54,
  );

  /// Nav label active — 10px w500
  static TextStyle navLabelActive = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.navActiveIcon,
  );

  /// Nav label inactive — 10px w400
  static TextStyle navLabelInactive = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.navInactiveIcon,
  );

  // ═══════════════════════════════════════════════════
  // HELPER — get the font family string for TextStyle
  // ═══════════════════════════════════════════════════
  static String get fontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily ?? 'Plus Jakarta Sans';
}
