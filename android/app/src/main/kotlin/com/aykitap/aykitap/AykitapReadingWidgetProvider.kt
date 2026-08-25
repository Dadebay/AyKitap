package com.aykitap.aykitap

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** The dedicated last-book widget. Tapping anywhere resumes that book. */
class AykitapReadingWidgetProvider : HomeWidgetProvider() {
  private companion object {
    /** Must match the cover box in `aykitap_last_book_widget.xml` (78x117dp) —
     *  the bitmap is cropped to this ratio so its rounded corners survive. */
    const val COVER_ASPECT = 78f / 117f
    /** The 14dp radius the cover box's gradient background already uses,
     *  expressed against the box's 78dp width so it scales with the bitmap. */
    const val COVER_RADIUS_RATIO = 14f / 78f
  }

  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val title = widgetData.getString("book_title", null) ?: "Start your reading journey"
    val author = widgetData.getString("book_author", null)?.takeIf { it.isNotBlank() }
    val page = widgetData.getInt("book_page", 0) + 1
    val total = widgetData.getInt("book_page_count", 0)
    val bookId = widgetData.getInt("book_id", -1)
    val hasBook = bookId >= 0
    val hasPages = hasBook && total > 0
    // "158 left" is the part that actually answers "how much is still ahead of
    // me" — the page counter alone leaves that as mental arithmetic, and the
    // column has the room for it now.
    val remaining = (total - page).coerceAtLeast(0)
    val subtitle = when {
      hasPages && remaining > 0 -> "Page $page of $total · $remaining left"
      hasPages -> "Page $page of $total · finished"
      else -> "Choose your next book in Aýkitap"
    }
    val progress = if (hasPages) ((page * 100) / total).coerceIn(0, 100) else 0
    val cover = widgetData.getString("book_cover", null)?.let(::decodeWidgetCover)

    appWidgetIds.forEach { id ->
      val views = RemoteViews(context.packageName, R.layout.aykitap_last_book_widget).apply {
        setTextViewText(R.id.widget_eyebrow, if (hasBook) "CONTINUE READING" else "GET STARTED")
        setTextViewText(R.id.widget_title, title)
        setTextViewText(R.id.widget_author, author ?: "")
        setViewVisibility(R.id.widget_author, if (hasBook && author != null) View.VISIBLE else View.GONE)
        setTextViewText(R.id.widget_subtitle, subtitle)
        setTextViewText(
          R.id.widget_cta,
          if (hasBook) "Tap to continue  →" else "Browse the library  →",
        )
        // A 0%-progress bar next to "choose your next book" reads as
        // clutter, not progress — only meaningful once a book is active.
        setViewVisibility(R.id.widget_progress_row, if (hasPages) View.VISIBLE else View.GONE)
        if (hasPages) {
          setProgressBar(R.id.widget_progress, 100, progress, false)
          setTextViewText(R.id.widget_percent, "$progress%")
        }
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
      ?.let(::roundedCover)
  }.getOrNull()

  /** RemoteViews has no way to clip an ImageView to its container's rounded
   *  background (`setClipToOutline` isn't a remotable method), which is why
   *  the cover used to render with square corners inside a rounded box. The
   *  radius has to be baked into the bitmap instead — and since the corners
   *  would simply be cropped off again by a mismatched box, the source is
   *  first center-cropped to the layout's exact cover ratio. */
  private fun roundedCover(source: Bitmap): Bitmap {
    val sourceAspect = source.width.toFloat() / source.height
    val cropWidth: Int
    val cropHeight: Int
    if (sourceAspect > COVER_ASPECT) {
      cropHeight = source.height
      cropWidth = (cropHeight * COVER_ASPECT).toInt().coerceIn(1, source.width)
    } else {
      cropWidth = source.width
      cropHeight = (cropWidth / COVER_ASPECT).toInt().coerceIn(1, source.height)
    }
    val cropped = Bitmap.createBitmap(
      source,
      (source.width - cropWidth) / 2,
      (source.height - cropHeight) / 2,
      cropWidth,
      cropHeight,
    )

    val rounded = Bitmap.createBitmap(cropped.width, cropped.height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(rounded)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    val bounds = RectF(0f, 0f, cropped.width.toFloat(), cropped.height.toFloat())
    val radius = cropped.width * COVER_RADIUS_RATIO
    canvas.drawRoundRect(bounds, radius, radius, paint)
    paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
    canvas.drawBitmap(cropped, 0f, 0f, paint)
    return rounded
  }
}
