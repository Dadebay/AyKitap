import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stable_hash.dart';
import '../../reader/provider/reader_provider.dart';
import '../../reader/views/cbz_reader_screen.dart';
import '../../reader/views/pdf_reader_screen.dart';
import '../../reader/views/reader_view.dart';

/// Dev-only list of every book bundled under `assets/books/`, opening each one
/// directly in the reader it belongs to — EPUBs in [ReaderScreen], PDFs in
/// [PdfReaderScreen], CBZs in [CbzReaderScreen] — the same three-way split
/// "Öz Kitaplarym" makes for imports.
///
/// The catalogue can't answer "does this file open?": mock books are mapped
/// onto a sample EPUB by `stableBookKey(book.id) % assets.length`, so which
/// file a given cover opens is arbitrary and several covers share one file. This
/// lists the files themselves, by name, one tap each.
///
/// Delete once the backend serves per-book content.
enum _BookFormat { epub, pdf, cbz }

class BundledBooksDebugScreen extends StatefulWidget {
  const BundledBooksDebugScreen({super.key});

  @override
  State<BundledBooksDebugScreen> createState() => _BundledBooksDebugScreenState();
}

class _BundledBooksDebugScreenState extends State<BundledBooksDebugScreen> {
  List<String>? _assets;
  String? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest
        .listAssets()
        .where((k) => k.startsWith('assets/books/') && _formatOf(k) != null)
        .toList()
      ..sort();
    if (mounted) setState(() => _assets = keys);
  }

  /// The reader an asset opens in, or null for a file that is neither format —
  /// `assets/books/` is a plain directory in the pubspec, so anything dropped in
  /// there shows up in the manifest and has to be filtered by extension.
  static _BookFormat? _formatOf(String assetKey) {
    final k = assetKey.toLowerCase();
    if (k.endsWith('.epub')) return _BookFormat.epub;
    if (k.endsWith('.pdf')) return _BookFormat.pdf;
    if (k.endsWith('.cbz')) return _BookFormat.cbz;
    return null;
  }

  /// Both readers need a real filesystem path (EpubSource.fromFile / PDFView's
  /// filePath), not an asset key, so the asset is copied out on first open and
  /// reused after.
  Future<String> _materialise(String assetKey) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/sample_books');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

    final dest = File('${cacheDir.path}/${assetKey.split('/').last}');
    if (!await dest.exists()) {
      final data = await rootBundle.load(assetKey);
      await dest.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return dest.path;
  }

  Future<void> _open(String assetKey) async {
    if (_opening != null) return;
    setState(() => _opening = assetKey);
    final name = _titleOf(assetKey);
    try {
      final path = await _materialise(assetKey);
      if (!mounted) return;
      // Each file gets its own id so progress and bookmarks don't bleed
      // between them while testing.
      final Widget screen = switch (_formatOf(assetKey)) {
        _BookFormat.pdf => PdfReaderScreen(filePath: path, title: name, bookId: stableBookKey(assetKey)),
        _BookFormat.cbz => CbzReaderScreen(filePath: path, title: name, bookId: stableBookKey(assetKey)),
        _ => ChangeNotifierProvider(
            create: (_) => ReaderProvider(),
            child: ReaderScreen(bookPath: path, bookId: stableBookKey(assetKey), bookTitle: name),
          ),
      };
      await context.push(screen);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name açılmadı: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  String _titleOf(String assetKey) {
    final file = assetKey.split('/').last;
    final dot = file.lastIndexOf('.');
    return dot == -1 ? file : file.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    final assets = _assets;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.white,
        title: Text(
          assets == null ? HomeStrings.bundledBooksTitle : '${HomeStrings.bundledBooksTitle} (${assets.length})',
          style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: assets == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: assets.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final key = assets[i];
                final busy = _opening == key;
                return ListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    _titleOf(key),
                    style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  // Which reader a tap lands in — the two are entirely separate
                  // screens, so it matters which one a failure came from.
                  subtitle: Text(
                    switch (_formatOf(key)) {
                      _BookFormat.pdf => 'PDF',
                      _BookFormat.cbz => 'CBZ',
                      _ => 'EPUB',
                    },
                    style: TextStyle(color: AppColors.grey3, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  trailing: busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
                  onTap: () => _open(key),
                );
              },
            ),
    );
  }
}
