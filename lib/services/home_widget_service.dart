import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service that bridges Flutter analytics data to the native home screen widget.
///
/// Currently uses **dummy data** — swap with real backend API calls tomorrow.
/// The widget reads these shared-preference keys from the native side.
class HomeWidgetService {
  // ── Shared-preference keys (must match native Kotlin code) ───────────
  static const _keyStreakCount = 'streak_count';
  static const _keyTodayDone = 'today_done';
  static const _keyTodayTotal = 'today_total';
  static const _keyWeekPercentage = 'week_percentage';
  static const _keyTopHabitName = 'top_habit_name';
  static const _keyTopHabitEmoji = 'top_habit_emoji';
  static const _keyTopHabitStreak = 'top_habit_streak';

  // Android widget provider class name (must match Kotlin class)
  static const _androidWidgetName = 'HabitzWidgetProvider';
  // iOS widget name (for future use)
  static const _iosWidgetName = 'HabitzWidget';

  /// Initialize the widget system.
  /// Call once after app startup (post-auth).
  Future<void> initialize() async {
    try {
      // Set app group for iOS (needed later for WidgetKit)
      await HomeWidget.setAppGroupId('group.com.space.habittrackingapp');

      // Push initial data
      await updateWidgetWithDummyData();

      if (kDebugMode) {
        debugPrint('🏠 HomeWidgetService: initialized with dummy data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🏠 HomeWidgetService: init error — $e');
      }
    }
  }

  /// Push dummy analytics to the native widget.
  /// TODO: Replace with real data from backend API tomorrow.
  Future<void> updateWidgetWithDummyData() async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>(_keyStreakCount, 15),
        HomeWidget.saveWidgetData<int>(_keyTodayDone, 4),
        HomeWidget.saveWidgetData<int>(_keyTodayTotal, 6),
        HomeWidget.saveWidgetData<int>(_keyWeekPercentage, 78),
        HomeWidget.saveWidgetData<String>(_keyTopHabitName, 'Morning Run'),
        HomeWidget.saveWidgetData<String>(_keyTopHabitEmoji, '🏃'),
        HomeWidget.saveWidgetData<int>(_keyTopHabitStreak, 15),
      ]);

      // Tell the OS to refresh the widget
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );

      if (kDebugMode) {
        debugPrint('🏠 HomeWidgetService: widget data pushed ✓');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🏠 HomeWidgetService: update error — $e');
      }
    }
  }

  /// Push real analytics data to the widget.
  /// Call this whenever analytics are refreshed in the app.
  Future<void> updateWidgetWithRealData({
    required int streakCount,
    required int todayDone,
    required int todayTotal,
    required int weekPercentage,
    String? topHabitName,
    String? topHabitEmoji,
    int? topHabitStreak,
  }) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>(_keyStreakCount, streakCount),
        HomeWidget.saveWidgetData<int>(_keyTodayDone, todayDone),
        HomeWidget.saveWidgetData<int>(_keyTodayTotal, todayTotal),
        HomeWidget.saveWidgetData<int>(_keyWeekPercentage, weekPercentage),
        if (topHabitName != null)
          HomeWidget.saveWidgetData<String>(_keyTopHabitName, topHabitName),
        if (topHabitEmoji != null)
          HomeWidget.saveWidgetData<String>(_keyTopHabitEmoji, topHabitEmoji),
        if (topHabitStreak != null)
          HomeWidget.saveWidgetData<int>(_keyTopHabitStreak, topHabitStreak),
      ]);

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🏠 HomeWidgetService: real data update error — $e');
      }
    }
  }
}
