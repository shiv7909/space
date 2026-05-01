import 'package:flutter/material.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// SPACE APP — GEN Z BORDER RADIUS SYSTEM
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AppRadius {
  AppRadius._();

  // ── Raw values ──
  static const double pillValue = 99;
  static const double buttonValue = 12;
  static const double cardValue = 20;
  static const double largeCardValue = 24;
  static const double heroCardValue = 28;
  static const double iconContainerValue = 14;
  static const double tabSelectorValue = 14;
  static const double tabItemValue = 10;
  static const double progressBarValue = 99;

  // ── BorderRadius shortcuts ──
  static final pill = BorderRadius.circular(99);
  static final button = BorderRadius.circular(12);
  static final card = BorderRadius.circular(20);
  static final largeCard = BorderRadius.circular(24);
  static final heroCard = BorderRadius.circular(28);
  static final iconContainer = BorderRadius.circular(14);
  static final tabSelector = BorderRadius.circular(14);
  static final tabItem = BorderRadius.circular(10);
  static final progressBar = BorderRadius.circular(99);

  /// Hero white overlap below hero section
  static const heroOverlap = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );
}
