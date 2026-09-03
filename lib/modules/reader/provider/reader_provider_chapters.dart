part of 'reader_provider.dart';

/// Table-of-contents lookup (TZ §12.1): resolving the chapter title for the
/// page currently on screen, matching a chapter list entry against the
/// reader's position, and reconciling TOC hrefs against spine hrefs — the
/// two rarely agree on anchors, query strings or directory prefixes.
extension ReaderProviderChapters on ReaderProvider {
  List<EpubChapter> get chapters => _chapters;

  /// TZ §12.1 — the chapter name shown in the reader's top bar; null while the
  /// position is still unknown or the entry isn't in the TOC, so the caller can
  /// fall back to the book title.
  String? get currentChapterTitle {
    if (_currentTocHref.isEmpty || _chapters.isEmpty) return null;
    final target = _tocKey(_currentTocHref);

    String? walk(List<EpubChapter> list) {
      for (final c in list) {
        if (_tocKey(c.href) == target && c.title.trim().isNotEmpty) {
          return c.title.trim();
        }
        final fromChild = walk(c.subitems);
        if (fromChild != null) return fromChild;
      }
      return null;
    }

    // Matching is exact, so at most one entry answers — no need to prefer the
    // deepest. Fall back to the file if the resolved entry isn't in the TOC.
    return walk(_chapters) ?? chapterTitleForHref(_currentHref);
  }

  /// The TOC title for a spine [href], or null when the href isn't in the TOC.
  /// Search results carry the href of the chapter they were found in, so this
  /// is how they get labelled.
  String? chapterTitleForHref(String? href) {
    if (href == null || href.isEmpty || _chapters.isEmpty) return null;
    final target = _normalizeHref(href);
    if (target.isEmpty) return null;

    String? walk(List<EpubChapter> list) {
      // Depth-first, deepest match wins: a subitem is more specific than the
      // top-level entry that contains it.
      for (final c in list) {
        final fromChild = walk(c.subitems);
        if (fromChild != null) return fromChild;
        if (_normalizeHref(c.href) == target && c.title.trim().isNotEmpty) {
          return c.title.trim();
        }
      }
      return null;
    }

    return walk(_chapters);
  }

  /// Whether [chapter] is the one currently on screen — used by the chapter
  /// list to highlight where the reader is. Anchor-exact: a book that packs
  /// twelve chapters into one xhtml would otherwise light all twelve up.
  bool isChapterCurrent(EpubChapter chapter) {
    if (_currentTocHref.isEmpty || chapter.href.isEmpty) return false;
    return _tocKey(chapter.href) == _tocKey(_currentTocHref);
  }

  /// TOC hrefs and spine hrefs often disagree on anchors (`#id`), query
  /// strings and directory prefixes (`OEBPS/text/ch1.xhtml` vs `ch1.xhtml`),
  /// so compare on the bare file name only. Deliberately drops the anchor —
  /// use [_tocKey] to tell chapters within a file apart.
  String _normalizeHref(String href) {
    var h = href.split('#').first.split('?').first;
    final slash = h.lastIndexOf('/');
    if (slash != -1) h = h.substring(slash + 1);
    return h.trim();
  }

  /// Identity of a single TOC entry: file name plus anchor. Two entries in the
  /// same file with different anchors are different chapters, which is exactly
  /// what [_normalizeHref] throws away.
  String _tocKey(String href) {
    final hash = href.indexOf('#');
    final anchor =
        hash == -1 ? '' : href.substring(hash + 1).split('?').first.trim();
    return '${_normalizeHref(href)}#$anchor';
  }

  void onChaptersLoaded(List<EpubChapter> chapters) {
    log('📑 Chapters loaded: ${chapters.length}');
    _chapters = chapters;
    _notify();
    // The current position's chapter title can only resolve once the TOC is
    // in, so republish the progress snapshot too — see _updateProgressSnapshot.
    _updateProgressSnapshot();
  }
}
