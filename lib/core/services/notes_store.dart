import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_note.dart';
import 'auth_session.dart';
import 'user_notes_api_service.dart';
import '../theme/highlight_colors.dart';
import '../utils/stable_hash.dart';

/// Persists the reading notes/highlights list (TZ 8.4) across restarts.
class NotesStore extends ChangeNotifier {
  NotesStore._();
  static final instance = NotesStore._();

  static const _kKey = 'reading_notes_v1';
  static const _kDeletesKey = 'reading_note_deletes_v1';

  List<ReadingNote> _notes = [];
  Future<void>? _loadFuture;
  bool _syncing = false;
  bool _syncAgain = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  List<Map<String, int>> _pendingDeletes = [];

  List<ReadingNote> get notes => List.unmodifiable(_notes);

  Future<void> load() => _loadFuture ??= _read();

  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      _notes = decoded
          .map((e) => ReadingNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _notes = _seedNotes();
      await _persist();
    }
    _pendingDeletes =
        (jsonDecode(prefs.getString(_kDeletesKey) ?? '[]') as List)
            .map((e) => Map<String, int>.from(e as Map))
            .toList();
    notifyListeners();
  }

  /// Captures a new highlight/note from the reader (TZ 12.7). The note is
  /// keyed to its book by [bookId] (the reader's own stable key) so it restores
  /// for any book. [bookSeed]/[bookIndex] are passed only for catalogue books,
  /// letting [ReadingNote.book] regenerate the source Book for the cover and
  /// "go to book"; leave them null for imported files. [colorValue] is the
  /// ARGB colour the highlight is painted with. Newest notes sort to the top.
  Future<ReadingNote?> add({
    required String text,
    required int bookId,
    required String bookTitle,
    int? bookSeed,
    int? bookIndex,
    int colorValue = 0xFFFFD54F,
    String? cfi,
    int? remoteId,
    int? realBookId,
    String? snippet,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
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
      remoteId: remoteId,
      realBookId: realBookId,
      ownerUserId: realBookId == null ? null : await AuthSession.getUserId(),
      snippet: snippet,
    );
    _notes = [note, ..._notes];
    await _persist();
    notifyListeners();
    if (realBookId != null && remoteId == null) unawaited(syncPending());
    return note;
  }

  /// Highlights (notes with a [ReadingNote.cfi]) captured for one book,
  /// identified by the reader's stable [bookId]. Used by ReaderProvider to
  /// redraw them once a book's rendition is set up.
  List<ReadingNote> highlightsForBook({required int bookId}) {
    return _notes
        .where((n) => n.bookId == bookId && (n.cfi?.isNotEmpty ?? false))
        .toList();
  }

  /// Updates a note's text and/or highlight colour in place.
  Future<void> updateNote(String id, {String? text, int? colorValue}) async {
    final trimmed = text?.trim();
    if (trimmed != null && trimmed.isEmpty) return;
    _notes = _notes
        .map((n) => n.id == id
            ? n.copyWith(
                text: trimmed,
                colorValue: colorValue,
                needsUpdate: n.remoteId != null && n.realBookId != null)
            : n)
        .toList();
    await _persist();
    notifyListeners();
    unawaited(syncPending());
  }

  Future<void> remove(String id) async {
    await load();
    final note = _notes.where((n) => n.id == id).firstOrNull;
    if (note?.remoteId != null) {
      final owner = note!.ownerUserId ?? await AuthSession.getUserId();
      if (owner != null) {
        _pendingDeletes.add({'id': note.remoteId!, 'owner': owner});
      }
    }
    _notes = _notes.where((n) => n.id != id).toList();
    await _persist();
    notifyListeners();
    if (_pendingDeletes.isNotEmpty) unawaited(syncPending());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
    await prefs.setString(_kDeletesKey, jsonEncode(_pendingDeletes));
  }

  /// Starts one reconnect listener and retries durable local work at startup.
  void startSync() {
    _connectivity ??= Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        unawaited(syncPending());
      }
    });
    unawaited(syncPending());
  }

  /// Uses only the existing notes API. A failed request leaves the note on
  /// disk, ready for the next reconnect or app launch.
  Future<void> syncPending() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      await load();
      final owner = await AuthSession.getUserId();
      if (owner == null) return;
      for (final note in List<ReadingNote>.of(_notes)) {
        if (note.ownerUserId != owner ||
            note.realBookId == null ||
            note.remoteId != null) continue;
        try {
          final created = await UserNotesApiService.createNote(
              bookId: note.realBookId!, note: note.text, snippet: note.snippet);
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index < 0) {
            _pendingDeletes.add({'id': created.id, 'owner': owner});
          } else {
            _notes[index] = _notes[index].copyWith(
                remoteId: created.id,
                needsUpdate: _notes[index].text != note.text);
          }
          await _persist();
          notifyListeners();
        } catch (_) {
          break;
        }
      }
      for (final note in List<ReadingNote>.of(_notes)) {
        if (note.ownerUserId != owner ||
            note.remoteId == null ||
            !note.needsUpdate) continue;
        try {
          await UserNotesApiService.updateNote(note.remoteId!, note: note.text);
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index >= 0 && _notes[index].text == note.text) {
            _notes[index] = note.copyWith(needsUpdate: false);
            await _persist();
            notifyListeners();
          }
        } catch (_) {
          break;
        }
      }
      for (final item in List<Map<String, int>>.of(_pendingDeletes)) {
        if (item['owner'] != owner) continue;
        try {
          await UserNotesApiService.deleteNote(item['id']!);
          _pendingDeletes.remove(item);
          await _persist();
        } catch (_) {
          break;
        }
      }
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(syncPending());
      }
    }
  }

  Future<void> removeSyncedLocal(int remoteId) async {
    await load();
    _notes = _notes.where((n) => n.remoteId != remoteId).toList();
    await _persist();
    notifyListeners();
  }

  // The screen's original hardcoded notes, ported over as the first-run
  // seed so existing users don't see an empty list.
  static List<ReadingNote> _seedNotes() {
    final now = DateTime.now();
    ReadingNote seed(
            String id, String text, int index, String title, int color) =>
        ReadingNote(
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
      seed(
          'seed_1',
          '"Wagt hiç kimi garaşmaýar, ýöne hakyky söýgi hemişe garaşýar."',
          0,
          'Ýitgi we tapyş',
          HighlightColors.yellow.toARGB32()),
      seed('seed_2', '"Iň garaňky gijeden soň, iň ýagty daň gelýär."', 4,
          'Asman ýyldyzlary', HighlightColors.blue.toARGB32()),
      seed(
          'seed_3',
          '"Umyt — ýüreginde ýanýan ody hiç haçan öçürmeýän ýeke-täk zat."',
          8,
          'Umyt guşy',
          HighlightColors.green.toARGB32()),
    ];
  }
}
