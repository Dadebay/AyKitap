import '../../core/models/book.dart';

/// Returned to the SearchScreen when "Netijeleri görkez" is pressed —
/// whether any filter is set (drives the red badge) and the books to show.
class FilterResult {
  final bool active;
  final List<Book> books;
  const FilterResult({required this.active, required this.books});
}
