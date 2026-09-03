import 'package:aykitap/modules/reader/utils/pdf_book_opener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fixed PDF opening defaults', () {
    test('an unclassified PDF uses image-safe defaults', () {
      expect(imageSafePdfDefaultsFor(null), isTrue);
    });

    test('a cached image-only verdict uses image-safe defaults', () {
      expect(imageSafePdfDefaultsFor(true), isTrue);
    });

    test('a cached text verdict keeps text-PDF defaults', () {
      expect(imageSafePdfDefaultsFor(false), isFalse);
    });
  });
}
