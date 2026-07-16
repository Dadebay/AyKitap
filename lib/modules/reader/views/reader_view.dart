import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../provider/reader_provider.dart';
import '../widgets/reader_top_bar.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/chapter_list_sheet.dart';
import '../widgets/search_sheet.dart';
import '../widgets/selection_toolbar.dart';
import '../../../core/services/notes_store.dart';
import '../../profile/widgets/edit_note_sheet.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/strings/reader_strings.dart';

class ReaderScreen extends StatefulWidget {
  final String bookPath;
  final int bookId;
  final String bookTitle;

  /// Cover artwork (asset path) shown in the chapter-list sheet header. Null
  /// for the user's own imported files, which have no catalogue cover.
  final String? coverUrl;

  /// Total page count from the catalogue metadata, used to render an estimated
  /// "page X of Y" in the chapter-list header (the epub engine only exposes a
  /// 0–1 progress, so the page is derived from it). Null when unknown.
  final int? bookPages;

  /// The catalogue book's `book_{seed}_{index}` id (TZ §12.7). Present only
  /// when the reader was opened for a MockData book — highlights/notes taken
  /// here are linked back to it in the profile's Notlar list. Null for the
  /// user's own imported files, which no catalogue book can regenerate.
  final String? bookRef;

  const ReaderScreen({
    super.key,
    required this.bookPath,
    required this.bookId,
    required this.bookTitle,
    this.coverUrl,
    this.bookPages,
    this.bookRef,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Where/when the current touch began, in the WebView's normalised (0–1)
  // space — used to tell a tap apart from a swipe or a long press.
  Offset? _touchStart;
  DateTime? _touchStartAt;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderProvider>().initialize(bookId: widget.bookId, bookTitle: widget.bookTitle);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The reader is a pushed route, so it won't rebuild on a live language
    // switch unless it depends on [AppLocale] — watch it so the bars/labels
    // re-render in the app's current language while a book is open.
    context.watch<AppLocale>();
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        final bgColor = _extractBgColor(provider.currentEpubTheme);
        final isDarkPage = bgColor.computeLuminance() < 0.4;
        // In focus mode (chrome hidden) a faint chapter title / page number
        // stays on screen; they use the page's own contrast colour.
        final focusColor = isDarkPage ? Colors.white38 : Colors.black38;
        final inFocus = !provider.showControls && !provider.isLoading;

        return Scaffold(
          backgroundColor: bgColor,

          // The bars are *overlays*, not Scaffold appBar/bottomNavigationBar.
          // As slots they resized the body every time they toggled, which
          // resized the WebView and made epub.js repaginate — that's what
          // broke swiping to turn pages while the controls were on screen.
          // Floating them over a fixed-size viewer keeps pagination stable.
          body: Stack(
            children: [
              // ── EPUB Viewer ────────────────────────────────────────────
              // Brightness (TZ §12.4) now dims the *device* screen via
              // [ReaderProvider.setBrightness] rather than painting a black
              // veil over the page — the veil greyed out the text.
              Positioned.fill(child: _buildEpubViewer(provider)),

              // ── Top bar (TZ §12.1) ─────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !provider.showControls,
                  child: AnimatedSlide(
                    offset: provider.showControls ? Offset.zero : const Offset(0, -1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: provider.showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: ReaderTopBar(
                        // TZ §12.1: the centre shows the *chapter* name; the
                        // book title stands in until a chapter resolves.
                        title: provider.currentChapterTitle ?? widget.bookTitle,
                        isBookmarked: provider.isCurrentPageBookmarked,
                        pageColor: bgColor,
                        onBack: () async {
                          await provider.saveAndClose();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        onBookmark: () => _showBookmarks(context, provider),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom bar (pill design, TZ §12.3) ─────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !provider.showControls,
                  child: AnimatedSlide(
                    offset: provider.showControls ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: provider.showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: ReaderBottomBar(
                        progress: provider.progress,
                        currentPage: provider.currentPage,
                        totalPages: provider.totalPages,
                        pageColor: bgColor,
                        onSettings: () => _showSettings(context),
                        onChapters: () => _showChapters(context, provider),
                        onSearch: () => _showSearch(context, provider),
                        onProgressChanged: (value) => provider.epubController.toProgressPercentage(value),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Focus-mode chapter label (top) ─────────────────────────
              // Shown only while the chrome is hidden, so the reader still
              // knows the chapter without bringing the bars back.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: inFocus ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: Text(
                          provider.currentChapterTitle ?? widget.bookTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: focusColor, fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Focus-mode page number (bottom) ────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: inFocus ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Text(
                          _pageLabel(provider),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: focusColor, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Loading overlay ────────────────────────────────────────
              if (provider.isLoading) _LoadingOverlay(bgColor: bgColor),

              // ── Selection toolbar (TZ §12.7) ───────────────────────────
              if (provider.hasSelection)
                SelectionToolbar(
                  selectedText: provider.selectedText,
                  selectionRect: provider.selectionRect,
                  canAnnotate: _bookSeedIndex != null,
                  onHighlight: () => _highlight(context, provider),
                  onAddNote: () => _addNote(context, provider),
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: provider.selectedText));
                    provider.clearSelection();
                    _showSnack(context, ReaderStrings.copiedMessage);
                  },
                  onShare: () {
                    final text = provider.selectedText;
                    provider.clearSelection();
                    if (text.isNotEmpty) Share.share(text);
                  },
                  onClose: provider.clearSelection,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEpubViewer(ReaderProvider provider) {
    // No GestureDetector here: the EPUB renders inside a WebView, which
    // consumes touch events, so a Flutter tap handler wrapped around it never
    // fires — that's why the top/bottom bars could never be revealed. Instead
    // we use the touch callbacks sakura_epub forwards out of the page.
    return EpubViewer(
      epubController: provider.epubController,
      epubSource: EpubSource.fromFile(File(widget.bookPath)),
      displaySettings: EpubDisplaySettings(
        flow: EpubFlow.paginated,
        snap: true,
        theme: provider.currentEpubTheme,
        // sakura_epub takes fontSize as an int (percentage), while the
        // provider keeps it as a double for its slider — round on the way in.
        fontSize: provider.fontSize.round(),
      ),
      // TZ §12.7: our own selection toolbar (Belle / Not / Kopyala / Paýlaş)
      // is the only menu we want — suppress the WebView's native Android/iOS
      // one so it doesn't show a second, duplicate toolbar over the selection.
      suppressNativeContextMenu: true,
      onEpubLoaded: provider.onEpubLoaded,
      onChaptersLoaded: provider.onChaptersLoaded,
      onRelocated: provider.onRelocated,
      onTextSelected: provider.onTextSelected,
      onSelection: provider.onSelection,
      onDeselection: provider.onDeselection,
      onTouchDown: (x, y) {
        _touchStart = Offset(x, y);
        _touchStartAt = DateTime.now();
      },
      onTouchUp: (x, y) => _onTouchUp(provider, x, y),
    );
  }

  /// Toggles the reader chrome on a genuine tap. Coordinates arrive
  /// normalised (0–1). Swipes (page turns) and long presses (text selection)
  /// are filtered out so they don't flash the bars on every page change.
  void _onTouchUp(ReaderProvider provider, double x, double y) {
    final start = _touchStart;
    final startedAt = _touchStartAt;
    _touchStart = null;
    _touchStartAt = null;
    if (start == null || startedAt == null) return;

    final moved = (Offset(x, y) - start).distance;
    final held = DateTime.now().difference(startedAt);
    if (moved > 0.03 || held > const Duration(milliseconds: 300)) return;

    if (provider.hasSelection) {
      provider.clearSelection();
    } else {
      provider.toggleControls();
    }
  }

  /// The focus-mode page indicator. The epub engine only reports a 0–1
  /// progress, so when the catalogue gives a page count the page is estimated
  /// from it ("245"); otherwise it falls back to a percentage.
  String _pageLabel(ReaderProvider provider) {
    final p = provider.progress.clamp(0.0, 1.0);
    final total = widget.bookPages;
    if (total != null && total > 0) {
      return '${(p * total).round().clamp(1, total)}';
    }
    return '${(p * 100).round()}%';
  }

  /// Parses the catalogue book's `book_{seed}_{index}` id into (seed, index),
  /// or null when there's no catalogue book to link a note back to.
  (int, int)? get _bookSeedIndex {
    final ref = widget.bookRef;
    if (ref == null) return null;
    final m = RegExp(r'^book_(\d+)_(\d+)$').firstMatch(ref);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// TZ §12.7 "Sarymtyl bellemek": paints the selection yellow in the page and
  /// files it in the profile's Notlar list.
  void _highlight(BuildContext context, ReaderProvider provider) {
    final si = _bookSeedIndex;
    final text = provider.selectedText;
    final cfi = provider.selectedCfi;
    if (si == null || text.isEmpty) {
      provider.clearSelection();
      return;
    }
    if (cfi != null && cfi.isNotEmpty) {
      provider.epubController.addHighlight(cfi: cfi, color: const Color(0xFFFFE082), opacity: 0.4);
    }
    NotesStore.instance.add(text: text, bookSeed: si.$1, bookIndex: si.$2, bookTitle: widget.bookTitle);
    provider.clearSelection();
    _showSnack(context, ReaderStrings.highlightedMessage);
  }

  /// TZ §12.7 "Not goşmak": opens a sheet pre-filled with the quoted passage so
  /// the reader can annotate it; the saved note appears in the profile.
  Future<void> _addNote(BuildContext context, ReaderProvider provider) async {
    final si = _bookSeedIndex;
    final text = provider.selectedText;
    provider.clearSelection();
    if (si == null || text.isEmpty) return;

    final noteText = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditNoteSheet(
        initialText: '"$text"\n\n',
        title: ReaderStrings.addNoteTitle,
        subtitle: ReaderStrings.addNoteSubtitle,
      ),
    );
    if (noteText == null || noteText.isEmpty) return;
    await NotesStore.instance.add(text: noteText, bookSeed: si.$1, bookIndex: si.$2, bookTitle: widget.bookTitle);
    if (context.mounted) _showSnack(context, ReaderStrings.noteSavedMessage);
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ReaderProvider>(),
        child: const ReaderSettingsSheet(),
      ),
    );
  }

  void _showChapters(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ChapterListSheet(
          bookTitle: widget.bookTitle,
          coverImage: widget.coverUrl,
          bookPages: widget.bookPages,
        ),
      ),
    );
  }

  void _showBookmarks(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const BookmarksSheet(),
      ),
    );
  }

  void _showSearch(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SearchSheet(provider: provider),
    );
  }

  Color _extractBgColor(EpubTheme theme) {
    final dec = theme.backgroundDecoration;
    if (dec is BoxDecoration) return dec.color ?? Colors.white;
    return Colors.white;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final Color bgColor;
  const _LoadingOverlay({required this.bgColor});

  @override
  Widget build(BuildContext context) {
    final isDark = bgColor.computeLuminance() < 0.4;
    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: isDark ? Colors.white : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              ReaderStrings.bookOpening,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
