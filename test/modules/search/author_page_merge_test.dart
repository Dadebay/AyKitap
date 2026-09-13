// The paging rule behind the Awtor tab's infinite scroll. The tab used to
// stop at whatever its first request returned; these pin down the two backend
// behaviours that make a naive "did this page fill up?" check get that wrong.
import 'package:aykitap/core/models/author_detail.dart';
import 'package:aykitap/modules/search/author_page_merge.dart';
import 'package:flutter_test/flutter_test.dart';

List<AuthorSearchResult> _page(Iterable<int> ids) =>
    [for (final id in ids) AuthorSearchResult(id: id, name: 'Awtor $id')];

List<int> _ids(List<AuthorSearchResult> authors) =>
    authors.map((a) => a.id).toList();

void main() {
  test('the first page is taken whole', () {
    final (merged, added) = mergeAuthorPage(null, _page([1, 2, 3]));

    expect(_ids(merged), [1, 2, 3]);
    expect(added, 3);
  });

  test('a following page is appended in order', () {
    final (merged, added) = mergeAuthorPage(_page([1, 2, 3]), _page([4, 5]));

    expect(_ids(merged), [1, 2, 3, 4, 5]);
    expect(added, 2);
  });

  test('a short page still counts as progress', () {
    // The reported symptom: the endpoint can cap `size` below what was asked
    // for, so a page that arrives shorter than requested is not the last one.
    // `added > 0` is what keeps the scroll going here; a length-vs-size check
    // would have declared this the end on the very first request.
    final (merged, added) = mergeAuthorPage(_page([1, 2, 3]), _page([4]));

    expect(_ids(merged), [1, 2, 3, 4]);
    expect(added, greaterThan(0));
  });

  test('a backend that ignores `page` stops the scroll instead of looping', () {
    final first = _page([1, 2, 3]);
    final (merged, added) = mergeAuthorPage(first, _page([1, 2, 3]));

    expect(_ids(merged), [1, 2, 3], reason: 'no author is listed twice');
    expect(added, 0, reason: 'nothing new means there is no next page');
  });

  test('a partly overlapping page contributes only its new authors', () {
    final (merged, added) = mergeAuthorPage(_page([1, 2, 3]), _page([3, 4, 5]));

    expect(_ids(merged), [1, 2, 3, 4, 5]);
    expect(added, 2);
  });

  test('an empty page ends the scroll', () {
    final (merged, added) = mergeAuthorPage(_page([1, 2]), _page([]));

    expect(_ids(merged), [1, 2]);
    expect(added, 0);
  });

  test('the existing list is never mutated in place', () {
    final existing = _page([1, 2]);
    mergeAuthorPage(existing, _page([3]));

    expect(_ids(existing), [1, 2]);
  });
}
