library flutter_epub_viewer;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

enum EpubFlow { paginated, scrolled }

class EpubTheme {
  final Decoration? backgroundDecoration;
  final Color? foregroundColor;
  final Map<String, String>? customCss;

  const EpubTheme._({this.backgroundDecoration, this.foregroundColor, this.customCss});

  factory EpubTheme.custom({
    Decoration? backgroundDecoration,
    Color? foregroundColor,
    Map<String, String>? customCss,
  }) =>
      EpubTheme._(backgroundDecoration: backgroundDecoration, foregroundColor: foregroundColor, customCss: customCss);
}

class EpubDisplaySettings {
  final EpubFlow flow;
  final bool snap;
  final EpubTheme? theme;
  final double fontSize;

  const EpubDisplaySettings({this.flow = EpubFlow.paginated, this.snap = true, this.theme, this.fontSize = 16.0});
}

class EpubSource {
  final File? file;
  final String? url;
  final List<int>? bytes;

  const EpubSource._({this.file, this.url, this.bytes});

  factory EpubSource.fromFile(File file) => EpubSource._(file: file);
  factory EpubSource.fromUrl(String url) => EpubSource._(url: url);
  factory EpubSource.fromBytes(List<int> bytes) => EpubSource._(bytes: bytes);
}

class EpubChapter {
  final String href;
  final String id;
  final String title;
  final int? startPage;
  final List<EpubChapter> subItems;

  const EpubChapter({required this.href, required this.id, required this.title, this.startPage, this.subItems = const []});
}

class EpubLocation {
  final double progress;
  final String startCfi;
  final String href;

  const EpubLocation({required this.progress, required this.startCfi, required this.href});
}

class EpubTextSelection {
  final String selectedText;
  final String selectionCfi;

  const EpubTextSelection({required this.selectedText, required this.selectionCfi});
}

class EpubMetadata {
  final String? title;
  final String? coverImage;
  final String? author;

  const EpubMetadata({this.title, this.coverImage, this.author});
}

class EpubController {
  _EpubViewerState? _state;

  void _attach(_EpubViewerState state) => _state = state;
  void _detach() => _state = null;

  void next() => _state?._next();
  void prev() => _state?._prev();
  void clearSelection() {}
  void display({required String cfi}) => _state?._display(cfi);
  void toProgressPercentage(double progress) => _state?._toProgress(progress);
  void setFontSize({required double fontSize}) => _state?._setFontSize(fontSize);
  void updateTheme({required EpubTheme theme}) => _state?._updateTheme(theme);
  void updateChapterStartPages(Map<String, int> pages) => _state?._updateChapterStartPages(pages);

  Future<Map<String, dynamic>> getPageInfo() async =>
      _state?._getPageInfo() ?? {'totalPages': 0, 'currentPage': 0, 'vppReady': false};

  Future<Map<String, int>> getAllChapterPages() async => _state?._getAllChapterPages() ?? {};

  Future<EpubMetadata> getMetadata() async => _state?._getMetadata() ?? const EpubMetadata();
}

class EpubViewer extends StatefulWidget {
  final EpubController epubController;
  final EpubSource epubSource;
  final EpubDisplaySettings displaySettings;
  final bool suppressNativeContextMenu;
  final String? cachedLocations;
  final void Function(String)? onLocationsCached;
  final void Function()? onEpubLoaded;
  final void Function(List<EpubChapter>)? onChaptersLoaded;
  final void Function(EpubLocation)? onRelocated;
  final void Function(EpubTextSelection)? onTextSelected;
  final void Function(String, String?, Rect?, Rect?)? onSelection;
  final void Function()? onDeselection;
  final void Function(double, double)? onTouchDown;
  final void Function(double, double)? onTouchUp;

  const EpubViewer({
    super.key,
    required this.epubController,
    required this.epubSource,
    required this.displaySettings,
    this.suppressNativeContextMenu = false,
    this.cachedLocations,
    this.onLocationsCached,
    this.onEpubLoaded,
    this.onChaptersLoaded,
    this.onRelocated,
    this.onTextSelected,
    this.onSelection,
    this.onDeselection,
    this.onTouchDown,
    this.onTouchUp,
  });

  @override
  State<EpubViewer> createState() => _EpubViewerState();
}

class _EpubViewerState extends State<EpubViewer> {
  int _currentPage = 0;
  int _totalPages = 100;
  double _fontSize = 16.0;
  EpubTheme? _theme;
  final Map<String, int> _chapterPages = {};

  @override
  void initState() {
    super.initState();
    widget.epubController._attach(this);
    _fontSize = widget.displaySettings.fontSize;
    _theme = widget.displaySettings.theme;
    Future.microtask(_simulateLoad);
  }

  @override
  void dispose() {
    widget.epubController._detach();
    super.dispose();
  }

  Future<void> _simulateLoad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onEpubLoaded?.call();
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onChaptersLoaded?.call([
      const EpubChapter(href: 'chapter1.html', id: 'ch1', title: 'Chapter 1'),
      const EpubChapter(href: 'chapter2.html', id: 'ch2', title: 'Chapter 2'),
    ]);
    await Future.delayed(const Duration(milliseconds: 200));
    widget.onRelocated?.call(const EpubLocation(progress: 0.0, startCfi: 'epubcfi(/6/2!)', href: 'chapter1.html'));
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onLocationsCached?.call('[]');
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _fireRelocated();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _fireRelocated();
    }
  }

  void _display(String cfi) {}
  void _toProgress(double progress) {
    setState(() => _currentPage = (progress * _totalPages).round().clamp(0, _totalPages - 1));
    _fireRelocated();
  }

  void _setFontSize(double fontSize) => setState(() => _fontSize = fontSize);
  void _updateTheme(EpubTheme theme) => setState(() => _theme = theme);
  void _updateChapterStartPages(Map<String, int> pages) => _chapterPages.addAll(pages);

  Map<String, dynamic> _getPageInfo() => {'currentPage': _currentPage, 'totalPages': _totalPages, 'vppReady': true};
  Map<String, int> _getAllChapterPages() => _chapterPages;
  EpubMetadata _getMetadata() => const EpubMetadata(title: 'Book', author: 'Author');

  void _fireRelocated() {
    final progress = _totalPages > 0 ? _currentPage / _totalPages : 0.0;
    widget.onRelocated?.call(EpubLocation(
      progress: progress,
      startCfi: 'epubcfi(/6/${_currentPage * 2}!/)',
      href: 'chapter1.html',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bg = (_theme?.backgroundDecoration as BoxDecoration?)?.color ?? Colors.white;
    final fg = _theme?.foregroundColor ?? Colors.black;

    return GestureDetector(
      onTapDown: (d) {
        final size = MediaQuery.of(context).size;
        widget.onTouchDown?.call(d.localPosition.dx / size.width, d.localPosition.dy / size.height);
      },
      onTapUp: (d) {
        final size = MediaQuery.of(context).size;
        widget.onTouchUp?.call(d.localPosition.dx / size.width, d.localPosition.dy / size.height);
      },
      child: Container(
        color: bg,
        child: Center(
          child: Text(
            'Page ${_currentPage + 1} / $_totalPages',
            style: TextStyle(color: fg, fontSize: _fontSize),
          ),
        ),
      ),
    );
  }
}
