import 'package:aykitap/core/services/book_access_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing or invalid price never grants access to an unowned book', () {
    expect(
      accessForUnownedBook(price: null, balance: 100),
      BookAccess.priceUnavailable,
    );
    expect(
      accessForUnownedBook(price: -1, balance: 100),
      BookAccess.priceUnavailable,
    );
  });

  test('an explicit zero price is still free', () {
    expect(
      accessForUnownedBook(price: 0, balance: null),
      BookAccess.purchased,
    );
  });
}
