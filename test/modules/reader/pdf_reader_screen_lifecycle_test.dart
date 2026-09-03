import 'package:aykitap/modules/reader/views/pdf_reader_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initial PDF margin crop', () {
    test('unconfigured image PDF fills the width', () {
      expect(
        initialPdfMarginCropFor(
          imageOnly: true,
          readerCrop: 0.0,
        ),
        1.0,
      );
    });

    test('per-book image PDF choice is preserved', () {
      expect(
        initialPdfMarginCropFor(
          imageOnly: true,
          bookCrop: 0.35,
          readerCrop: 0.8,
        ),
        0.35,
      );
    });

    test('text PDF keeps the app-wide choice', () {
      expect(
        initialPdfMarginCropFor(
          imageOnly: false,
          readerCrop: 0.4,
        ),
        0.4,
      );
    });
  });
}
