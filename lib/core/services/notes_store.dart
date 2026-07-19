import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_note.dart';
import '../theme/highlight_colors.dart';
import '../utils/stable_hash.dart';

/// Persists the reading notes/highlights list (TZ 8.4) across restarts.
class NotesStore extends ChangeNotifier {
  NotesStore._();
  static final instance = NotesStore._();

  static const _kKey = 'reading_notes_v1';

  List<ReadingNote> _notes = [];
  bool _loaded = false;

  List<ReadingNote> get notes => List.unmodifiable(_notes);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      _notes = decoded.map((e) => ReadingNote.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _notes = _seedNotes();
      await _persist();
    }
    _loaded = true;
    notifyListeners();
  }

  /// Captures a new highlight/note from the reader (TZ 12.7). The note is
  /// keyed to its book by [bookId] (the reader's own stable key) so it restores
  /// for any book. [bookSeed]/[bookIndex] are passed only for catalogue books,
  /// letting [ReadingNote.book] regenerate the source Book for the cover and
  /// "go to book"; leave them null for imported files. [colorValue] is the
  /// ARGB colour the highlight is painted with. Newest notes sort to the top.
  Future<void> add({
    required String text,
    required int bookId,
    required String bookTitle,
    int? bookSeed,
    int? bookIndex,
    int colorValue = 0xFFFFD54F,
    String? cfi,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // The reader can capture a note before the profile ever opened the list,
    // so make sure the persisted notes are in memory first — otherwise this
    // would save on top of an empty list and wipe the seeds/earlier notes.
    await load();
    final note = ReadingNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      bookId: bookId,
      bookSeed: bookSeed,
      bookIndex: bookIndex,
      bookTitle: bookTitle,
      createdAt: DateTime.now(),
      colorValue: colorValue,
      cfi: cfi,
    );
    _notes = [note, ..._notes];
    await _persist();
    notifyListeners();
  }

  /// Highlights (notes with a [ReadingNote.cfi]) captured for one book,
  /// identified by the reader's stable [bookId]. Used by ReaderProvider to
  /// redraw them once a book's rendition is set up.
  List<ReadingNote> highlightsForBook({required int bookId}) {
    return _notes.where((n) => n.bookId == bookId && (n.cfi?.isNotEmpty ?? false)).toList();
  }

  /// Updates a note's text and/or highlight colour in place.
  Future<void> updateNote(String id, {String? text, int? colorValue}) async {
    final trimmed = text?.trim();
    if (trimmed != null && trimmed.isEmpty) return;
    _notes = _notes.map((n) => n.id == id ? n.copyWith(text: trimmed, colorValue: colorValue) : n).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _notes = _notes.where((n) => n.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  // The screen's original hardcoded notes, ported over as the first-run
  // seed so existing users don't see an empty list.
  static List<ReadingNote> _seedNotes() {
    final now = DateTime.now();
    ReadingNote seed(String id, String text, int index, String title, int color) => ReadingNote(
          id: id,
          text: text,
          bookId: stableBookKey('book_0_$index'),
          bookSeed: 0,
          bookIndex: index,
          bookTitle: title,
          createdAt: now,
          colorValue: color,
        );
    return [
      seed('seed_1', '"Wagt hiç kimi garaşmaýar, ýöne hakyky söýgi hemişe garaşýar."', 0, 'Ýitgi we tapyş', HighlightColors.yellow.toARGB32()),
      seed('seed_2', '"Iň garaňky gijeden soň, iň ýagty daň gelýär."', 4, 'Asman ýyldyzlary', HighlightColors.blue.toARGB32()),
      seed('seed_3', '"Umyt — ýüreginde ýanýan ody hiç haçan öçürmeýän ýeke-täk zat."', 8, 'Umyt guşy', HighlightColors.green.toARGB32()),
    ];
  }
}
