enum HabitVisibility {
  private,
  public,
  nearby;

  String get value => name; // 'private' | 'public' | 'nearby'

  static HabitVisibility fromString(String s) {
    return HabitVisibility.values.firstWhere(
      (e) => e.name == s,
      orElse: () => HabitVisibility.private,
    );
  }

  String get label => switch (this) {
        HabitVisibility.private => 'Private',
        HabitVisibility.public => 'Public',
        HabitVisibility.nearby => 'Nearby',
      };

  String get description => switch (this) {
        HabitVisibility.private => 'Only your space members can see this',
        HabitVisibility.public => 'Anyone on SPACE can discover and join',
        HabitVisibility.nearby => 'Only people near you can discover this',
      };

  String get icon => switch (this) {
        HabitVisibility.private => '🔒',
        HabitVisibility.public => '🌍',
        HabitVisibility.nearby => '📍',
      };
}

