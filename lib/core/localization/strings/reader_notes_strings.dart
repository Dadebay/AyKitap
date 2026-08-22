import '../strings_base.dart';

/// Strings for highlighting/note-taking on a selected passage (TZ §12.7) —
/// the reader's selection toolbar ([SelectionToolbar], [PdfBottomBar]'s note
/// action) and the add-note sheet ([showAddNoteSheet], [showAddPageNoteSheet]
/// in page_note.dart). Split out of [ReaderStrings] to keep that file under
/// the 200-line limit; these two sections were combined here because most of
/// their call sites already need both.
class ReaderNotesStrings {
  ReaderNotesStrings._();

  // ── Selection toolbar ──────────────────────────────────────────────────
  static String get copyLabel =>
      t(tk: 'Kopyala', ru: 'Копировать', tr: 'Kopyala');
  static String get highlightLabel =>
      t(tk: 'Belle', ru: 'Выделить', tr: 'İşaretle');
  static String get noteLabel => t(tk: 'Not', ru: 'Заметка', tr: 'Not');
  static String get shareLabel =>
      t(tk: 'Paýlaş', ru: 'Поделиться', tr: 'Paylaş');
  static String get highlightedMessage =>
      t(tk: 'Bellendi', ru: 'Выделено', tr: 'İşaretlendi');
  static String get noteSavedMessage =>
      t(tk: 'Not goşuldy', ru: 'Заметка добавлена', tr: 'Not eklendi');
  static String get noteSaveFailedMessage => t(
        tk: 'Not saklanmady — internet baglanyşygyňyzy barlaň',
        ru: 'Не удалось сохранить заметку — проверьте подключение к интернету',
        tr: 'Not kaydedilemedi — internet bağlantınızı kontrol edin',
      );

  /// Shown in the selection toolbar instead of "Not" when the tapped passage
  /// is already highlighted — removes the highlight (and its note) rather
  /// than adding a new one.
  static String get removeHighlightLabel =>
      t(tk: 'Poz', ru: 'Удалить', tr: 'Kaldır');
  static String get highlightRemovedMessage =>
      t(tk: 'Bellik aýryldy', ru: 'Выделение удалено', tr: 'İşaret kaldırıldı');

  // ── Add-note sheet ──────────────────────────────────────────────────────
  static String get addNoteTitle =>
      t(tk: 'Not goş', ru: 'Добавить заметку', tr: 'Not ekle');
  static String get addNoteSubtitle => t(
        tk: 'Saýlanan tekst üçin bellik ýazyň',
        ru: 'Напишите заметку к выделенному тексту',
        tr: 'Seçili metin için not yazın',
      );

  /// The fixed-layout readers' variant: a PDF/CBZ page has no selectable text
  /// to quote, so the note is anchored to the page instead — see
  /// [showAddPageNoteSheet].
  static String get addPageNoteSubtitle => t(
        tk: 'Şu sahypa üçin bellik ýazyň',
        ru: 'Напишите заметку к этой странице',
        tr: 'Bu sayfa için not yazın',
      );
}
