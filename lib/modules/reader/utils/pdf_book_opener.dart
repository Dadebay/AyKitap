import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/pdf_reflow_service.dart';
import '../provider/reader_provider.dart';
import '../views/pdf_reader_screen.dart';
import '../views/reader_view.dart';

/// Per-book override, set from the reader's own settings sheet, for a reader
/// who switched a text PDF to fixed page images (or back). Read here on
/// every open so the choice sticks without re-asking each time the book is
/// opened.
String preferFixedPrefKey(int bookId) => 'book_${bookId}_pdf_prefer_fixed';

/// Opens a PDF in whichever reader fits it: a text-layer PDF is converted
/// once (cached after) into a synthetic EPUB and opened in the same
/// reflowable [ReaderScreen] real EPUBs use — background/font/theme, notes,
/// bookmarks and search all apply. A scanned/image-only PDF has no text to
/// reflow and opens in the fixed-page [PdfReaderScreen] exactly as before.
///
/// The same [bookId] is passed through either way, so bookmarks/notes (keyed
/// by bare bookId) carry over regardless of which reader ends up handling it.
Future<void> openPdfBook(
  BuildContext context, {
  required String filePath,
  required String title,
  required int bookId,
}) {
  return context.push(_PdfOpeningScreen(filePath: filePath, title: title, bookId: bookId));
}

/// A brief hand-off screen pushed while the PDF is classified (and, on first
/// open only, converted) — then immediately replaced with whichever reader
/// the result calls for.
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
class _PdfOpeningScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final int bookId;

  const _PdfOpeningScreen({required this.filePath, required this.title, required this.bookId});

  @override
  State<_PdfOpeningScreen> createState() => _PdfOpeningScreenState();
}

class _PdfOpeningScreenState extends State<_PdfOpeningScreen> {
  static const _bgColor = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final prefs = await SharedPreferences.getInstance();
    final preferFixed = prefs.getBool(preferFixedPrefKey(widget.bookId)) ?? false;
    String? epubPath;
    if (!preferFixed) {
      try {
        epubPath = await PdfReflowService.instance.reflowEpubPathFor(filePath: widget.filePath, title: widget.title);
      } catch (_) {
        epubPath = null;
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
