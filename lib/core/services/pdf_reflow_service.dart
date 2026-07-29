import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../localization/strings/reader_strings.dart';
import '../utils/stable_hash.dart';

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
  Future<String?> reflowEpubPathFor({required String filePath, required String title}) async {
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

  Future<List<int>> _buildEpub(PdfDocument document, {required String title}) async {
    final pages = document.pages;
    final chapterCount = (pages.length / _pagesPerChapter).ceil().clamp(1, pages.length);

    final archive = Archive();
    final mimetype = utf8.encode('application/epub+zip');
    archive.addFile(ArchiveFile.noCompress('mimetype', mimetype.length, mimetype));
    archive.addFile(ArchiveFile.string('META-INF/container.xml', _containerXml));

    final manifestItems = StringBuffer();
    final spineItems = StringBuffer();
    final navItems = StringBuffer();

    for (var c = 0; c < chapterCount; c++) {
      final start = c * _pagesPerChapter;
      final end = ((c + 1) * _pagesPerChapter).clamp(0, pages.length);
      final body = StringBuffer();
      for (var i = start; i < end; i++) {
        final text = await pages[i].loadText();
        body.write(_paragraphsFor(text?.fullText ?? ''));
      }
      final id = 'chap${(c + 1).toString().padLeft(4, '0')}';
      archive.addFile(ArchiveFile.string('OEBPS/$id.xhtml', _chapterXhtml(body.toString())));
      manifestItems.writeln('<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>');
      spineItems.writeln('<itemref idref="$id"/>');
      navItems.writeln(
        '<li><a href="$id.xhtml">${_escapeXml('${ReaderStrings.pdfGoToPageShort} ${start + 1}–$end')}</a></li>',
      );
    }

    archive.addFile(ArchiveFile.string('OEBPS/nav.xhtml', _navXhtml(navItems.toString())));
    archive.addFile(
      ArchiveFile.string(
        'OEBPS/content.opf',
        _contentOpf(title: title, manifestItems: manifestItems.toString(), spineItems: spineItems.toString()),
      ),
    );

    return ZipEncoder().encodeBytes(archive);
  }

  /// Blank-line runs become paragraph breaks; single newlines (PDFium's
  /// per-visual-line breaks, not real paragraph breaks) are joined with a
  /// space. A page with no blank lines at all would otherwise extract as one
  /// giant block, so overly long blocks are additionally split at sentence
  /// boundaries — see [_splitLongBlock].
  String _paragraphsFor(String rawText) {
    final buffer = StringBuffer();
    for (final block in rawText.split(RegExp(r'\n\s*\n'))) {
      final joined = block.replaceAll('\n', ' ').trim();
      if (joined.isEmpty) continue;
      for (final paragraph in _splitLongBlock(joined)) {
        buffer.writeln('<p>${_escapeXml(paragraph)}</p>');
      }
    }
    return buffer.toString();
  }

  /// Real book paragraphs rarely run past a few sentences; a scanned PDF page
  /// with no blank lines extracts as one uninterrupted block that can span
  /// the entire page. Besides reading oddly once reflowed, a drag with no
  /// nearby paragraph boundary is easier for the WebView to mistake for a
  /// text-selection drag than a page-turn swipe — and once a selection gets
  /// stuck active, epub.js's own touch handler blocks every further swipe
  /// (see epubView.js's hasActiveSelection() gate). Splitting at sentence
  /// ends keeps generated paragraphs closer to a normal book's, which should
  /// make that far less likely, though it isn't a guaranteed fix on its own.
  static const _maxParagraphLength = 480;

  List<String> _splitLongBlock(String block) {
    if (block.length <= _maxParagraphLength) return [block];
    final sentences = block.split(RegExp(r'(?<=[.!?])\s+'));
    final paragraphs = <String>[];
    final current = StringBuffer();
    for (final sentence in sentences) {
      if (current.isNotEmpty && current.length + sentence.length + 1 > _maxParagraphLength) {
        paragraphs.add(current.toString().trim());
        current.clear();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(sentence);
    }
    if (current.isNotEmpty) paragraphs.add(current.toString().trim());
    return paragraphs.isEmpty ? [block] : paragraphs;
  }

  String _escapeXml(String s) =>
      _stripXmlIllegalChars(s).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// For the rare glyph code its ToUnicode map has no entry for, PDFium
  /// emits either a raw control character or U+FFFD (the "�" replacement
  /// character) — harmless in a rendered page (the glyph itself still draws
  /// fine from its embedded outline) but bad news once it lands in extracted
  /// text: control characters are mostly illegal XML content
  /// (https://www.w3.org/TR/xml/#charsets) and abort the whole chapter with
  /// "PCDATA invalid Char value", while U+FFFD is legal XML but reads as a
  /// glaring "?" stamped into the middle of a word. Both are dropped rather
  /// than mapped to anything — there's no correct replacement to guess for
  /// an unmapped glyph, and losing one stray character reads far better than
  /// losing the chapter or leaving visible junk in the sentence.
  static final _xmlIllegalChars = RegExp(
    '[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFD\uFFFE\uFFFF]',
  );

  String _stripXmlIllegalChars(String s) {
    final withoutControls = s.replaceAll(_xmlIllegalChars, '');
    // Guard against lone surrogates too (a mis-decoded glyph could produce
    // one): each UTF-16 code unit is checked and only high/low surrogates
    // that are correctly paired are kept.
    final buffer = StringBuffer();
    for (var i = 0; i < withoutControls.length; i++) {
      final unit = withoutControls.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        final next = i + 1 < withoutControls.length ? withoutControls.codeUnitAt(i + 1) : 0;
        if (next >= 0xDC00 && next <= 0xDFFF) {
          buffer.writeCharCode(unit);
          buffer.writeCharCode(next);
          i++;
        }
        continue;
      }
      if (unit >= 0xDC00 && unit <= 0xDFFF) continue;
      buffer.writeCharCode(unit);
    }
    return buffer.toString();
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

  static const _containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

  String _chapterXhtml(String body) => '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter</title></head>
<body>
$body
</body>
</html>
''';

  String _navXhtml(String items) => '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Nav</title></head>
<body>
  <nav epub:type="toc" id="toc">
    <ol>
$items
    </ol>
  </nav>
</body>
</html>
''';

  String _contentOpf({required String title, required String manifestItems, required String spineItems}) =>
      '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">pdf-reflow-${stableBookKey(title)}</dc:identifier>
    <dc:title>${_escapeXml(title)}</dc:title>
    <dc:language>tk</dc:language>
    <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
$manifestItems
  </manifest>
  <spine>
$spineItems
  </spine>
</package>
''';
}
