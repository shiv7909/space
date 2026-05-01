enum SpaceVisibility {
  private,
  public,
  nearby;

  String get value => name; // 'private' | 'public' | 'nearby'

  static SpaceVisibility fromString(String s) {
    return SpaceVisibility.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SpaceVisibility.private,
    );
  }

  String get label => switch (this) {
        SpaceVisibility.private => 'Private',
        SpaceVisibility.public => 'Public',
        SpaceVisibility.nearby => 'Nearby',
      };

  String get description => switch (this) {
        SpaceVisibility.private => 'Only members you invite can see this space',
        SpaceVisibility.public => 'Anyone on SPACE App can discover and join',
        SpaceVisibility.nearby => 'Only people near you can discover this space',
      };

  String get icon => switch (this) {
        SpaceVisibility.private => '🔒',
        SpaceVisibility.public => '🌍',
        SpaceVisibility.nearby => '📍',
      };
}

