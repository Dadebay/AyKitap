import 'package:flutter/material.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/notes_store.dart';
import '../../../core/services/user_notes_api_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../profile/widgets/edit_note_sheet.dart';

/// TZ §12.7 "Not goşmak" for the fixed-layout readers ([PdfReaderScreen],
/// [CbzReaderScreen]).
///
/// The EPUB reader anchors a note to the passage the reader selected — it has
/// reflowable text, so a selection and a CFI exist. A PDF page is drawn by
/// PDFium and a CBZ page is a bitmap: neither exposes selectable text, so
/// there is nothing to quote and nothing to paint a highlight on. The page
/// itself is the only anchor those formats can offer, so the note opens
/// pre-filled with "Sahypa 12 / 300" (editable, exactly like the EPUB's quote
/// prefill) and that same label goes to the backend as the note's `snippet` —
/// which is the line the profile's Notlar card shows above the note text.
///
/// Kept out of both screens so the two stay identical: they already share a
/// bottom bar, bookmarks sheet and go-to-page sheet, and a note flow that
/// drifted between them would be a note flow that behaves differently
/// depending on which fixed-layout book you happen to be reading.
Future<void> showAddPageNoteSheet(
  BuildContext context, {
  /// The reader's own scoping id — the catalogue id for a downloaded book, a
  /// hashed file path for an import. Same key the book's bookmarks use.
  required int bookId,

  /// The real `/books/:id` id, or null for the user's own imported files. Set
  /// means the note is also persisted via `POST /users/notes` — see
  /// [ReaderScreen.realBookId]; that backend copy is the only thing the
  /// profile's "Notlar" list reads, so without it a note stays local-only.
  required int? realBookId,
  required String bookTitle,

  /// 1-based, as the reader displays it.
  required int page,
  required int totalPages,
}) async {
  // Same guard as the go-to-page sheet: until the document reports its length
  // there is no page to anchor to (the bars are still sitting over the opening
  // animation at that point).
  if (totalPages <= 0) return;

  final pageLabel = ReaderStrings.pageOfPages(page, totalPages);
  final draft = await showModalBottomSheet<NoteDraft>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => EditNoteSheet(
      initialText: '$pageLabel\n\n',
      title: ReaderStrings.addNoteTitle,
      subtitle: ReaderStrings.addPageNoteSubtitle,
    ),
  );
  if (draft == null || draft.text.isEmpty) return;

  // See ReaderScreen._addNote for why the sync has to succeed *before*
  // anything is stored locally: a catalogue book's note is only ever shown in
  // the profile's Notlar list, which reads from the backend alone, so one that
  // failed to sync would look saved (snackbar and all) and then be nowhere.
  int? remoteId;
  if (realBookId != null) {
    try {
      final created = await UserNotesApiService.createNote(
        bookId: realBookId,
        note: draft.text,
        snippet: pageLabel,
      );
      remoteId = created.id;
    } on ApiException {
      if (context.mounted) {
        context.showAppSnackBar(ReaderStrings.noteSaveFailedMessage, isError: true);
      }
      return;
    }
  }

  // No `cfi`: it is an EPUB CFI that ReaderProvider feeds straight to
  // epub.js's addHighlight when a book opens. A PDF's reflowed text view
  // ([PdfReflowService]) opens under the *same* bookId, so stashing a page
  // reference in that field would hand the EPUB engine "page:12" to resolve.
  // The page lives in the note's text and snippet instead.
  await NotesStore.instance.add(
    text: draft.text,
    bookId: bookId,
    bookTitle: bookTitle,
    colorValue: draft.colorValue,
    remoteId: remoteId,
  );
  if (context.mounted) context.showAppSnackBar(ReaderStrings.noteSavedMessage);
}
