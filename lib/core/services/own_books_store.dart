import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/own_book.dart';
import 'cbz_page_cache.dart';
import 'pdf_reflow_service.dart';

/// Persists the "Öz Kitaplarym" (own EPUB/PDF imports) list across app
/// restarts. Picked files are copied into app-owned storage so they keep
/// working even if the user deletes the original from Downloads/Files.
class OwnBooksStore extends ChangeNotifier {
  OwnBooksStore._();
  static final instance = OwnBooksStore._();

  static const _kKey = 'own_books_v1';

  List<OwnBook> _books = [];
  bool _loaded = false;

  List<OwnBook> get books => List.unmodifiable(_books);

  Future<void> load() async {
    if (_loaded) return;
    await _ensureLoaded();
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const [];
    final loaded = raw
        .map((s) => OwnBook.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // Drop entries whose backing file was lost (cache cleared, reinstall).
    _books = loaded.where((b) => File(b.filePath).existsSync()).toList();
    _loaded = true;
    if (_books.length != loaded.length) await _persist();
  }

  Future<OwnBook> addFromPickedFile(
      {required String sourcePath, required String fileName}) async {
    await _ensureLoaded();
    final lower = fileName.toLowerCase();
    final format = lower.endsWith('.pdf')
        ? OwnBookFormat.pdf
        : lower.endsWith('.cbz')
            ? OwnBookFormat.cbz
            : OwnBookFormat.epub;

    final docsDir = await getApplicationDocumentsDirectory();
    final ownDir = Directory('${docsDir.path}/own_books');
    if (!await ownDir.exists()) await ownDir.create(recursive: true);

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final destPath = '${ownDir.path}/$id-$fileName';
    await File(sourcePath).copy(destPath);

    final title = fileName.replaceAll(
        RegExp(r'\.(epub|pdf|cbz)$', caseSensitive: false), '');
    final book = OwnBook(
        id: id,
        title: title,
        filePath: destPath,
        format: format,
        addedAt: DateTime.now());

    _books = [book, ..._books];
    await _persist();
    notifyListeners();
    return book;
  }

  Future<void> remove(String id) async {
    await _ensureLoaded();
    final match = _books.where((b) => b.id == id);
    if (match.isEmpty) return;
    final book = match.first;
    _books = _books.where((b) => b.id != id).toList();
    await _persist();
    notifyListeners();
    try {
      await File(book.filePath).delete();
    } catch (_) {}
    // CbzReaderScreen extracts a CBZ's pages onto disk the first time it's
    // opened and never cleans them up itself (reuse across opens is the
    // point) — this was the other half of that: removing the book from the
    // library orphaned that extraction forever. No-ops for non-CBZ formats
    // and books that were never opened.
    if (book.format == OwnBookFormat.cbz) {
      await deleteCbzPageCache(book.filePath);
    }
    // Same idea for a PDF's generated reflow EPUB / "it's an image PDF"
    // marker (PdfReflowService) — otherwise removing the book orphans it.
    if (book.format == OwnBookFormat.pdf) {
      await PdfReflowService.instance.deleteCacheFor(book.filePath);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kKey, _books.map((b) => jsonEncode(b.toJson())).toList());
  }
}
