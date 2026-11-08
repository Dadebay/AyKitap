// Diagnostics for a reported "the search results keep showing the same book".
// A scan of the whole live catalogue turned up no repeated ids, so this logs
// nothing on a clean page — these tests are what say it would speak up when
// there is something to report.
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/modules/search/search_result_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryBook _book(int id, String name) => LibraryBook(id: id, name: name);

void main() {
  group('normalizedBookTitle', () {
    test('ignores the stray spacing the live catalogue actually carries', () {
      // Real titles from `GET /books/all`.
      expect(
          normalizedBookTitle('Alchemist '), normalizedBookTitle('Alchemist'));
      expect(
        normalizedBookTitle('%100  Düşünce gücü'),
        normalizedBookTitle('%100 Düşünce gücü'),
      );
    });

    test('ignores case and punctuation', () {
      expect(
        normalizedBookTitle('"Ferrarisini" satan keşiş'),
        normalizedBookTitle('Ferrarisini satan Keşiş'),
      );
    });

    test('keeps genuinely different titles apart', () {
      expect(
        normalizedBookTitle('Atomic habits'),
        isNot(normalizedBookTitle('Atomik Alışkanlıklar')),
      );
      expect(
        normalizedBookTitle('#ЛюбовьНенависть'),
        isNot(normalizedBookTitle('#НенавистьЛюбовь')),
      );
    });

    test('keeps non-Latin titles intact', () {
      expect(normalizedBookTitle('Гордые души'), 'гордые души');
    });

    test('a title of nothing but punctuation normalises to empty', () {
      expect(normalizedBookTitle('— «...» —'), isEmpty);
    });
  });

  group('findLookalikeResults', () {
    test('an ordinary page reports nothing', () {
      final clean = [
        _book(1, 'Alchemist'),
        _book(2, 'Atomic habits'),
        _book(3, 'Гордые души'),
      ];

      expect(findLookalikeResults(clean), isEmpty);
    });

    test('the same id twice is reported — that is never right', () {
      final groups = findLookalikeResults([
        _book(7, 'Alchemist'),
        _book(7, 'Alchemist'),
        _book(8, 'Veyl'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.reason, LookalikeReason.sameId);
      expect(groups.single.books, hasLength(2));
    });

    test('two ids sharing a title are reported separately', () {
      // The live catalogue's one real case: 'Insancıklar' twice, two ids.
      final groups = findLookalikeResults([
        _book(11, 'Insancıklar'),
        _book(12, 'Insancıklar '),
      ]);

      expect(groups.single.reason, LookalikeReason.sameTitle);
      expect(groups.single.books.map((b) => b.id), [11, 12]);
    });

    test('a repeated id is not also reported as a repeated title', () {
      final groups = findLookalikeResults([
        _book(7, 'Alchemist'),
        _book(7, 'Alchemist'),
      ]);

      expect(groups.map((g) => g.reason), [LookalikeReason.sameId]);
    });

    test('repeated ids come before merely repeated titles', () {
      final groups = findLookalikeResults([
        _book(11, 'Insancıklar'),
        _book(12, 'Insancıklar'),
        _book(7, 'Alchemist'),
        _book(7, 'Alchemist'),
      ]);

      expect(groups.first.reason, LookalikeReason.sameId);
      expect(groups.last.reason, LookalikeReason.sameTitle);
    });

    test('two punctuation-only titles are not called the same book', () {
      final groups = findLookalikeResults([
        _book(1, '...'),
        _book(2, '???'),
      ]);

      expect(groups, isEmpty);
    });
  });

  group('matchesWatchedTitle', () {
    // The five titles a reader named on 14.09.2026, plus the manga series
    // they said was the expected kind of repetition.
    test('matches the reported titles however they are spelled on screen', () {
      expect(
          matchesWatchedTitle('İçimizdeki çocuk', 'İçimizdeki çocuk'), isTrue);
      expect(matchesWatchedTitle('Beyaz Leke ', 'Beyaz leke'), isTrue);
      expect(matchesWatchedTitle('«Гордые души»', 'Гордые души'), isTrue);
      expect(
          matchesWatchedTitle(
              'Сила уверенности в себе', 'Сила уверенности в себе'),
          isTrue);
    });

    test('word order and extra words do not hide a series volume', () {
      // Why the match is a word-subset rather than an equality: a series has
      // many volumes, and no two of their titles are the same string.
      expect(matchesWatchedTitle('Spy x Family, Vol. 3', 'spy family'), isTrue);
      expect(matchesWatchedTitle('SPY×FAMILY 1', 'spy family'), isTrue);
    });

    test('does not match a book that merely shares a word', () {
      expect(matchesWatchedTitle('Veyl', 'Veyl'), isTrue);
      expect(matchesWatchedTitle('Beyaz diş', 'Beyaz leke'), isFalse);
      expect(matchesWatchedTitle('Family', 'spy family'), isFalse);
    });

    test('every watched entry is a real one, not an empty string', () {
      // An empty entry would match every book on screen and bury the log.
      for (final watched in watchedBookTitles) {
        expect(matchesWatchedTitle('Something else entirely', watched), isFalse,
            reason: 'watched entry "$watched" matches everything');
      }
    });
  });
}
