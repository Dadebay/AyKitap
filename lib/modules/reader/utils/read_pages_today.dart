import 'package:shared_preferences/shared_preferences.dart';

/// Which pages of a book have already been counted as read *today*, so going
/// back and re-reading (or reopening the book) never counts a page twice in
/// one day. Stored per book as `yyyymmdd|p1,p2,...`; a new day starts empty,
/// so old days never pile up.
class ReadPagesToday {
  ReadPagesToday._();

  static final Map<int, ({String day, Set<int> pages})> _cache = {};

  static String _today() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// True the first time [page] of [bookId] is seen today (and records it).
  static Future<bool> markIfNew(int bookId, int page) async {
    final day = _today();
    var entry = _cache[bookId];
    SharedPreferences? prefs;
    if (entry == null || entry.day != day) {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(bookId));
      final parts = raw?.split('|');
      if (parts != null && parts.length == 2 && parts[0] == day) {
        entry = (
          day: day,
          pages: parts[1].split(',').map(int.tryParse).whereType<int>().toSet(),
        );
      } else {
        entry = (day: day, pages: <int>{});
      }
      _cache[bookId] = entry;
    }
    if (!entry.pages.add(page)) return false;
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_key(bookId), '$day|${entry.pages.join(',')}');
    return true;
  }

  static String _key(int bookId) => 'read_pages_today_v1_$bookId';
}
