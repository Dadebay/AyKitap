part of 'pdf_reflow_service.dart';

/// [PdfReflowService]'s EPUB XHTML/OPF templates — split out of
/// `pdf_reflow_epub_builder.dart` to keep both files under the 200-line
/// limit.
extension _PdfEpubTemplates on PdfReflowService {
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

  String _contentOpf(
          {required String title,
          required String manifestItems,
          required String spineItems}) =>
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

const _containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';
