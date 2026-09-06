import '../strings_base.dart';

/// Strings for [LibraryScreen] and [OfflineLibraryScreen].
class LibraryStrings {
  LibraryStrings._();

  // Library screen — title & tabs.
  static String get libraryTitle => t(tk: 'Kitap Tekjäm', ru: 'Моя библиотека', tr: 'Kitaplığım', en: 'My Bookshelf');
  static String get tabReading => t(tk: 'Okaýanlarym', ru: 'Читаю', tr: 'Okuduklarım', en: 'Reading');
  static String get tabFinished => t(tk: 'Okap gutaranlarym', ru: 'Прочитанные', tr: 'Bitirdiklerim', en: 'Finished');
  static String get tabDownloaded => t(tk: 'Ýüklenenler', ru: 'Загруженные', tr: 'İndirilenler', en: 'Downloaded');
  static String get tabPurchased => t(tk: 'Satyn alynanlar', ru: 'Купленные', tr: 'Satın Alınanlar', en: 'Purchased');
  static String get tabFavorites => t(tk: 'Halanlarym', ru: 'Избранные', tr: 'Favorilerim', en: 'Favorites');
  static String get tabOwnBooks => t(tk: 'Öz Kitaplarym', ru: 'Мои книги', tr: 'Kendi Kitaplarım', en: 'My Own Books');

  // Empty states.
  static String get emptyPurchased => t(tk: 'Aýratyn satyn alnan kitap ýok', ru: 'Нет отдельно купленных книг', tr: 'Ayrıca satın alınmış kitap yok', en: 'No separately purchased books');
  static String get emptyFavorites => t(tk: 'Halanan kitap ýok', ru: 'Нет избранных книг', tr: 'Favori kitap yok', en: 'No favorite books');
  static String get emptyReading => t(tk: 'Häzir okalýan kitap ýok', ru: 'Сейчас нет читаемых книг', tr: 'Şu anda okunan kitap yok', en: 'No books being read right now');
  static String get emptyFinished => t(tk: 'Okap gutaran kitap ýok', ru: 'Нет прочитанных книг', tr: 'Henüz bitirdiğin kitap yok', en: 'No finished books yet');
  static String get emptyDownloaded => t(tk: 'Ýüklenen kitap ýok', ru: 'Нет загруженных книг', tr: 'İndirilen kitap yok', en: 'No downloaded books');
  static String get emptyDownloadedSub =>
      t(tk: 'Oflaýn okamak üçin kitap ýükläň', ru: 'Загрузите книгу для чтения офлайн', tr: 'Çevrimdışı okumak için kitap indirin', en: 'Download a book to read offline');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');
  static String get loginRequiredTitle =>
      t(tk: 'Kitaphanaňyzy görmek üçin hasabyňyza giriň', ru: 'Войдите в аккаунт, чтобы увидеть свою библиотеку', tr: 'Kitaplığınızı görmek için giriş yapın', en: 'Sign in to see your bookshelf');
  static String get loginRequiredSub => t(
      tk: 'Kitap goşmak we okamak üçin ilki giriş etmeli',
      ru: 'Чтобы добавлять и читать книги, сначала войдите в аккаунт',
      tr: 'Kitap eklemek ve okumak için önce giriş yapmalısınız',
      en: 'Sign in first to add and read books');
  static String get offlineBookUnavailable =>
      t(tk: 'Bu kitap enjamyňyza ýüklenmändir', ru: 'Эта книга не загружена на устройство', tr: 'Bu kitap cihazınıza indirilmemiş', en: 'This book hasn\'t been downloaded to your device');

  // Long-press delete, shared by every shelf (see [ShelfRemoval]). Each
  // shelf spells out what it actually removes, because "poz" means
  // something different on each one — progress, a purchase, a like, or the
  // imported file itself.
  static String get deleteTitle => t(tk: 'Tekjeden poz', ru: 'Удалить с полки', tr: 'Raftan sil', en: 'Remove from shelf');
  static String get delete => t(tk: 'Poz', ru: 'Удалить', tr: 'Sil', en: 'Remove');
  static String deleteReadingConfirm(String title) => t(
      tk: '«$title» okaýanlarymdan aýrylar we okaýyş göterimi ýitiriler. Kitabyň özi pozulmaýar.',
      ru: '«$title» исчезнет из «Читаю», прогресс чтения будет сброшен. Сама книга не удаляется.',
      tr: '«$title» okuduklarımdan kalkar ve okuma ilerlemesi sıfırlanır. Kitabın kendisi silinmez.',
      en: '“$title” will leave Reading and its reading progress will be lost. The book itself isn\'t deleted.');
  static String deleteFinishedConfirm(String title) => t(
      tk: '«$title» okap gutaranlarymdan aýrylar we okaýyş göterimi ýitiriler. Kitabyň özi pozulmaýar.',
      ru: '«$title» исчезнет из «Прочитанные», прогресс чтения будет сброшен. Сама книга не удаляется.',
      tr: '«$title» bitirdiklerimden kalkar ve okuma ilerlemesi sıfırlanır. Kitabın kendisi silinmez.',
      en: '“$title” will leave Finished and its reading progress will be lost. The book itself isn\'t deleted.');
  static String deletePurchasedConfirm(String title) => t(
      tk: '«$title» satyn alnanlardan aýrylar. Ony täzeden okamak üçin gaýtadan satyn almaly bolarsyňyz.',
      ru: '«$title» исчезнет из купленных. Чтобы снова её читать, придётся купить её заново.',
      tr: '«$title» satın alınanlardan kalkar. Tekrar okumak için yeniden satın almanız gerekir.',
      en: '“$title” will be removed from Purchased. You\'ll need to buy it again to read it.');
  static String deleteFavoriteConfirm(String title) =>
      t(tk: '«$title» Halanlarymdan aýrylar.', ru: '«$title» исчезнет из избранного.', tr: '«$title» favorilerimden kalkar.', en: '“$title” will be removed from Favorites.');
  static String deleteOwnBookConfirm(String title) => t(
      tk: '«$title» faýly enjamyňyzdan hemişelik pozulýar.',
      ru: 'Файл «$title» будет навсегда удалён с устройства.',
      tr: '«$title» dosyası cihazınızdan kalıcı olarak silinir.',
      en: 'The file “$title” will be permanently deleted from your device.');
  static String removedFromFavorites(String title) =>
      t(tk: '«$title» Halanlarymdan aýryldy', ru: '«$title» удалена из избранного', tr: '«$title» favorilerimden kaldırıldı', en: '“$title” removed from favorites');
  static String bookDeleted(String title) => t(tk: '«$title» tekjeden aýryldy', ru: '«$title» удалена с полки', tr: '«$title» raftan kaldırıldı', en: '“$title” removed from shelf');

  // Own-books tab.
  static String fileAddError(Object e) => t(tk: 'Faýl goşulmady: $e', ru: 'Файл не добавлен: $e', tr: 'Dosya eklenemedi: $e', en: 'File couldn\'t be added: $e');
  static String get addFileTitle => t(tk: 'EPUB / PDF faýl goş', ru: 'Добавить файл EPUB / PDF', tr: 'EPUB / PDF dosyası ekle', en: 'Add an EPUB / PDF file');
  static String get addFileSubtitle =>
      t(tk: 'Telefondaky faýllary Reader-da aç', ru: 'Открыть файлы с телефона в Reader', tr: 'Telefondaki dosyaları Reader\'da aç', en: 'Open files from your phone in Reader');
  static String get addedBooks => t(tk: 'Goşulan kitaplar', ru: 'Добавленные книги', tr: 'Eklenen kitaplar', en: 'Added books');
  static String get localOnlyNotice => t(
        tk: 'Bu kitaplar diňe lokal işleýär, serwere ýüklenmeýär.',
        ru: 'Эти книги работают только локально и не загружаются на сервер.',
        tr: 'Bu kitaplar yalnızca yerel olarak çalışır, sunucuya yüklenmez.',
        en: 'These books work locally only and aren\'t uploaded to the server.',
      );

  // Offline library screen.
  static String get noInternetSnackbar => t(tk: 'Entek internet ýok', ru: 'Пока нет интернета', tr: 'Henüz internet yok', en: 'No internet yet');
  static String get noInternetTitle => t(tk: 'Internet ýok', ru: 'Нет интернета', tr: 'İnternet yok', en: 'No internet');
  static String get noInternetSubtitle => t(
      tk: 'Diňe ýüklenen kitaplary okap bilersiňiz',
      ru: 'Вы можете читать только загруженные книги',
      tr: 'Yalnızca indirilen kitapları okuyabilirsiniz',
      en: 'You can only read books you\'ve downloaded');
  static String get checkConnection => t(tk: 'Baglanyşygy barla', ru: 'Проверить соединение', tr: 'Bağlantıyı kontrol et', en: 'Check connection');
  static String get goToLibrary => t(tk: 'Kitaphanama git', ru: 'Перейти в библиотеку', tr: 'Kitaplığıma git', en: 'Go to my library');
  static String get noOfflineBooksTitle => t(tk: 'Oflaýn kitap ýok', ru: 'Нет офлайн-книг', tr: 'Çevrimdışı kitap yok', en: 'No offline books');
  static String get noOfflineBooksBody => t(
        tk: 'Internete birikdirilende kitaphananyň ähli aýratynlyklary açylar.',
        ru: 'Все функции библиотеки станут доступны при подключении к интернету.',
        tr: 'İnternete bağlandığınızda kütüphanenin tüm özellikleri açılacak.',
        en: 'All library features will unlock once you\'re back online.',
      );
}
