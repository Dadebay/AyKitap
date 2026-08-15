import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/pdf_reflow_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../provider/reader_provider.dart';
import '../views/pdf_reader_screen.dart';
import '../views/reader_view.dart';

/// Per-book override, set from the reader's own settings sheet, for a reader
/// who switched a PDF between fixed page images and reflowed text. Read here
/// on every open so the choice sticks without re-asking each time the book
/// is opened. Absent (neither ever chosen) defaults to fixed — see
/// [openPdfBook].
String preferFixedPrefKey(int bookId) => 'book_${bookId}_pdf_prefer_fixed';

/// Opens a PDF straight into the fixed-page [PdfReaderScreen] — the actual
/// PDF pages, exactly as the source file looks — by default, same as a
/// scanned/image-only PDF always has to. A reflowed, reader-styled text
/// view is available (background/font/theme, notes, bookmarks and search
/// all apply, the same as a real EPUB) but is opt-in from there via
/// "Tekst görnüşi" ([PdfReaderScreen._switchToTextView]) rather than
/// automatic, so nobody's book silently opens differently than the file
/// they downloaded.
///
/// The same [bookId] is passed through either way, so bookmarks/notes (keyed
/// by bare bookId) carry over regardless of which reader ends up handling it.
Future<void> openPdfBook(
  BuildContext context, {
  required String filePath,
  required String title,
  required int bookId,
}) {
  return context.push(PdfOpeningScreen(filePath: filePath, title: title, bookId: bookId));
}

/// A brief hand-off screen pushed while the PDF is classified (and, on first
/// open only, converted) — then immediately replaced with whichever reader
/// the result calls for.
///
/// Every path into the reflow conversion goes through here, including the
/// "Tekst görnüşi" switch from inside [PdfReaderScreen] (which pushes this
/// as a replacement rather than converting in place). That is deliberate:
/// the conversion drives pdfrx's PDFium over the whole document, and doing
/// that while a live [PDFView] holds the same file open in
/// flutter_pdfview's *own* PDFium — two engines, one file, one of them
/// rendering — took the whole app down on a large book. Converting only
/// from here means no PDF view is ever alive at the time.
///
/// This deliberately does *not* reuse [BookOpeningOverlay]'s ramped 0→100%
/// animation: that overlay holds for a multi-second minimum by design (see
/// its own doc comment) so the "kitap açylýar" moment reads as genuine
/// progress. Classifying a PDF is normally a single cache-file check —
/// instant — with real multi-second work (epub.js parsing, PDFium
/// rendering) still ahead in whichever reader we're about to hand off to.
/// Giving this step the same ramped overlay meant every PDF open flashed
/// two full "book opening" animations back to back, each enforcing its own
/// multi-second hold, so the very first open of *any* PDF took twice as
/// long as it needed to and visibly restarted partway through. A bare,
/// non-timed loading animation here — gone the instant [_resolve] actually
/// finishes — leaves exactly one ramped overlay (the next screen's own) for
/// the reader to see.
class PdfOpeningScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final int bookId;

  const PdfOpeningScreen({required this.filePath, required this.title, required this.bookId});

  @override
  State<PdfOpeningScreen> createState() => PdfOpeningScreenState();
}

class PdfOpeningScreenState extends State<PdfOpeningScreen> {
  static const _bgColor = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final prefs = await SharedPreferences.getInstance();
    // Fixed (the actual PDF pages) unless the reader has explicitly asked
    // for the reflowed text view before — no auto-reflow on a first open,
    // so a downloaded PDF always opens looking like the file it is.
    final preferFixed = prefs.getBool(preferFixedPrefKey(widget.bookId)) ?? true;
    String? epubPath;
    if (!preferFixed) {
      try {
        epubPath = await PdfReflowService.instance.reflowEpubPathFor(filePath: widget.filePath, title: widget.title);
      } catch (_) {
        epubPath = null;
      }
      // Asked for text and there is none to give — a scanned/image-only
      // book. Drop the preference back to fixed so the next open doesn't
      // retry a conversion that can't succeed, and say why rather than
      // silently landing back on the same fixed pages the switch was
      // supposed to leave.
      if (epubPath == null) {
        await prefs.setBool(preferFixedPrefKey(widget.bookId), true);
        if (!mounted) return;
        context.showAppSnackBar(ReaderStrings.pdfTextViewUnavailable, isError: true);
      }
    }
    if (!mounted) return;
    _proceed(epubPath);
  }

  void _proceed(String? epubPath) {
    final replacement = epubPath != null
        ? ChangeNotifierProvider(
            create: (_) => ReaderProvider(),
            child: ReaderScreen(
              bookPath: epubPath,
              bookId: widget.bookId,
              bookTitle: widget.title,
              originalPdfPath: widget.filePath,
            ),
          )
        : PdfReaderScreen(filePath: widget.filePath, title: widget.title, bookId: widget.bookId);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => replacement));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Lottie.asset('assets/animations/book_reading_boy.json', repeat: true, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
