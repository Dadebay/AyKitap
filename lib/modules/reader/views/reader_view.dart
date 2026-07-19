import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
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
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/highlight_colors.dart';
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

  // Kept separate from provider.isLoading so the overlay can finish its
  // 100% animation and hold briefly instead of vanishing the instant the
  // epub actually becomes ready.
  bool _showLoadingOverlay = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReaderProvider>()
          .initialize(bookId: widget.bookId, bookTitle: widget.bookTitle);
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

        return PopScope(
          // System back gesture/button bypasses ReaderTopBar's onBack, which
          // is the only place progress used to get saved — losing a whole
          // session's progress on a swipe-back. Intercept and route it
          // through the same saveAndClose() path.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await provider.saveAndClose();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Scaffold(
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
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: _viewerInset,
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (e) => debugPrint('[FLUTTER-POINTER] down at ${e.localPosition}'),
                        onPointerMove: (e) => debugPrint('[FLUTTER-POINTER] move at ${e.localPosition}'),
                        onPointerUp: (e) => debugPrint('[FLUTTER-POINTER] up at ${e.localPosition}'),
                        child: provider.loadFailed
                            ? _EpubErrorView(bgColor: bgColor, isDarkPage: isDarkPage)
                            : _buildEpubViewer(provider),
                      ),
                    ),
                  ),
                ),

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
                // Nothing here has meaning once the book failed to load — no
                // pages, chapters or search to offer.
                if (!provider.loadFailed)
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
                if (_showLoadingOverlay)
                  _LoadingOverlay(
                    bgColor: bgColor,
                    loaded: !provider.isLoading,
                    onDone: () {
                      if (mounted) setState(() => _showLoadingOverlay = false);
                    },
                  ),

                // ── Selection toolbar (TZ §12.7) ───────────────────────────
                if (provider.hasSelection)
                  SelectionToolbar(
                    selectedText: provider.selectedText,
                    selectionRect: provider.selectionRect,
                    // Every book can be annotated now — imported files just
                    // won't offer "go to book" on the saved note (no catalogue
                    // entry to open); see NoteCard.
                    canAnnotate: true,
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
          ),
        );
      },
    );
  }

  /// Vertical breathing room reserved around the page text.
  ///
  /// It has to be taken out of the *viewer's own box*, not added as CSS
  /// padding: epub.js paginates to fill the WebView's viewport and writes its
  /// own `padding: 20px` straight onto the book's `<body>` as an inline style,
  /// which no rule we inject through the theme can outrank. Shrinking the
  /// viewport is the only lever that epub.js actually lays out against.
  ///
  /// Sized to clear the focus-mode chapter title and page number, which float
  /// over the page while the chrome is hidden and used to land on top of the
  /// text. [SafeArea] handles the notch and gesture bar; this is on top of it.
  static const _viewerInset = EdgeInsets.only(top: 26, bottom: 30);

  Widget _buildEpubViewer(ReaderProvider provider) {
    // No GestureDetector here: the EPUB renders inside a WebView, which
    // consumes touch events, so a Flutter tap handler wrapped around it never
    // fires — that's why the top/bottom bars could never be revealed. Instead
    // we use the touch callbacks sakura_epub forwards out of the page.
    return EpubViewer(
      epubController: provider.epubController,
      epubSource: EpubSource.fromFile(File(widget.bookPath)),
      // Opens the WebView directly at the saved position — see
      // ReaderProvider.savedCfi for why this replaced a post-load progress
      // jump that raced book.locations.generate() on large books.
      initialCfi: provider.savedCfi.isEmpty ? null : provider.savedCfi,
      // Skips epub.js's multi-second locations scan on reopen — see
      // ReaderProvider.savedLocationsJson.
      initialLocations: provider.savedLocationsJson,
      onLocationsGenerated: provider.onLocationsGenerated,
      displaySettings: EpubDisplaySettings(
        flow: EpubFlow.paginated,
        snap: true,
        theme: provider.currentEpubTheme,
        // sakura_epub applies this as `${fontSize}px`, while the provider keeps
        // it as a double for its slider — round on the way in. This only seeds
        // the initial load; ReaderProvider.onEpubLoaded re-applies the saved
        // size once the rendition exists.
        fontSize: provider.fontSize.round(),
      ),
      // TZ §12.7: our own selection toolbar (Belle / Not / Kopyala / Paýlaş)
      // is the only menu we want — suppress the WebView's native Android/iOS
      // one so it doesn't show a second, duplicate toolbar over the selection.
      suppressNativeContextMenu: true,
      onEpubLoaded: provider.onEpubLoaded,
      onEpubLoadFailed: provider.onEpubLoadFailed,
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

  /// The focus-mode page indicator: "12 / 340".
  ///
  /// The epub engine counts the book's pages a few seconds after it opens (see
  /// [EpubLocation.page]); until it reports them, this falls back to a page
  /// estimated from the catalogue's page count, and to a bare percentage for
  /// imported files that have no catalogue entry.
  String _pageLabel(ReaderProvider provider) {
    if (provider.totalPages > 0) {
      return '${provider.currentPage} / ${provider.totalPages}';
    }
    final p = provider.progress.clamp(0.0, 1.0);
    final total = widget.bookPages;
    if (total != null && total > 0) {
      return '${(p * total).round().clamp(1, total)} / $total';
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
        title: ReaderStrings.addNoteTitle,
        subtitle: ReaderStrings.addNoteSubtitle,
      ),
    );
    if (draft == null || draft.text.isEmpty) return;
    final si = _bookSeedIndex;
    if (cfi != null && cfi.isNotEmpty) {
      provider.epubController.addHighlight(cfi: cfi, color: Color(draft.colorValue), opacity: HighlightColors.highlightOpacity);
    }
    await NotesStore.instance.add(
      text: draft.text,
      bookId: widget.bookId,
      bookSeed: si?.$1,
      bookIndex: si?.$2,
      bookTitle: widget.bookTitle,
      colorValue: draft.colorValue,
      cfi: cfi,
    );
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

/// Shown in place of the WebView when the book fails to open or render — see
/// [ReaderProvider.loadFailed]. Styled to match the PDF/CBZ readers' own
/// error screens so a bad file looks the same no matter which format it is.
class _EpubErrorView extends StatelessWidget {
  final Color bgColor;
  final bool isDarkPage;

  const _EpubErrorView({required this.bgColor, required this.isDarkPage});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedFileNotFound,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ReaderStrings.epubOpenError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkPage ? Colors.white70 : Colors.black54,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Book-opening screen: [book_reading_boy.json] plus a 0→100% readout.
///
/// The underlying load (read file → base64-encode → hand to the WebView →
/// epub.js parses and paginates) exposes no byte-level progress, so there's
/// nothing genuine to report — the percentage below is a timed ramp, not a
/// measurement. It eases up to 92% over ~3s and holds there for however long
/// the real load takes, then snaps to 100% the moment [loaded] actually turns
/// true, holds briefly so the number is readable, and calls [onDone].
class _LoadingOverlay extends StatefulWidget {
  final Color bgColor;
  final bool loaded;
  final VoidCallback onDone;

  const _LoadingOverlay({
    required this.bgColor,
    required this.loaded,
    required this.onDone,
  });

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay> with SingleTickerProviderStateMixin {
  static const _rampCeiling = 0.92;
  static const _rampDuration = Duration(milliseconds: 3200);
  static const _finishDuration = Duration(milliseconds: 260);
  static const _holdAt100 = Duration(milliseconds: 400);

  late final AnimationController _controller;
  late Animation<double> _percent;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _rampDuration);
    _percent = Tween<double>(begin: 0, end: _rampCeiling).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    if (widget.loaded) _finish();
  }

  @override
  void didUpdateWidget(covariant _LoadingOverlay old) {
    super.didUpdateWidget(old);
    if (widget.loaded && !old.loaded) _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final start = _percent.value;
    _controller
      ..stop()
      ..duration = _finishDuration;
    _percent = Tween<double>(begin: start, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.value = 0;
    await _controller.forward();
    await Future.delayed(_holdAt100);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.4;
    final fg = isDark ? Colors.white : Colors.black87;
    final fgMuted = isDark ? Colors.white54 : Colors.black45;

    return Container(
      color: widget.bgColor,
      child: Center(
        child: AnimatedBuilder(
          animation: _percent,
          builder: (context, _) {
            final shown = (_percent.value * 100).round().clamp(0, 100);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.asset(
                    'assets/animations/book_reading_boy.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$shown%',
                  style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _percent.value,
                      minHeight: 5,
                      backgroundColor: fgMuted.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ReaderStrings.bookOpening,
                  style: TextStyle(color: fgMuted, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
