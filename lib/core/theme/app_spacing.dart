import 'package:flutter/material.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// SPACE APP — GEN Z SPACING SYSTEM
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AppSpacing {
  AppSpacing._();

  // ── Raw values ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double hero = 32;

  // ── Semantic spacing ──
  /// Default screen horizontal padding (16px both sides)
  static const double screenH = 16;

  /// Card internal horizontal padding
  static const double cardH = 16;

  /// Card internal vertical padding
  static const double cardV = 14;

  /// Gap between cards
  static const double cardGap = 8;

  /// Gap between sections
  static const double sectionGap = 20;

  // ── EdgeInsets shortcuts ──
  static const screenPadding = EdgeInsets.symmetric(horizontal: 16);

  static const cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  static const sectionPaddingH = EdgeInsets.symmetric(horizontal: 16);
}
