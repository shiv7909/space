import 'package:profanity_filter/profanity_filter.dart';

class ProfanityChecker {
  static final ProfanityFilter _filter = ProfanityFilter();

  /// Checks if the given text contains any profanity.
  /// Returns true if profanity is detected, false otherwise.
  static bool containsProfanity(String text) {
    if (text.isEmpty) return false;
    return _filter.hasProfanity(text);
  }

  /// Censors the given text by replacing profanity with asterisks.
  static String censor(String text) {
    if (text.isEmpty) return text;
    return _filter.censor(text);
  }
}
