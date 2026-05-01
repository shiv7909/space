package com.space.habittrackingapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

/**
 * Native Android AppWidget provider for the Habitz home screen widget.
 *
 * Reads analytics data from SharedPreferences (written by Flutter via home_widget)
 * and populates the RemoteViews layout.
 */
class HabitzWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Handle home_widget refresh broadcasts
        if (intent.action == "es.antonborri.home_widget.action.REFRESH" ||
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, HabitzWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        // SharedPreferences keys — must match Dart HomeWidgetService keys
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val KEY_STREAK = "streak_count"
        private const val KEY_TODAY_DONE = "today_done"
        private const val KEY_TODAY_TOTAL = "today_total"
        private const val KEY_WEEK_PCT = "week_percentage"
        private const val KEY_TOP_HABIT_NAME = "top_habit_name"
        private const val KEY_TOP_HABIT_EMOJI = "top_habit_emoji"
        private const val KEY_TOP_HABIT_STREAK = "top_habit_streak"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Read stored analytics from SharedPreferences
            val prefs: SharedPreferences = context.getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

            val streakCount = prefs.getInt(KEY_STREAK, 0)
            val todayDone = prefs.getInt(KEY_TODAY_DONE, 0)
            val todayTotal = prefs.getInt(KEY_TODAY_TOTAL, 0)
            val weekPercentage = prefs.getInt(KEY_WEEK_PCT, 0)
            val topHabitName = prefs.getString(KEY_TOP_HABIT_NAME, "—") ?: "—"
            val topHabitEmoji = prefs.getString(KEY_TOP_HABIT_EMOJI, "✨") ?: "✨"
            val topHabitStreak = prefs.getInt(KEY_TOP_HABIT_STREAK, 0)

            // Calculate today progress (0-100)
            val todayProgress = if (todayTotal > 0) {
                (todayDone * 100) / todayTotal
            } else {
                0
            }

            // Build RemoteViews
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Streak badge
            views.setTextViewText(R.id.widget_streak_count, "$streakCount")

            // Today progress
            views.setTextViewText(
                R.id.widget_today_label,
                "$todayDone / $todayTotal done"
            )
            views.setProgressBar(R.id.widget_today_progress, 100, todayProgress, false)

            // Stat pills
            views.setTextViewText(R.id.widget_stat_today, "$todayDone/$todayTotal")
            views.setTextViewText(R.id.widget_stat_week, "$weekPercentage%")
            views.setTextViewText(
                R.id.widget_stat_top_habit,
                "$topHabitEmoji $topHabitStreak"
            )
            views.setTextViewText(R.id.widget_stat_top_label, "Top streak")

            // Subtitle with context
            views.setTextViewText(
                R.id.widget_subtitle,
                if (todayDone == todayTotal && todayTotal > 0) {
                    "All done! 🎉"
                } else if (todayTotal > 0) {
                    "${todayTotal - todayDone} habits remaining"
                } else {
                    "Your daily overview"
                }
            )

            // Tap-to-open: launch the main app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            // Push update
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
