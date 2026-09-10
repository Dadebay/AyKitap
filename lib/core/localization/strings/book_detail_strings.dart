import '../strings_base.dart';

/// Strings for [BookDetailScreen] (§10) — header actions, stats, synopsis,
/// section headings, carousels and the sticky bottom CTA.
class BookDetailStrings {
  BookDetailStrings._();

  static String openError(Object error) => t(
        tk: 'Kitap açylmady: $error',
        ru: 'Не удалось открыть книгу: $error',
        tr: 'Kitap açılamadı: $error',
        en: 'Couldn\'t open the book: $error',
      );

  static String get finishedAdded => t(
        tk: 'Okap bitirenlerime goşuldy',
        ru: 'Добавлено в прочитанные',
        tr: 'Bitirdiklerime eklendi',
        en: 'Added to finished',
      );
  static String get finishedRemoved => t(
        tk: 'Okap bitirenlerimden aýryldy',
        ru: 'Удалено из прочитанных',
        tr: 'Bitirdiklerimden çıkarıldı',
        en: 'Removed from finished',
      );
  static String get favoriteAdded => t(
        tk: 'Halananlara goşuldy',
        ru: 'Добавлено в избранное',
        tr: 'Favorilere eklendi',
        en: 'Added to favorites',
      );
  static String get favoriteRemoved => t(
        tk: 'Halananlardan aýryldy',
        ru: 'Удалено из избранного',
        tr: 'Favorilerden çıkarıldı',
        en: 'Removed from favorites',
      );

  static String _shareGenres(List<String> genres) => t(
        tk: 'Žanr: ${genres.join(', ')}',
        ru: 'Жанр: ${genres.join(', ')}',
        tr: 'Tür: ${genres.join(', ')}',
        en: 'Genre: ${genres.join(', ')}',
      );
  static String _sharePages(int pages) => t(
      tk: '$pages sahypa',
      ru: '$pages страниц',
      tr: '$pages sayfa',
      en: '$pages pages');
  static String get _shareCta => t(
        tk: '📲 Aýkitap-da oka!',
        ru: '📲 Читайте на Aýkitap!',
        tr: '📲 Aýkitap\'ta oku!',
        en: '📲 Read it on Aýkitap!',
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
      lines.add(trimmed.length > 140
          ? '${trimmed.substring(0, 140).trimRight()}…'
          : trimmed);
    }
    lines.add(_shareCta);
    return lines.join('\n\n');
  }

  static String get aboutBook => t(
      tk: 'Kitap barada',
      ru: 'О книге',
      tr: 'Kitap hakkında',
      en: 'About the book');
  static String get genres =>
      t(tk: 'Žanrlar', ru: 'Жанры', tr: 'Türler', en: 'Genres');
  static String get noBooksInGenre => t(
      tk: 'Bu žanrda entek kitap ýok',
      ru: 'В этом жанре пока нет книг',
      tr: 'Bu türde henüz kitap yok',
      en: 'No books in this genre yet');
  static String get similarBooks => t(
      tk: 'Meňzeş kitaplar',
      ru: 'Похожие книги',
      tr: 'Benzer kitaplar',
      en: 'Similar books');
  static String get moreByAuthor => t(
        tk: 'Awtoryň beýleki kitaplary',
        ru: 'Другие книги этого автора',
        tr: 'Bu yazarın diğer kitapları',
        en: 'More by this author',
      );

  static String get statRead =>
      t(tk: 'okaldy', ru: 'прочитано', tr: 'okundu', en: 'read');
  static String get statPurchased =>
      t(tk: 'satyn alyndy', ru: 'куплено', tr: 'satın alındı', en: 'purchased');
  static String get statPages =>
      t(tk: 'sahypa', ru: 'страниц', tr: 'sayfa', en: 'pages');

  static String get showLess =>
      t(tk: 'Az görkez', ru: 'Свернуть', tr: 'Daha az göster', en: 'Show less');
  static String get readFull => t(
      tk: 'Doly oka',
      ru: 'Читать полностью',
      tr: 'Tamamını oku',
      en: 'Read full text');

  static String get read => t(tk: 'Oka', ru: 'Читать', tr: 'Oku', en: 'Read');
  static String get price =>
      t(tk: 'Baha', ru: 'Цена', tr: 'Fiyat', en: 'Price');
  static String priceValue(int manat) => '$manat TMT';
  static String get buy =>
      t(tk: 'Satyn al', ru: 'Купить', tr: 'Satın al', en: 'Buy');

  // catalog_book_detail_screen.dart — the real `GET /books/:id` detail page.
  static String get catalogLoadError => t(
      tk: 'Kitap ýüklenmedi',
      ru: 'Не удалось загрузить книгу',
      tr: 'Kitap yüklenemedi',
      en: 'Book couldn\'t load');
  static String get retry => t(
      tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');
  static String get year => t(tk: 'Ýyl', ru: 'Год', tr: 'Yıl', en: 'Year');
  static String get ageRating => t(
      tk: 'Ýaş çägi',
      ru: 'Возрастной рейтинг',
      tr: 'Yaş sınırı',
      en: 'Age rating');
  static String get readingNotAvailable => t(
        tk: 'Bu kitaby okamak entek elýeterli däl',
        ru: 'Чтение этой книги пока недоступно',
        tr: 'Bu kitabı okumak henüz mevcut değil',
        en: 'Reading this book isn\'t available yet',
      );

  // Oku / Satyn al flow — CTA row, download progress, access gate.
  static String get downloading => t(
      tk: 'Ýüklenýär…',
      ru: 'Загрузка…',
      tr: 'İndiriliyor…',
      en: 'Downloading…');
  static String get downloadFailed => t(
        tk: 'Kitap ýüklenmedi',
        ru: 'Не удалось загрузить книгу',
        tr: 'Kitap indirilemedi',
        en: 'Book couldn\'t download',
      );
  static String get noFileForBook => t(
        tk: 'Bu kitabyň okalýan faýly ýok',
        ru: 'У этой книги нет файла для чтения',
        tr: 'Bu kitabın okunabilir dosyası yok',
        en: 'This book has no readable file',
      );
  static String get purchasedBadge =>
      t(tk: 'Satyn alnan', ru: 'Куплено', tr: 'Satın alındı', en: 'Purchased');
  static String get subscriptionExpiredForBook => t(
        tk: 'Abunalygyňyz gutardy — bu kitaby okamak üçin satyn alyň ýa-da abunalygy täzeläň',
        ru: 'Подписка закончилась — купите эту книгу или продлите подписку',
        tr: 'Aboneliğiniz bitti — bu kitabı okumak için satın alın ya da aboneliği yenileyin',
        en: 'Your subscription has ended — buy this book or renew your subscription to read it',
      );
  static String get loginRequired => t(
        tk: 'Dowam etmek üçin hasabyňyza giriň',
        ru: 'Войдите в аккаунт, чтобы продолжить',
        tr: 'Devam etmek için hesabınıza giriş yapın',
        en: 'Sign in to your account to continue',
      );
  static String get deleteDownload => t(
        tk: 'Ýüklemäni poz',
        ru: 'Удалить загрузку',
        tr: 'İndirmeyi sil',
        en: 'Delete download',
      );
  static String deleteDownloadConfirm(String title) => t(
        tk: '“$title” telefonyňyzdan pozulsynmy? Kitap kitaphanaňyzda galýar.',
        ru: 'Удалить «$title» с устройства? Книга останется в вашей библиотеке.',
        tr: '“$title” telefonunuzdan silinsin mi? Kitap kitaplığınızda kalır.',
        en: 'Delete “$title” from your device? The book stays in your library.',
      );
  static String get downloadDeleted => t(
        tk: 'Ýükleme pozuldy',
        ru: 'Загрузка удалена',
        tr: 'İndirme silindi',
        en: 'Download deleted',
      );
  static String get saveToFiles => t(
        tk: 'Faýllara ýaz',
        ru: 'Сохранить в Файлы',
        tr: 'Dosyalara kaydet',
        en: 'Save to Files',
      );
  static String get savePurchasedTitle => t(
      tk: 'Kitaby nirede saklamaly?',
      ru: 'Где сохранить книгу?',
      tr: 'Kitap nereye kaydedilsin?',
      en: 'Where should the book be saved?');
  static String get savePurchasedBody => t(
      tk: 'Kitaby oflaýn okamak üçin programmaňyzda saklaýarys. Şeýle hem öz faýl ýeriňize ýazyp bilersiňiz.',
      ru: 'Книга уже сохранена в приложении для офлайн-чтения. Также можно сохранить копию в выбранном месте.',
      tr: 'Kitap çevrimdışı okuma için uygulamada saklanır. İsterseniz seçtiğiniz konuma bir kopyasını da kaydedebilirsiniz.',
      en: 'We keep the book in the app for offline reading. You can also save a copy to a location of your choice.');
  static String get keepInApp => t(
      tk: 'Diňe programmada sakla',
      ru: 'Только в приложении',
      tr: 'Yalnızca uygulamada tut',
      en: 'Keep in app only');
  static String get chooseSaveLocation => t(
      tk: 'Ýer saýla',
      ru: 'Выбрать место',
      tr: 'Konum seç',
      en: 'Choose location');
  static String saveToFilesError(Object error) => t(
        tk: 'Faýl paýlaşylmady: $error',
        ru: 'Не удалось поделиться файлом: $error',
        tr: 'Dosya paylaşılamadı: $error',
        en: 'Couldn\'t share the file: $error',
      );

  static String get removeFromPurchased => t(
        tk: 'Satyn alnanlardan aýyr',
        ru: 'Удалить из купленных',
        tr: 'Satın alınanlardan kaldır',
        en: 'Remove from purchased',
      );
  static String removePurchasedConfirm(String title) => t(
        tk: '“$title” satyn alnan kitaphanaňyzdan aýrylsynmy?',
        ru: 'Удалить «$title» из купленных книг?',
        tr: '“$title” satın alınan kitaplarınızdan kaldırılsın mı?',
        en: 'Remove “$title” from your purchased books?',
      );
  static String get cancel =>
      t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç', en: 'Cancel');
  static String get remove =>
      t(tk: 'Aýyr', ru: 'Удалить', tr: 'Kaldır', en: 'Remove');
  static String removedFromPurchased(String title) => t(
        tk: '“$title” satyn alnanlardan aýryldy',
        ru: '«$title» удалена из купленных',
        tr: '“$title” satın alınanlardan kaldırıldı',
        en: '“$title” removed from purchased',
      );
}
