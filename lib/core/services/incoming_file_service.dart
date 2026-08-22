import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../modules/reader/provider/reader_provider.dart';
import '../../modules/reader/utils/pdf_book_opener.dart';
import '../../modules/reader/views/cbz_reader_screen.dart';
import '../../modules/reader/views/reader_view.dart';
import '../models/own_book.dart';
import '../navigation/root_navigator.dart';
import '../utils/stable_hash.dart';
import 'analytics_service.dart';
import 'own_books_store.dart';

/// Bridges the native "Open with" hand-off (MainActivity.kt on Android,
/// SceneDelegate.swift on iOS) into the same import + open flow a file
/// manually picked in [OwnBooksTab] already goes through: copy into
/// [OwnBooksStore], then push the matching reader.
class IncomingFileService {
  IncomingFileService._();
  static final instance = IncomingFileService._();

  static const _channel = MethodChannel('com.aykitap.aykitap/incoming_file');
  static const _supportedExtensions = {'.pdf', '.epub', '.cbz'};

  bool _initialized = false;

  /// Call once the app shell (post-splash/onboarding) is mounted, so a
  /// cold-start file has a Navigator to open into.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onIncomingFile') {
        final path = call.arguments as String?;
        if (path != null) unawaited(_open(path));
      }
    });
    unawaited(
      _channel.invokeMethod<String>('getInitialFile').then((path) {
        if (path != null) unawaited(_open(path));
      }),
    );
  }

  Future<void> _open(String sourcePath) async {
    if (!_supportedExtensions.contains(_extensionOf(sourcePath))) return;
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    OwnBook book;
    try {
      await OwnBooksStore.instance.load();
      book = await OwnBooksStore.instance.addFromPickedFile(
          sourcePath: sourcePath, fileName: _basenameOf(sourcePath));
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    AnalyticsService.instance
        .logBookOpened(id: book.id, format: book.format.name);
    final bookId = stableBookKey(book.id);
    switch (book.format) {
      case OwnBookFormat.pdf:
        openPdfBook(context,
            filePath: book.filePath, title: book.title, bookId: bookId);
      case OwnBookFormat.cbz:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CbzReaderScreen(
                    filePath: book.filePath,
                    title: book.title,
                    bookId: bookId)));
      case OwnBookFormat.epub:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => ReaderProvider(),
              child: ReaderScreen(
                  bookPath: book.filePath,
                  bookId: bookId,
                  bookTitle: book.title),
            ),
          ),
        );
    }
  }

  String _basenameOf(String path) => path.split(Platform.pathSeparator).last;

  String _extensionOf(String path) {
    final name = _basenameOf(path);
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot).toLowerCase();
  }
}
