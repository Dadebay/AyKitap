import '../../core/models/author_detail.dart';

/// Appends one `GET /authors/search` page onto what's already on screen,
/// skipping any author that's already there, and reports how many were
/// genuinely new.
///
/// That count — not the page's raw length — is what [SearchScreen] uses to
/// decide whether to keep paging. Length alone can't do the job:
///
/// * The endpoint is free to hand back fewer rows than the `size` asked for.
///   A server-side cap (20 rows against a requested 30, say) would then read
///   as "that was the last page" on the very first request, which is exactly
///   what pinned the Awtor tab to its first screenful.
/// * A backend that ignored `page` would return the same rows forever, and a
///   length-based check would happily append them over and over.
///
/// Counting new ids handles both: paging continues while pages keep
/// contributing authors, and stops the moment one stops contributing.
(List<AuthorSearchResult>, int) mergeAuthorPage(
  List<AuthorSearchResult>? existing,
  List<AuthorSearchResult> incoming,
) {
  final merged = [...?existing];
  final seen = merged.map((a) => a.id).toSet();
  var added = 0;
  for (final author in incoming) {
    if (seen.add(author.id)) {
      merged.add(author);
      added++;
    }
  }
  return (merged, added);
}
