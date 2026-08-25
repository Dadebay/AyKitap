package com.aykitap.aykitap

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** The dedicated last-book widget. Tapping anywhere resumes that book. */
class AykitapReadingWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val title = widgetData.getString("book_title", null) ?: "Start your reading journey"
    val page = widgetData.getInt("book_page", 0) + 1
    val total = widgetData.getInt("book_page_count", 0)
    val bookId = widgetData.getInt("book_id", -1)
    val hasBook = bookId >= 0
    val subtitle = if (hasBook && total > 0) "Page $page of $total" else "Choose your next book in Aýkitap"
    val progress = if (hasBook && total > 0) ((page * 100) / total).coerceIn(0, 100) else 0
    val cover = widgetData.getString("book_cover", null)?.let(::decodeWidgetCover)

    appWidgetIds.forEach { id ->
      val views = RemoteViews(context.packageName, R.layout.aykitap_last_book_widget).apply {
        setTextViewText(R.id.widget_eyebrow, if (hasBook) "CONTINUE READING" else "GET STARTED")
        setTextViewText(R.id.widget_title, title)
        setTextViewText(R.id.widget_subtitle, subtitle)
        setTextViewText(
          R.id.widget_cta,
          if (hasBook) "Tap to continue  →" else "Browse the library  →",
        )
        // A 0%-progress bar next to "choose your next book" reads as
        // clutter, not progress — only meaningful once a book is active.
        setViewVisibility(R.id.widget_progress, if (hasBook) View.VISIBLE else View.GONE)
        if (hasBook) setProgressBar(R.id.widget_progress, 100, progress, false)
        if (cover != null) {
          setImageViewBitmap(R.id.widget_cover, cover)
          setViewVisibility(R.id.widget_cover, View.VISIBLE)
          setViewVisibility(R.id.widget_cover_placeholder, View.GONE)
        } else {
          setViewVisibility(R.id.widget_cover, View.GONE)
          setViewVisibility(R.id.widget_cover_placeholder, View.VISIBLE)
        }
        val uri = if (hasBook) Uri.parse("aykitap://reader/$bookId") else Uri.parse("aykitap://")
        setOnClickPendingIntent(R.id.widget_container, pendingIntent(context, id, uri))
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun pendingIntent(context: Context, id: Int, uri: Uri): PendingIntent {
    val intent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java)
    return PendingIntent.getActivity(
      context,
      id,
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun decodeWidgetCover(path: String) = runCatching {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    var sampleSize = 1
    while (bounds.outWidth / sampleSize > 360 || bounds.outHeight / sampleSize > 540) {
      sampleSize *= 2
    }
    BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sampleSize })
  }.getOrNull()
}
