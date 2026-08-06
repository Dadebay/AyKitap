import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One downloaded book file on disk — which book it belongs to, what format
/// it is, and where [BookOpenFlow] can find it without going near the
/// network.
class DownloadedFileEntry {
  final int bookId;

  /// `pdf` | `epub` | `cbz`, straight off `bookFiles[].file_format`.
  final String format;
  final String path;
  final int sizeBytes;
  final DateTime downloadedAt;

  const DownloadedFileEntry({
    required this.bookId,
    required this.format,
    required this.path,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  factory DownloadedFileEntry.fromJson(Map<String, dynamic> json) => DownloadedFileEntry(
        bookId: json['book_id'] as int,
        format: json['format'] as String? ?? '',
        path: json['path'] as String? ?? '',
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
        downloadedAt: DateTime.tryParse(json['downloaded_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'format': format,
        'path': path,
        'size_bytes': sizeBytes,
        'downloaded_at': downloadedAt.toIso8601String(),
      };
}

/// Maps a catalogue book id to the file(s) of it sitting in app-private
/// storage.
///
/// Deliberately separate from [DownloadedBooksStore], which persists the
/// *book* (cover, title, authors) for Kitaplygym's "Ýüklenenler" shelf and
/// knows nothing about paths or formats. The two are written together after
/// a successful download and cleared together when the user deletes it.
class DownloadedFilesStore extends ChangeNotifier {
  DownloadedFilesStore._();
  static final instance = DownloadedFilesStore._();

  static const _kKey = 'downloaded_book_files_v1';

  /// Which reader gives the best experience for the same book: the epub
  /// reader reflows (theme, font size, search, notes, bookmarks), a PDF is
  /// converted to one anyway when it has a text layer ([openPdfBook]), and
  /// a CBZ is fixed images with none of that.
  static const List<String> formatPriority = ['epub', 'pdf', 'cbz'];

  List<DownloadedFileEntry> _entries = [];
  bool _loaded = false;

  List<DownloadedFileEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    final parsed = raw.map((s) => DownloadedFileEntry.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    // Drop entries whose file is gone (reinstall, OS storage reclaim) so
    // "already downloaded" never means "opens a missing file".
    _entries = parsed.where((e) => File(e.path).existsSync()).toList();
    _loaded = true;
    if (_entries.length != parsed.length) await _persist();
    notifyListeners();
  }

  List<DownloadedFileEntry> forBook(int bookId) => _entries.where((e) => e.bookId == bookId).toList();

  /// The downloaded file to open for [bookId], best format first, or null
  /// if nothing of this book is on disk.
  DownloadedFileEntry? best(int bookId) {
    final mine = forBook(bookId);
    if (mine.isEmpty) return null;
    for (final format in formatPriority) {
      for (final entry in mine) {
        if (entry.format.toLowerCase() == format) return entry;
      }
    }
    return mine.first;
  }

  DownloadedFileEntry? find(int bookId, String format) {
    for (final entry in forBook(bookId)) {
      if (entry.format.toLowerCase() == format.toLowerCase()) return entry;
    }
    return null;
  }

  bool hasAnyFile(int bookId) => _entries.any((e) => e.bookId == bookId);

  Future<void> add(DownloadedFileEntry entry) async {
    await load();
    _entries = [
      entry,
      ..._entries.where((e) => !(e.bookId == entry.bookId && e.format.toLowerCase() == entry.format.toLowerCase())),
    ];
    await _persist();
    notifyListeners();
  }

  /// Forgets every file of [bookId] *and* deletes them from disk — this is
  /// what "Ýüklemäni poz" in Kitaplygym actually frees.
  Future<void> removeBook(int bookId) async {
    await load();
    final doomed = forBook(bookId);
    _entries = _entries.where((e) => e.bookId != bookId).toList();
    await _persist();
    notifyListeners();
    for (final entry in doomed) {
      try {
        final file = File(entry.path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // A file we can't delete is still gone from the library; leaking
        // it is better than failing the user's delete.
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _entries.map((e) => jsonEncode(e.toJson())).toList());
  }
}
