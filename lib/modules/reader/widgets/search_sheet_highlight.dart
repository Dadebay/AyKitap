part of 'search_sheet.dart';

/// [icon] is a `HugeIcons.*` constant — hugeicons models its glyphs as a JSON
/// structure rather than an [IconData]. Used for every empty/loading/no-
/// results state in [SearchSheet]'s results list.
Widget _hint(List<List<dynamic>> icon, String text) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.grey3, size: 34),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

/// epub.js builds excerpts by concatenating raw text nodes, so they arrive
/// with the source file's newlines and indentation in them.
String _clean(String excerpt) => excerpt.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Splits [text] around every case-insensitive occurrence of [query] so the
/// match can be picked out from the surrounding sentence. Matching on the
/// original string via RegExp (rather than indexing into a lowercased copy)
/// keeps the offsets valid for characters whose lowercase form is a
/// different length, such as Turkish İ.
List<TextSpan> _highlight(String text, String query) {
  final base = TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.45);
  if (query.isEmpty) return [TextSpan(text: text, style: base)];

  final hit = TextStyle(
    color: AppColors.primary,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w700,
  );

  final spans = <TextSpan>[];
  var cursor = 0;
  for (final m
      in RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
    }
    spans.add(TextSpan(text: text.substring(m.start, m.end), style: hit));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  return spans;
}
