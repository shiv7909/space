import 'package:flutter/material.dart';

/// 🎨 2026 GLASSMORPHISM GRADIENT SYSTEM
///
/// Three official gradient sets for habit shape icons:
/// 1. Cyber-Solar  — Fitness/Energy (gold → orange)
/// 2. Deep Hydration — Wellness/Water (cyan → blue)
/// 3. Focus Neon   — Productivity/Code (purple → deep purple)
///
/// Each gradient also carries a glow color for the subtle
/// outer shadow ("saturated shadow") effect.

class ShapeGradientSet {
  final Color start;
  final Color end;
  final Alignment beginAlign;
  final Alignment endAlign;
  final Color glowColor;
  final double fillOpacity;

  const ShapeGradientSet({
    required this.start,
    required this.end,
    this.beginAlign = Alignment.topLeft,
    this.endAlign = Alignment.bottomRight,
    required this.glowColor,
    this.fillOpacity = 0.85,
  });

  LinearGradient get gradient =>
      LinearGradient(colors: [start, end], begin: beginAlign, end: endAlign);
}

class ShapeGradients {
  ShapeGradients._();

  // ═══════════════════════════════════════════════
  // 1. CYBER-SOLAR — Fitness / Energy
  // ═══════════════════════════════════════════════
  static const cyberSolar = ShapeGradientSet(
    start: Color(0xFFFFD700),
    end: Color(0xFFFF8C00),
    beginAlign: Alignment.topLeft,
    endAlign: Alignment.bottomRight,
    glowColor: Color(0x1AFFD700), // 10% opacity
    fillOpacity: 0.85,
  );

  // ═══════════════════════════════════════════════
  // 2. DEEP HYDRATION — Wellness / Water
  // ═══════════════════════════════════════════════
  static const deepHydration = ShapeGradientSet(
    start: Color(0xFF00D2FF),
    end: Color(0xFF3A7BD5),
    beginAlign: Alignment.topCenter,
    endAlign: Alignment.bottomCenter,
    glowColor: Color(0x1A00D2FF),
    fillOpacity: 0.85,
  );

  // ═══════════════════════════════════════════════
  // 3. FOCUS NEON — Productivity / Code
  // ═══════════════════════════════════════════════
  static const focusNeon = ShapeGradientSet(
    start: Color(0xFF8E2DE2),
    end: Color(0xFF4A00E0),
    beginAlign: Alignment.centerLeft,
    endAlign: Alignment.centerRight,
    glowColor: Color(0x1A8E2DE2),
    fillOpacity: 0.70,
  );

  // ═══════════════════════════════════════════════
  // 4. LIFE GREEN — Health / Nature (bonus)
  // ═══════════════════════════════════════════════
  static const lifeGreen = ShapeGradientSet(
    start: Color(0xFF56AB2F),
    end: Color(0xFF1D976C),
    beginAlign: Alignment.topLeft,
    endAlign: Alignment.bottomRight,
    glowColor: Color(0x1A56AB2F),
    fillOpacity: 0.85,
  );

  // ═══════════════════════════════════════════════
  // 5. EMBER ROSE — Passion / Social (bonus)
  // ═══════════════════════════════════════════════
  static const emberRose = ShapeGradientSet(
    start: Color(0xFFFF6B6B),
    end: Color(0xFFEE5A24),
    beginAlign: Alignment.topCenter,
    endAlign: Alignment.bottomRight,
    glowColor: Color(0x1AFF6B6B),
    fillOpacity: 0.85,
  );

  /// Default fallback gradient — subtle silver for unknown shapes
  static const defaultGradient = ShapeGradientSet(
    start: Color(0xFF667EEA),
    end: Color(0xFF764BA2),
    beginAlign: Alignment.topLeft,
    endAlign: Alignment.bottomRight,
    glowColor: Color(0x1A667EEA),
    fillOpacity: 0.80,
  );

  // ═══════════════════════════════════════════════
  // SHAPE KEY → GRADIENT MAPPING
  // ═══════════════════════════════════════════════

  /// Maps a shape_key (e.g. 'gym.svg') to its gradient set.
  /// Uses keyword matching on the filename to auto-detect category.
  static ShapeGradientSet forShapeKey(String shapeKey) {
    final key = shapeKey.toLowerCase();

    // ── Fitness / Energy → Cyber-Solar ──
    if (_matchesAny(key, [
      'gym',
      'workout',
      'exercise',
      'run',
      'fitness',
      'sport',
      'muscle',
      'weight',
      'dumbbell',
      'barbell',
      'cardio',
      'walk',
      'jog',
      'bike',
      'cycle',
      'swim',
      'stretch',
      'yoga',
      'push',
      'squat',
      'plank',
      'hiit',
      'train',
    ])) {
      return cyberSolar;
    }

    // ── Wellness / Water → Deep Hydration ──
    if (_matchesAny(key, [
      'water',
      'drink',
      'hydra',
      'sleep',
      'rest',
      'meditat',
      'breath',
      'calm',
      'relax',
      'mindful',
      'journal',
      'gratitude',
      'morning',
      'night',
      'routine',
      'self',
      'skin',
      'health',
      'vitamin',
      'supplement',
      'pill',
    ])) {
      return deepHydration;
    }

    // ── Productivity / Code → Focus Neon ──
    if (_matchesAny(key, [
      'code',
      'dsa',
      'study',
      'read',
      'book',
      'learn',
      'focus',
      'work',
      'task',
      'project',
      'write',
      'blog',
      'dev',
      'program',
      'algo',
      'math',
      'science',
      'exam',
      'practice',
      'review',
      'note',
      'research',
      'brain',
    ])) {
      return focusNeon;
    }

    // ── Health / Nature → Life Green ──
    if (_matchesAny(key, [
      'eat',
      'food',
      'diet',
      'vegetable',
      'fruit',
      'cook',
      'meal',
      'nutrition',
      'green',
      'plant',
      'garden',
      'outdoor',
      'nature',
      'hike',
      'walk',
      'step',
      'clean',
      'organize',
      'tidy',
    ])) {
      return lifeGreen;
    }

    // ── Social / Passion → Ember Rose ──
    if (_matchesAny(key, [
      'call',
      'friend',
      'social',
      'talk',
      'chat',
      'family',
      'love',
      'heart',
      'art',
      'music',
      'sing',
      'dance',
      'paint',
      'draw',
      'create',
      'hobby',
      'game',
      'play',
      'pet',
      'dog',
      'cat',
      'guitar',
      'piano',
    ])) {
      return emberRose;
    }

    return defaultGradient;
  }

  static bool _matchesAny(String key, List<String> keywords) {
    return keywords.any((kw) => key.contains(kw));
  }

  /// Returns all available gradients for a picker/preview
  static List<ShapeGradientSet> get all => [
    cyberSolar,
    deepHydration,
    focusNeon,
    lifeGreen,
    emberRose,
    defaultGradient,
  ];
}
