part of 'reader_view.dart';

/// Adding/removing a highlight+note from the current text selection (TZ
/// §12.7) — the backend sync for catalogue books and the local
/// [NotesStore] write every reader shares.
extension _ReaderViewNotes on _ReaderScreenState {
  /// Parses the catalogue book's `book_{seed}_{index}` id into (seed, index),
  /// or null when there's no catalogue book to link a note back to.
  (int, int)? get _bookSeedIndex {
    final ref = widget.bookRef;
    if (ref == null) return null;
    final m = RegExp(r'^book_(\d+)_(\d+)$').firstMatch(ref);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// TZ §12.7 "Not goşmak": opens a sheet pre-filled with the quoted passage
  /// and a colour picker so the reader can annotate it; the saved note appears
  /// in the profile. Also paints the passage on the page when a CFI is known.
  Future<void> _addNote(BuildContext context, ReaderProvider provider) async {
    final text = provider.selectedText;
    final cfi = provider.selectedCfi;
    provider.clearSelection();
    if (text.isEmpty) return;

    final draft = await showModalBottomSheet<NoteDraft>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditNoteSheet(
        initialText: '"$text"\n\n',
        title: ReaderNotesStrings.addNoteTitle,
        subtitle: ReaderNotesStrings.addNoteSubtitle,
      ),
    );
    if (draft == null || draft.text.isEmpty) return;

    // A catalogue book (realBookId set) syncs this note to the backend's
    // own `GET /users/notes` list — the only place a note is shown outside
    // this book's own highlights, so one that fails to sync would look
    // saved here (highlight painted, snackbar shown) but never actually
    // appear there. Require the sync to succeed before painting/persisting
    // anything locally rather than save a note the profile can never
    // display. Imported files have no realBookId and no backend list to
    // join, so they stay local-only, same as always.
    int? remoteId;
    final realBookId = widget.realBookId;
    if (realBookId != null) {
      try {
        final created = await UserNotesApiService.createNote(
          bookId: realBookId,
          note: draft.text,
          snippet: text,
        );
        remoteId = created.id;
      } on ApiException {
        if (context.mounted)
          _showSnack(context, ReaderNotesStrings.noteSaveFailedMessage,
              isError: true);
        return;
      }
    }

    final si = _bookSeedIndex;
    if (cfi != null && cfi.isNotEmpty) {
      provider.epubController.addHighlight(
          cfi: cfi,
          color: Color(draft.colorValue),
          opacity: HighlightColors.highlightOpacity);
    }
    await NotesStore.instance.add(
      text: draft.text,
      bookId: widget.bookId,
      bookSeed: si?.$1,
      bookIndex: si?.$2,
      bookTitle: widget.bookTitle,
      colorValue: draft.colorValue,
      cfi: cfi,
      remoteId: remoteId,
    );
    if (context.mounted)
      _showSnack(context, ReaderNotesStrings.noteSavedMessage);
  }

  /// Reverse of [_addNote]: tapping an already-painted highlight re-selects
  /// its exact range (see the viewer's `selectAnnotationRange`), which
  /// [ReaderProvider.selectedHighlight] matches back to the note that
  /// created it — this erases both the paint on the page and the saved note,
  /// which was previously impossible to undo once a highlight was made.
  Future<void> _removeHighlight(
      BuildContext context, ReaderProvider provider) async {
    final note = provider.selectedHighlight;
    provider.clearSelection();
    if (note == null) return;
    final cfi = note.cfi;
    if (cfi != null && cfi.isNotEmpty) {
      provider.epubController.removeHighlight(cfi: cfi);
    }
    final remoteId = note.remoteId;
    if (remoteId != null) {
      try {
        await UserNotesApiService.deleteNote(remoteId);
      } on ApiException {
        // Best-effort: removing a highlight is the user explicitly undoing
        // it, and blocking that on a flaky connection would leave them
        // stuck with one they can't get rid of. Worst case the backend
        // keeps a note the profile's "Notlar" list still shows — still
        // deletable from there directly.
      }
    }
    await NotesStore.instance.remove(note.id);
    if (context.mounted)
      _showSnack(context, ReaderNotesStrings.highlightRemovedMessage);
  }
}
