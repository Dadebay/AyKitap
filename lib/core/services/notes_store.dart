import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_note.dart';

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

  /// Captures a new highlight/note from the reader (TZ 12.7). The book is
  /// referenced by [bookSeed]/[bookIndex] so [ReadingNote.book] can regenerate
  /// it — the caller resolves those from the mock book's `book_{seed}_{index}`
  /// id. Newest notes sort to the top.
  Future<void> add({
    required String text,
    required int bookSeed,
    required int bookIndex,
    required String bookTitle,
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
      bookSeed: bookSeed,
      bookIndex: bookIndex,
      bookTitle: bookTitle,
      createdAt: DateTime.now(),
    );
    _notes = [note, ..._notes];
    await _persist();
    notifyListeners();
  }

  Future<void> updateText(String id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _notes = _notes.map((n) => n.id == id ? n.copyWith(text: trimmed) : n).toList();
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
    return [
      ReadingNote(
        id: 'seed_1',
        text: '"Wagt hiç kimi garaşmaýar, ýöne hakyky söýgi hemişe garaşýar."',
        bookSeed: 0,
        bookIndex: 0,
        bookTitle: 'Ýitgi we tapyş',
        createdAt: now,
      ),
      ReadingNote(
        id: 'seed_2',
        text: '"Iň garaňky gijeden soň, iň ýagty daň gelýär."',
        bookSeed: 0,
        bookIndex: 4,
        bookTitle: 'Asman ýyldyzlary',
        createdAt: now,
      ),
      ReadingNote(
        id: 'seed_3',
        text: '"Umyt — ýüreginde ýanýan ody hiç haçan öçürmeýän ýeke-täk zat."',
        bookSeed: 0,
        bookIndex: 8,
        bookTitle: 'Umyt guşy',
        createdAt: now,
      ),
    ];
  }
}
