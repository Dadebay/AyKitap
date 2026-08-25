import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_book.dart';
import '../network/api_config.dart';
import 'home_screen_widget_service.dart';

/// The one catalogue book surfaced by the Play tab. Reader-specific page
/// state remains in each reader's existing preferences; this stores the
/// metadata needed to find and reopen that book after an app restart.
class LastReadBook {
  final int bookId;
  final String title;

  /// Comma-joined author names ([LibraryBook.authorNames]), kept only so the
  /// home-screen widgets can show who wrote the book without a catalogue
  /// round-trip. Null for records persisted before this field existed.
  final String? author;
  final String? image;
  final String path;
  final String format;
  final int? pageCount;
  final int page;

  const LastReadBook({
    required this.bookId,
    required this.title,
    this.author,
    required this.image,
    required this.path,
    required this.format,
    required this.pageCount,
    required this.page,
  });

  LastReadBook copyWith({String? path, String? format, int? page}) =>
      LastReadBook(
        bookId: bookId,
        title: title,
        author: author,
        image: image,
        path: path ?? this.path,
        format: format ?? this.format,
        pageCount: pageCount,
        page: page ?? this.page,
      );

  factory LastReadBook.fromJson(Map<String, dynamic> json) => LastReadBook(
        bookId: json['book_id'] as int,
        title: json['title'] as String? ?? '',
        author: json['author'] as String?,
        image: json['image'] as String?,
        path: json['path'] as String? ?? '',
        format: json['format'] as String? ?? '',
        pageCount: json['page_count'] as int?,
        page: json['page'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'title': title,
        if (author != null) 'author': author,
        if (image != null) 'image': image,
        'path': path,
        'format': format,
        if (pageCount != null) 'page_count': pageCount,
        'page': page,
      };
}

class LastReadBookStore extends ChangeNotifier {
  LastReadBookStore._();
  static final instance = LastReadBookStore._();

  static const _kKey = 'last_read_catalogue_book_v1';

  LastReadBook? _book;
  bool _loaded = false;

  LastReadBook? get book => _book;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        _book = LastReadBook.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_kKey);
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Called immediately before any real catalogue reader is opened. Keep the
  /// existing page for a re-open: each reader restores the same page from its
  /// own preferences, and resetting this card to page 1 would be misleading.
  Future<void> recordOpened({
    required LibraryBook book,
    required String path,
    required String format,
  }) async {
    await load();
    final existingPage = _book?.bookId == book.id ? _book!.page : 0;
    final authorNames = book.authorNames;
    _book = LastReadBook(
      bookId: book.id,
      title: book.name,
      author: authorNames.isEmpty ? null : authorNames,
      image: book.image,
      path: path,
      format: format.toLowerCase(),
      pageCount: book.pageCount,
      page: existingPage,
    );
    await _persist();
    unawaited(_syncWidget(includeCover: true));
    notifyListeners();
  }

  /// Reader views call this alongside their normal page persistence.
  Future<void> updatePage({required int bookId, required int page}) async {
    await load();
    final current = _book;
    if (current == null || current.bookId != bookId || current.page == page) {
      return;
    }
    _book = current.copyWith(page: page);
    await _persist();
    unawaited(_syncWidget());
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final current = _book;
    if (current == null) {
      await prefs.remove(_kKey);
    } else {
      await prefs.setString(_kKey, jsonEncode(current.toJson()));
    }
  }

  Future<void> _syncWidget({bool includeCover = false}) async {
    final current = _book;
    await HomeScreenWidgetService.syncBook(
      bookId: current?.bookId,
      title: current?.title,
      author: current?.author,
      page: current?.page ?? 0,
      pageCount: current?.pageCount,
      coverUrl: includeCover && current?.image != null
          ? ApiConfig.resolveImageUrl(current!.image!)
          : null,
      updateCover: includeCover,
    );
  }
}
