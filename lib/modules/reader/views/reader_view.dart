import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../widgets/reader_top_bar.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/chapter_list_sheet.dart';
import '../widgets/selection_toolbar.dart';
import '../../../core/localization/strings/reader_strings.dart';

class ReaderScreen extends StatefulWidget {
  final String bookPath;
  final int bookId;
  final String bookTitle;
  final String? coverUrl;

  const ReaderScreen({
    super.key,
    required this.bookPath,
    required this.bookId,
    required this.bookTitle,
    this.coverUrl,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderProvider>().initialize(bookId: widget.bookId);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        final bgColor = _extractBgColor(provider.currentEpubTheme);

        return Scaffold(
          backgroundColor: bgColor,
          extendBody: true,

          // ── Top bar ────────────────────────────────────────────────────
          appBar: provider.showControls
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: ReaderTopBar(
                    title: widget.bookTitle,
                    onBack: () async {
                      await provider.saveAndClose();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    onChapters: () => _showChapters(context, provider),
                  ),
                )
              : null,

          // ── Bottom bar (pill design) ───────────────────────────────────
          bottomNavigationBar: AnimatedSlide(
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
                onSettings: () => _showSettings(context),
                onChapters: () => _showChapters(context, provider),
                onBookmark: () {},
                onShare: () {},
                onProgressChanged: (value) => provider.epubController.toProgressPercentage(value),
              ),
            ),
          ),

          body: Stack(
            children: [
              // ── EPUB Viewer ────────────────────────────────────────────
              _buildEpubViewer(provider),

              // ── Loading overlay ────────────────────────────────────────
              if (provider.isLoading) _LoadingOverlay(bgColor: bgColor),

              // ── Selection toolbar ──────────────────────────────────────
              if (provider.hasSelection)
                SelectionToolbar(
                  selectedText: provider.selectedText,
                  selectionRect: provider.selectionRect,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: provider.selectedText));
                    provider.clearSelection();
                    _showSnack(context, ReaderStrings.copiedMessage);
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
    return GestureDetector(
      onTap: provider.hasSelection ? provider.clearSelection : provider.toggleControls,
      child: EpubViewer(
        epubController: provider.epubController,
        epubSource: EpubSource.fromFile(File(widget.bookPath)),
        displaySettings: EpubDisplaySettings(
          flow: EpubFlow.paginated,
          snap: true,
          theme: provider.currentEpubTheme,
          fontSize: provider.fontSize,
        ),
        suppressNativeContextMenu: false,
        onEpubLoaded: provider.onEpubLoaded,
        onChaptersLoaded: provider.onChaptersLoaded,
        onRelocated: provider.onRelocated,
        onTextSelected: provider.onTextSelected,
        onSelection: provider.onSelection,
        onDeselection: provider.onDeselection,
        onTouchDown: (x, y) {},
        onTouchUp: (x, y) {},
      ),
    );
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
        child: const ChapterListSheet(),
      ),
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
