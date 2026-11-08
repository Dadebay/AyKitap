import 'package:flutter/material.dart';

/// The colour palette a reader can paint a highlight/note with (TZ §12.7).
///
/// One shared list so the reader's selection toolbar, the add-note sheet and
/// the profile's note card all offer — and render — the exact same swatches.
/// Tones are soft/pastel on purpose: a highlight is drawn *over* the page text
/// at 40% opacity, so a saturated colour would swallow the words on both light
/// (sepia/white) and dark reader themes. The stored value is the swatch's own
/// solid colour; the reader applies the opacity when painting.
class HighlightColors {
  HighlightColors._();

  static const Color yellow = Color(0xFFFFD54F);
  static const Color green = Color(0xFF81C784);
  static const Color blue = Color(0xFF64B5F6);
  static const Color red = Color(0xFFE57373);
  static const Color purple = Color(0xFFBA68C8);
  static const Color orange = Color(0xFFFFB74D);

  /// Order shown in every swatch row.
  static const List<Color> palette = [yellow, green, blue, red, purple, orange];

  /// Fallback for notes saved before colours existed, and the pre-selected
  /// swatch when a fresh highlight/note is started.
  static const Color defaultColor = yellow;

  /// Opacity the highlight is painted at over the page text. Kept here so the
  /// reader and any future preview use one value.
  static const double highlightOpacity = 0.40;
}
