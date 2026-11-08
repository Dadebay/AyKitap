import 'package:flutter/material.dart';

/// Stable Hero tags shared by catalogue surfaces and the reader entrance.
abstract final class AppHeroTags {
  static String catalogBookCover(int bookId) => 'catalog-book-cover-$bookId';

  /// Collection id prevents duplicate Hero tags when the same book appears
  /// in more than one Home collection on the same route.
  static String homeCollectionBookCover(int collectionId, int bookId) =>
      'home-collection-$collectionId-book-cover-$bookId';

  /// Library's five shelves (reading/finished/downloaded/purchased/favorites)
  /// share [LibraryBookCover] and are kept alive as sibling [TabBarView]
  /// pages on one route — the same book can therefore have more than one
  /// [Hero] mounted at once (e.g. a purchased book that's also currently
  /// being read), so the shelf name has to be part of the tag.
  static String libraryShelfBookCover(String shelf, int bookId) =>
      'library-$shelf-book-cover-$bookId';

  /// [NotesScreen] can list more than one note for the same book, so the
  /// book id alone isn't unique within that one route.
  static String noteBookCover(int noteId, int bookId) =>
      'note-$noteId-book-cover-$bookId';

  /// A book detail page carries two related rows (same author, same genre)
  /// and one book can legitimately appear in both — [prefix] is what keeps
  /// their Heroes from colliding on that single route.
  static String relatedBookCover(String prefix, int bookId) =>
      'related-$prefix-book-cover-$bookId';

  /// Flutter's material arc can initially bend a shelf cover away from the
  /// centered destination. A direct rect interpolation keeps the cover's
  /// center on one continuous line and avoids the visible sideways detour.
  static RectTween straightRectTween(Rect? begin, Rect? end) =>
      RectTween(begin: begin, end: end);
}
