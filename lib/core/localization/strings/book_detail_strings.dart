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

  static String _shareGenres(List<String> genres) => t(
        tk: 'Žanr: ${genres.join(', ')}',
        ru: 'Жанр: ${genres.join(', ')}',
        tr: 'Tür: ${genres.join(', ')}',
      );
  static String _sharePages(int pages) => t(tk: '$pages sahypa', ru: '$pages страниц', tr: '$pages sayfa');
  static String get _shareCta => t(
        tk: '📲 Aýkitap-da oka!',
        ru: '📲 Читайте на Aýkitap!',
        tr: '📲 Aýkitap\'ta oku!',
      );

  static String shareText(
    String title,
    String author, {
    List<String> genres = const [],
    int? pages,
    String? synopsis,
  }) {
    final lines = <String>['📚 «$title» — $author'];
    final meta = <String>[
      if (genres.isNotEmpty) _shareGenres(genres),
      if (pages != null && pages > 0) _sharePages(pages),
    ];
    if (meta.isNotEmpty) lines.add(meta.join(' · '));
    if (synopsis != null && synopsis.trim().isNotEmpty) {
      final trimmed = synopsis.trim();
      lines.add(trimmed.length > 140 ? '${trimmed.substring(0, 140).trimRight()}…' : trimmed);
    }
    lines.add(_shareCta);
    return lines.join('\n\n');
  }

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

  // catalog_book_detail_screen.dart — the real `GET /books/:id` detail page.
  static String get catalogLoadError => t(tk: 'Kitap ýüklenmedi', ru: 'Не удалось загрузить книгу', tr: 'Kitap yüklenemedi');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');
  static String get year => t(tk: 'Ýyl', ru: 'Год', tr: 'Yıl');
  static String get ageRating => t(tk: 'Ýaş çägi', ru: 'Возрастной рейтинг', tr: 'Yaş sınırı');
  static String get readingNotAvailable => t(
        tk: 'Bu kitaby okamak entek elýeterli däl',
        ru: 'Чтение этой книги пока недоступно',
        tr: 'Bu kitabı okumak henüz mevcut değil',
      );
}
