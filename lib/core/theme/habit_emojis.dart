/// 🎨 CURATED EMOJI CATALOG FOR HABITS
///
/// Organized by category so users can quickly find the right emoji
/// for their habit. Each category maps to a gradient set in ShapeGradients.

class HabitEmojiCategory {
  final String name;
  final String icon;
  final List<String> emojis;

  const HabitEmojiCategory({
    required this.name,
    required this.icon,
    required this.emojis,
  });
}

class HabitEmojis {
  HabitEmojis._();

  // ═══════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════

  static const fitness = HabitEmojiCategory(
    name: 'Fitness',
    icon: '💪',
    emojis: [
      '💪',
      '🏋️',
      '🏃',
      '🚴',
      '🏊',
      '🧘',
      '⚡',
      '🔥',
      '🥊',
      '⚽',
      '🏀',
      '🎾',
      '🏈',
      '🤸',
      '🚶',
      '🏆',
    ],
  );

  static const wellness = HabitEmojiCategory(
    name: 'Wellness',
    icon: '💧',
    emojis: [
      '💧',
      '😴',
      '🧘',
      '🧠',
      '💆',
      '🌙',
      '☀️',
      '🫁',
      '💊',
      '🩺',
      '🌿',
      '🍵',
      '♨️',
      '🧴',
      '🪥',
      '🛁',
    ],
  );

  static const productivity = HabitEmojiCategory(
    name: 'Focus',
    icon: '💻',
    emojis: [
      '💻',
      '📚',
      '✍️',
      '🎯',
      '📝',
      '🧩',
      '📖',
      '🔬',
      '📐',
      '🖊️',
      '💡',
      '⏰',
      '📊',
      '🗂️',
      '✅',
      '🚀',
    ],
  );

  static const nutrition = HabitEmojiCategory(
    name: 'Nutrition',
    icon: '🥗',
    emojis: [
      '🥗',
      '🍎',
      '🥑',
      '🍳',
      '🥤',
      '🧃',
      '🍌',
      '🥦',
      '🫐',
      '🥕',
      '🍇',
      '🥜',
      '🍯',
      '🫒',
      '🥚',
      '🍽️',
    ],
  );

  static const social = HabitEmojiCategory(
    name: 'Social',
    icon: '❤️',
    emojis: [
      '❤️',
      '📞',
      '👥',
      '🤝',
      '💬',
      '👨‍👩‍👧',
      '🐶',
      '🐱',
      '🎵',
      '🎨',
      '🎸',
      '🎮',
      '🎬',
      '📸',
      '💃',
      '🎤',
    ],
  );

  static const lifestyle = HabitEmojiCategory(
    name: 'Lifestyle',
    icon: '🌱',
    emojis: [
      '🌱',
      '🏡',
      '🧹',
      '💰',
      '📦',
      '🌍',
      '✈️',
      '🚗',
      '👔',
      '📰',
      '🧺',
      '🪴',
      '🛒',
      '📬',
      '🔑',
      '⭐',
    ],
  );

  /// All categories in display order
  static const List<HabitEmojiCategory> categories = [
    fitness,
    wellness,
    productivity,
    nutrition,
    social,
    lifestyle,
  ];

  /// Flat list of all emojis (for validation / search)
  static List<String> get allEmojis =>
      categories.expand((c) => c.emojis).toSet().toList();

  /// Default emoji
  static const String defaultEmoji = '🔥';
}
