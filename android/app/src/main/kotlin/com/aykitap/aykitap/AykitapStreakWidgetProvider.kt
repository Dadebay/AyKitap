package com.aykitap.aykitap

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Profile-style weekly streak widget. Widget launchers do not run continuous
 * animations, so the flame uses a glow treatment and refreshes with real data. */
class AykitapStreakWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val streak = widgetData.getInt("streak", 0)
    val bestStreak = widgetData.getInt("best_streak", 0)
    val todayPages = widgetData.getInt("today_pages", 0)
    val todayWeekday = widgetData.getInt("today_weekday", 1).coerceIn(1, 7)
    val weekRead = widgetData.getString("week_read", "0000000") ?: "0000000"

    appWidgetIds.forEach { id ->
      val views = RemoteViews(context.packageName, R.layout.aykitap_streak_widget).apply {
        setTextViewText(R.id.streak_title, if (streak == 1) "1 day streak" else "$streak day streak")
        setTextViewText(R.id.streak_best, "Best: $bestStreak days")
        setTextViewText(R.id.streak_today_pages_count, "$todayPages")
        bindWeek(weekRead, todayWeekday)

        val intent = Intent(
          Intent.ACTION_VIEW,
          Uri.parse("aykitap://streak"),
          context,
          MainActivity::class.java,
        )
        val pending = PendingIntent.getActivity(
          context,
          id + 10000,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        setOnClickPendingIntent(R.id.streak_widget_container, pending)
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun RemoteViews.bindWeek(weekRead: String, todayWeekday: Int) {
    val circles = intArrayOf(
      R.id.streak_day_1_circle, R.id.streak_day_2_circle, R.id.streak_day_3_circle,
      R.id.streak_day_4_circle, R.id.streak_day_5_circle, R.id.streak_day_6_circle,
      R.id.streak_day_7_circle,
    )
    val labels = intArrayOf(
      R.id.streak_day_1_label, R.id.streak_day_2_label, R.id.streak_day_3_label,
      R.id.streak_day_4_label, R.id.streak_day_5_label, R.id.streak_day_6_label,
      R.id.streak_day_7_label,
    )
    circles.forEachIndexed { index, circleId ->
      val met = weekRead.getOrNull(index) == '1'
      val today = index + 1 == todayWeekday
      setTextViewText(circleId, if (met) "🔥" else if (today) "•" else "")
      setInt(
        circleId,
        "setBackgroundResource",
        when {
          met -> R.drawable.aykitap_widget_day_read
          today -> R.drawable.aykitap_widget_day_today
          else -> R.drawable.aykitap_widget_day_empty
        },
      )
      setTextColor(circleId, if (today) Color.parseColor("#8D4DFF") else Color.WHITE)
      setTextColor(
        labels[index],
        Color.parseColor(if (today) "#8D4DFF" else "#8B8491"),
      )
    }
  }
}
