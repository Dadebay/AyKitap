import 'package:json_annotation/json_annotation.dart';

part 'epub_location.g.dart';

@JsonSerializable(explicitToJson: true)
class EpubLocation {
  /// Start cfi string of the page
  String startCfi;

  /// End cfi string of the page
  String endCfi;

  /// Start xpath/XPointer string of the page
  String? startXpath;

  /// End xpath/XPointer string of the page
  String? endXpath;

  /// Spine href of the page currently on screen, e.g. `index_split_003.xhtml`.
  /// This names the *file*, which is not the same thing as the chapter: tools
  /// like Calibre routinely put many chapters in one file and separate them
  /// with anchors. Use [tocHref] to identify the chapter.
  String? href;

  /// Href of the deepest table-of-contents entry at or before this position,
  /// anchor included — e.g. `index_split_003.xhtml#calibre_toc_991`. Matches
  /// [EpubChapter.href] exactly, so it's what identifies the current chapter.
  ///
  /// Falls back to the plain [href] when the file holds no anchored TOC
  /// entries, or when the position sits ahead of the first one.
  String? tocHref;

  /// Progress percentage of location, value between 0.0 and 1.0
  double progress;

  /// 1-based page number of this position, or 0 while the book is still being
  /// counted.
  ///
  /// Reflowable text has no inherent pagination, so a "page" here is one of the
  /// fixed-length text slices epub.js builds in `book.locations` — the same
  /// unit Kindle and Kobo number. It is deliberately independent of the reader's
  /// font size: the number of columns on screen changes with the type size, this
  /// does not.
  ///
  /// Counting the slices is an async pass over the whole book that finishes some
  /// seconds after it opens, so early positions report 0 and are re-sent with a
  /// real number once the pass completes. Treat 0 as "not known yet", never as a
  /// page.
  int page;

  /// Total number of pages in the book, on the same scale as [page]. 0 until
  /// counting finishes — see [page].
  int totalPages;

  EpubLocation({
    required this.startCfi,
    required this.endCfi,
    this.startXpath,
    this.endXpath,
    this.href,
    this.tocHref,
    required this.progress,
    this.page = 0,
    this.totalPages = 0,
  });
  factory EpubLocation.fromJson(Map<String, dynamic> json) =>
      _$EpubLocationFromJson(json);
  Map<String, dynamic> toJson() => _$EpubLocationToJson(this);
}
