import '../strings_base.dart';

/// Strings for [BookDetailScreen] (§10) — header actions, stats, synopsis,
/// section headings, carousels and the sticky bottom CTA.
class BookDetailStrings {
  BookDetailStrings._();

  static String openError(Object error) => t(
        tk: 'Kitap açylmady: $error',
        ru: 'Не удалось открыть книгу: $error',
        tr: 'Kitap açılamadı: $error',
      );

  static String get finishedAdded => t(
        tk: 'Okap bitirenlerime goşuldy',
        ru: 'Добавлено в прочитанные',
        tr: 'Bitirdiklerime eklendi',
      );
  static String get finishedRemoved => t(
        tk: 'Okap bitirenlerimden aýryldy',
        ru: 'Удалено из прочитанных',
        tr: 'Bitirdiklerimden çıkarıldı',
      );
  static String get favoriteAdded => t(
        tk: 'Halananlara goşuldy',
        ru: 'Добавлено в избранное',
        tr: 'Favorilere eklendi',
      );
  static String get favoriteRemoved => t(
        tk: 'Halananlardan aýryldy',
        ru: 'Удалено из избранного',
        tr: 'Favorilerden çıkarıldı',
      );

  static String shareText(String title, String author) => t(
        tk: '«$title» — $author\nAýkitap-da oka!',
        ru: '«$title» — $author\nЧитайте на Aýkitap!',
        tr: '«$title» — $author\nAýkitap\'ta oku!',
      );

  static String get aboutBook => t(tk: 'Kitap barada', ru: 'О книге', tr: 'Kitap hakkında');
  static String get genres => t(tk: 'Žanrlar', ru: 'Жанры', tr: 'Türler');
  static String get similarBooks => t(tk: 'Meňzeş kitaplar', ru: 'Похожие книги', tr: 'Benzer kitaplar');
  static String get moreByAuthor => t(
        tk: 'Şu ýazaryň beýleki kitaplary',
        ru: 'Другие книги этого автора',
        tr: 'Bu yazarın diğer kitapları',
      );

  static String get statRead => t(tk: 'okaldy', ru: 'прочитано', tr: 'okundu');
  static String get statPurchased => t(tk: 'satyn alyndy', ru: 'куплено', tr: 'satın alındı');
  static String get statPages => t(tk: 'sahypa', ru: 'страниц', tr: 'sayfa');

  static String get showLess => t(tk: 'Az görkez', ru: 'Свернуть', tr: 'Daha az göster');
  static String get readFull => t(tk: 'Doly oka', ru: 'Читать полностью', tr: 'Tamamını oku');

  static String get read => t(tk: 'Oka', ru: 'Читать', tr: 'Oku');
  static String get price => t(tk: 'Baha', ru: 'Цена', tr: 'Fiyat');
  static String priceValue(int manat) => t(tk: '$manat manat', ru: '$manat манат', tr: '$manat manat');
  static String get buy => t(tk: 'Satyn al', ru: 'Купить', tr: 'Satın al');
}
