part of 'pdf_reflow_service.dart';

/// [PdfReflowService]'s EPUB-building half — text extraction, paragraph
/// splitting, and XML escaping. The XHTML/OPF templates live in
/// `pdf_reflow_epub_templates.dart` and the detection/cache half
/// ([PdfReflowService.reflowEpubPathFor] and friends) stays in the main
/// file — both split out to keep every file under the 200-line limit.
extension _PdfEpubBuilder on PdfReflowService {
  Future<List<int>> _buildEpub(PdfDocument document,
      {required String title}) async {
    final pages = document.pages;
    final chapterCount = (pages.length / PdfReflowService._pagesPerChapter)
        .ceil()
        .clamp(1, pages.length);

    final archive = Archive();
    final mimetype = utf8.encode('application/epub+zip');
    archive
        .addFile(ArchiveFile.noCompress('mimetype', mimetype.length, mimetype));
    archive
        .addFile(ArchiveFile.string('META-INF/container.xml', _containerXml));

    final manifestItems = StringBuffer();
    final spineItems = StringBuffer();
    final navItems = StringBuffer();

    for (var c = 0; c < chapterCount; c++) {
      final start = c * PdfReflowService._pagesPerChapter;
      final end =
          ((c + 1) * PdfReflowService._pagesPerChapter).clamp(0, pages.length);
      final body = StringBuffer();
      for (var i = start; i < end; i++) {
        final text = await pages[i].loadText();
        body.write(_paragraphsFor(text?.fullText ?? ''));
      }
      final id = 'chap${(c + 1).toString().padLeft(4, '0')}';
      archive.addFile(ArchiveFile.string(
          'OEBPS/$id.xhtml', _chapterXhtml(body.toString())));
      manifestItems.writeln(
          '<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>');
      spineItems.writeln('<itemref idref="$id"/>');
      navItems.writeln(
        '<li><a href="$id.xhtml">${_escapeXml('${ReaderStrings.pdfGoToPageShort} ${start + 1}–$end')}</a></li>',
      );
    }

    archive.addFile(
        ArchiveFile.string('OEBPS/nav.xhtml', _navXhtml(navItems.toString())));
    archive.addFile(
      ArchiveFile.string(
        'OEBPS/content.opf',
        _contentOpf(
            title: title,
            manifestItems: manifestItems.toString(),
            spineItems: spineItems.toString()),
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

  List<String> _splitLongBlock(String block) {
    if (block.length <= _maxParagraphLength) return [block];
    final sentences = block.split(RegExp(r'(?<=[.!?])\s+'));
    final paragraphs = <String>[];
    final current = StringBuffer();
    for (final sentence in sentences) {
      if (current.isNotEmpty &&
          current.length + sentence.length + 1 > _maxParagraphLength) {
        paragraphs.add(current.toString().trim());
        current.clear();
      }
      if (current.isNotEmpty) current.write(' ');
      current.write(sentence);
    }
    if (current.isNotEmpty) paragraphs.add(current.toString().trim());
    return paragraphs.isEmpty ? [block] : paragraphs;
  }

  String _escapeXml(String s) => _stripXmlIllegalChars(s)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _stripXmlIllegalChars(String s) {
    final withoutControls = s.replaceAll(_xmlIllegalChars, '');
    // Guard against lone surrogates too (a mis-decoded glyph could produce
    // one): each UTF-16 code unit is checked and only high/low surrogates
    // that are correctly paired are kept.
    final buffer = StringBuffer();
    for (var i = 0; i < withoutControls.length; i++) {
      final unit = withoutControls.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        final next = i + 1 < withoutControls.length
            ? withoutControls.codeUnitAt(i + 1)
            : 0;
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
const _maxParagraphLength = 480;

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
final _xmlIllegalChars = RegExp(
  '[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFD\uFFFE\uFFFF]',
);
