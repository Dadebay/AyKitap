import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../localization/strings/reader_pdf_strings.dart';
import '../utils/stable_hash.dart';

part 'pdf_reflow_epub_builder.dart';
part 'pdf_reflow_epub_templates.dart';

/// Detects whether a PDF has a real text layer (as opposed to being a
/// scanned/image-only book) and, if so, converts it once into a minimal
/// synthetic EPUB so it can be opened through the same reflowable reader
/// pipeline as real EPUBs — background/font/theme, bookmarks, notes and
/// search all come along for free that way, rather than building a second
/// reflow renderer from scratch.
///
/// Image-based PDFs (scanned books, manga, etc.) have nothing to extract and
/// keep opening in the fixed-page PdfReaderScreen exactly as before.
class PdfReflowService {
  PdfReflowService._();
  static final instance = PdfReflowService._();

  /// Below this average character count per sampled page, a PDF is treated
  /// as image-based rather than real text — well above what a stray caption
  /// or page number would produce, comfortably below a real body-text page.
  static const _textPageThreshold = 60;

  /// Pages sampled (spread across the document) to make that call cheaply,
  /// without extracting the whole book just to classify it.
  static const _sampleSize = 8;

  /// PDF pages bundled per generated EPUB "chapter" file — keeps the spine
  /// and chapter list reasonable for a 200-300 page scan instead of one
  /// XHTML file per page.
  static const _pagesPerChapter = 15;

  /// Returns the path to a generated EPUB if [filePath] has a real text
  /// layer (converting and caching it on first call), or null if it's
  /// image-based — callers fall back to the fixed-page PDF viewer in that
  /// case. Never throws: any failure while reading or converting the PDF is
  /// treated the same as "image-based" so a bad/unusual file never blocks
  /// the reader from opening.
  Future<String?> reflowEpubPathFor(
      {required String filePath, required String title}) async {
    try {
      final dir = await _cacheDirFor(filePath);
      final epubFile = File('${dir.path}/reflow.epub');
      if (await epubFile.exists()) return epubFile.path;
      final markerFile = File('${dir.path}/is_image.marker');
      if (await markerFile.exists()) return null;

      final document = await PdfDocument.openFile(filePath);
      try {
        if (!await _looksLikeTextPdf(document)) {
          await dir.create(recursive: true);
          await markerFile.create();
          return null;
        }
        final bytes = await _buildEpub(document, title: title);
        await dir.create(recursive: true);
        await epubFile.writeAsBytes(bytes, flush: true);
        return epubFile.path;
      } finally {
        await document.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  /// Returns the already-generated reflow EPUB for [filePath] without
  /// running (or re-running) any conversion — null if this PDF was never
  /// converted (including image-only PDFs, which never get one). Used to
  /// offer "switch back to text view" from the fixed-page reader without
  /// paying for a fresh classify-and-convert pass.
  Future<String?> cachedReflowEpubPath(String filePath) async {
    try {
      final dir = await _cacheDirFor(filePath);
      final epubFile = File('${dir.path}/reflow.epub');
      if (await epubFile.exists()) return epubFile.path;
    } catch (_) {}
    return null;
  }

  /// Returns a classification that was already persisted by a previous,
  /// explicit reflow attempt without opening the PDF in PDFium.
  ///
  /// `true` means the image-only marker exists, `false` means a generated
  /// reflow EPUB proves the PDF had text, and `null` means this book has never
  /// been classified. Fixed-page opening uses this cache-only lookup because
  /// probing an unknown PDF here and then opening [PdfViewer] immediately
  /// afterwards creates two sequential native PDFium allocations. Image-heavy
  /// books can exhaust a budget Android process during the first allocation
  /// before Dart gets a catchable exception.
  Future<bool?> cachedImageOnlyVerdict(String filePath) async {
    try {
      final dir = await _cacheDirFor(filePath);
      if (await File('${dir.path}/reflow.epub').exists()) return false;
      if (await File('${dir.path}/is_image.marker').exists()) return true;
    } catch (_) {}
    return null;
  }

  /// Whether [filePath] is an image book — a scan, a manga, a comic — rather
  /// than one with a real text layer. This is the same test
  /// [reflowEpubPathFor] uses to decide there is nothing to reflow, exposed on
  /// its own because the *fixed-page* reader wants it too: a page that is one
  /// big picture needs a layout chosen for pictures (fill the width and scroll
  /// down it) rather than the whole page shrunk to fit the screen's height,
  /// which turns a tall manga page into an unreadable sliver.
  ///
  /// Shares [reflowEpubPathFor]'s on-disk verdict cache, so the PDFium pass
  /// runs at most once per book — afterwards this is a file-exists check, and
  /// a later reflow attempt reads the same marker instead of re-sampling.
  ///
  /// Returns false if the file can't be read at all: an unreadable PDF
  /// shouldn't have a layout picked for it on the strength of a guess.
  Future<bool> isImageOnlyPdf({required String filePath}) async {
    try {
      final dir = await _cacheDirFor(filePath);
      // A generated EPUB is proof it had text; the marker is proof it didn't.
      if (await File('${dir.path}/reflow.epub').exists()) return false;
      final markerFile = File('${dir.path}/is_image.marker');
      if (await markerFile.exists()) return true;

      final document = await PdfDocument.openFile(filePath);
      try {
        if (await _looksLikeTextPdf(document)) return false;
        await dir.create(recursive: true);
        await markerFile.create();
        return true;
      } finally {
        await document.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  /// Deletes [filePath]'s reflow cache (the generated EPUB or the "it's an
  /// image PDF" marker), if any. Safe to call for a book that was never
  /// opened or isn't a PDF at all.
  Future<void> deleteCacheFor(String filePath) async {
    try {
      final dir = await _cacheDirFor(filePath);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<bool> _looksLikeTextPdf(PdfDocument document) async {
    final pages = document.pages;
    if (pages.isEmpty) return false;
    final step = (pages.length / _sampleSize).ceil().clamp(1, pages.length);
    var total = 0;
    var sampled = 0;
    for (var i = 0; i < pages.length; i += step) {
      final text = await pages[i].loadText();
      total += text?.fullText.trim().length ?? 0;
      sampled++;
    }
    return sampled > 0 && (total / sampled) >= _textPageThreshold;
  }

  Future<Directory> _cacheDirFor(String filePath) async {
    final dir = await getApplicationSupportDirectory();
    final key = stableBookKey(filePath).toRadixString(16);
    // v3: v2 fixed XML-illegal characters slipping into generated chapters
    // (_stripXmlIllegalChars); v3 additionally splits overly long paragraphs
    // at sentence ends (_splitLongBlock). v4: _stripXmlIllegalChars now also
    // drops U+FFFD, PDFium's "�" stand-in for a glyph its ToUnicode map
    // can't resolve — legal XML, so v3 left it sitting visibly in the middle
    // of words. Bumping forces any epub cached by an older converter to
    // regenerate instead of keeping the stale file.
    return Directory('${dir.path}/pdf_reflow/v4/$key');
  }
}
