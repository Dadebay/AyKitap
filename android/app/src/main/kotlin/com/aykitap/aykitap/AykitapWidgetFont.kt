package com.aykitap.aykitap

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.util.Log
import android.widget.RemoteViews
import kotlin.math.ceil

/**
 * Renders widget labels into small transparent bitmaps with Gilroy.
 *
 * Android 16's RemoteViews protobuf serializer keeps only
 * `TypefaceSpan.family`; the actual Typeface loaded from our font resource is
 * discarded. Since a resource Typeface has no public family name, Samsung's
 * launcher receives a null span and falls back to the system font. Rendering
 * here keeps the font inside our process and sends the launcher only pixels.
 */
internal object AykitapWidgetFont {
  private const val TAG = "AykitapWidgetFont"

  private var regular: Typeface? = null
  private var bold: Typeface? = null
  private var loadAttempted = false

  private fun load(context: Context): Boolean {
    if (loadAttempted) return regular != null
    loadAttempted = true
    regular = runCatching { context.resources.getFont(R.font.gilroy_regular) }
      .onFailure { error -> Log.e(TAG, "Gilroy resource load failed", error) }
      .getOrNull()
    bold = regular?.let { Typeface.create(it, Typeface.BOLD) }
    Log.i(
      TAG,
      "Gilroy load success=${regular != null}, sdk=${android.os.Build.VERSION.SDK_INT}, " +
        "density=${context.resources.displayMetrics.densityDpi}",
    )
    return regular != null
  }

  fun render(
    context: Context,
    value: CharSequence,
    textSizeSp: Float,
    color: Int,
    bold: Boolean = false,
    maxWidthDp: Float? = null,
    letterSpacingEm: Float = 0f,
  ): Bitmap {
    val metrics = context.resources.displayMetrics
    val scaledDensity = metrics.scaledDensity
    val density = metrics.density
    val loaded = load(context)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
      this.color = color
      textSize = textSizeSp * scaledDensity
      typeface = when {
        bold && loaded -> this@AykitapWidgetFont.bold
        loaded -> regular
        bold -> Typeface.DEFAULT_BOLD
        else -> Typeface.DEFAULT
      }
    }
    val trackingPx = letterSpacingEm * paint.textSize
    val maxWidthPx = maxWidthDp?.let { it * density }
    val lines = value.toString().split('\n').map { line ->
      fitLine(line, paint, trackingPx, maxWidthPx)
    }
    val fontMetrics = paint.fontMetrics
    val lineHeight = ceil(fontMetrics.descent - fontMetrics.ascent).toInt().coerceAtLeast(1)
    val lineGap = if (lines.size > 1) ceil(2f * density).toInt() else 0
    val edge = ceil(1f * density).toInt()
    val contentWidth = lines.maxOfOrNull { measuredWidth(it, paint, trackingPx) } ?: 0f
    val bitmap = Bitmap.createBitmap(
      (ceil(contentWidth).toInt() + edge * 2).coerceAtLeast(1),
      (lineHeight * lines.size + lineGap * (lines.size - 1) + edge * 2).coerceAtLeast(1),
      Bitmap.Config.ARGB_8888,
    ).apply { this.density = metrics.densityDpi }
    val canvas = Canvas(bitmap)
    var baseline = edge - fontMetrics.ascent
    lines.forEach { line ->
      drawTrackedText(canvas, line, edge.toFloat(), baseline, paint, trackingPx)
      baseline += lineHeight + lineGap
    }
    return bitmap
  }

  private fun fitLine(
    value: String,
    paint: Paint,
    trackingPx: Float,
    maxWidthPx: Float?,
  ): String {
    if (maxWidthPx == null || measuredWidth(value, paint, trackingPx) <= maxWidthPx) return value
    val ellipsis = "…"
    val codePoints = value.codePointCount(0, value.length)
    for (count in codePoints downTo 0) {
      val end = value.offsetByCodePoints(0, count)
      val candidate = value.substring(0, end).trimEnd() + ellipsis
      if (measuredWidth(candidate, paint, trackingPx) <= maxWidthPx) return candidate
    }
    return ellipsis
  }

  private fun measuredWidth(value: String, paint: Paint, trackingPx: Float): Float {
    if (value.isEmpty()) return 0f
    var width = 0f
    var offset = 0
    var glyphs = 0
    while (offset < value.length) {
      val codePoint = value.codePointAt(offset)
      val glyph = String(Character.toChars(codePoint))
      width += paint.measureText(glyph)
      offset += Character.charCount(codePoint)
      glyphs++
    }
    return width + trackingPx * (glyphs - 1).coerceAtLeast(0)
  }

  private fun drawTrackedText(
    canvas: Canvas,
    value: String,
    startX: Float,
    baseline: Float,
    paint: Paint,
    trackingPx: Float,
  ) {
    var x = startX
    var offset = 0
    while (offset < value.length) {
      val codePoint = value.codePointAt(offset)
      val glyph = String(Character.toChars(codePoint))
      canvas.drawText(glyph, x, baseline, paint)
      x += paint.measureText(glyph) + trackingPx
      offset += Character.charCount(codePoint)
    }
  }
}

/** Places a launcher-independent Gilroy text bitmap into an ImageView. */
internal fun RemoteViews.setGilroyText(
  context: Context,
  viewId: Int,
  value: CharSequence,
  textSizeSp: Float,
  color: Int,
  bold: Boolean = false,
  maxWidthDp: Float? = null,
  letterSpacingEm: Float = 0f,
) {
  setImageViewBitmap(
    viewId,
    AykitapWidgetFont.render(
      context = context,
      value = value,
      textSizeSp = textSizeSp,
      color = color,
      bold = bold,
      maxWidthDp = maxWidthDp,
      letterSpacingEm = letterSpacingEm,
    ),
  )
  setContentDescription(viewId, value)
}
