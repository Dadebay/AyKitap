import 'package:flutter/material.dart';

import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/services/book_list_api_service.dart';
import 'detail_related_books.dart';

/// The two "keep reading" rows at the bottom of a book's detail sheet.
///
/// `GET /books/:id` carries no collection field, so "books from the same
/// collection" isn't answerable from a detail response — the closest thing
/// the catalogue actually models is the book's genre, which is what the
/// second row queries.
///
/// Each guard matters: a book with no author (or no genre) simply drops
/// that row rather than firing a query with a missing id, which the backend
/// would answer with the whole catalogue.
List<Widget> buildDetailRelatedSections(BookDetail book) {
  return [
    if (book.authors.isNotEmpty)
      DetailRelatedBooks(
        // Keyed by author so switching between two books by different
        // authors rebuilds the row instead of showing the previous one's
        // results until the new fetch lands.
        key: ValueKey('related-author-${book.authors.first.id}'),
        title: BookDetailStrings.moreByAuthor,
        heroPrefix: 'author',
        excludeBookId: book.id,
        fetch: () =>
            BookListApiService.listBooks(authorId: book.authors.first.id),
      ),
    if (book.genres.isNotEmpty)
      DetailRelatedBooks(
        key: ValueKey('related-genre-${book.genres.first.id}'),
        title: BookDetailStrings.similarBooks,
        heroPrefix: 'genre',
        excludeBookId: book.id,
        fetch: () =>
            BookListApiService.listBooks(genreIds: [book.genres.first.id]),
      ),
  ];
}
