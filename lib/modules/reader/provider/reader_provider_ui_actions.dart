part of 'reader_provider.dart';

/// Chrome visibility and text-selection UI state, plus the direct
/// navigation actions (page turn, jump to chapter/CFI) that don't belong to
/// any one of the other concerns.
extension ReaderProviderUiActions on ReaderProvider {
  bool get showControls => _showControls;

  String get selectedText => _selectedText;
  String? get selectedCfi => _selectedCfi;
  Rect? get selectionRect => _selectionRect;
  bool get hasSelection => _selectedText.isNotEmpty;

  /// The existing highlight whose CFI exactly matches the current selection,
  /// or null for a fresh selection with no highlight yet. Tapping an already
  /// painted highlight (see [EpubDisplaySettings]'s `selectAnnotationRange`
  /// on the viewer) re-selects the exact range it was created with, so an
  /// exact-string match against every saved note's own `cfi` is enough to
  /// tell "selecting new text" apart from "tapped an existing highlight" —
  /// letting the selection toolbar offer removal instead of adding a note.
  ReadingNote? get selectedHighlight {
    final bookId = _bookId;
    final cfi = _selectedCfi;
    if (bookId == null || cfi == null || cfi.isEmpty) return null;
    for (final note in NotesStore.instance.highlightsForBook(bookId: bookId)) {
      if (note.cfi == cfi) return note;
    }
    return null;
  }

  void toggleControls() {
    _showControls = !_showControls;
    _notify();
  }

  void hideControls() {
    if (_showControls) {
      _showControls = false;
      _notify();
    }
  }

  void clearSelection() {
    epubController.clearSelection();
    _selectedText = '';
    _selectedCfi = null;
    _selectionRect = null;
    _notify();
  }

  void nextPage() => epubController.next();
  void prevPage() => epubController.prev();

  void goToChapter(EpubChapter chapter) {
    final target = chapter.id.isNotEmpty && !chapter.href.contains('#')
        ? '${chapter.href}#${chapter.id}'
        : chapter.href;
    log('👉 goToChapter tapped="${chapter.title}" href=${chapter.href} → target=$target');
    epubController.display(cfi: target);
  }

  void goToCfi(String cfi) => epubController.display(cfi: cfi);
}
