import '../strings_base.dart';

/// Strings for [LibraryScreen] and [OfflineLibraryScreen].
class LibraryStrings {
  LibraryStrings._();

  // Library screen — title & tabs.
  static String get libraryTitle =>
      t(tk: 'Kitap Tekjäm', ru: 'Моя библиотека', tr: 'Kitaplığım');
  static String get tabReading =>
      t(tk: 'Okaýanlarym', ru: 'Читаю', tr: 'Okuduklarım');
  static String get tabFinished =>
      t(tk: 'Okap gutaranlarym', ru: 'Прочитанные', tr: 'Bitirdiklerim');
  static String get tabDownloaded =>
      t(tk: 'Ýüklenenler', ru: 'Загруженные', tr: 'İndirilenler');
  static String get tabPurchased =>
      t(tk: 'Satyn Alinanlar', ru: 'Купленные', tr: 'Satın Alınanlar');
  static String get tabFavorites =>
      t(tk: 'Halaýanlarym', ru: 'Избранное', tr: 'Favorilerim');
  static String get tabOwnBooks =>
      t(tk: 'Öz Kitaplarym', ru: 'Мои книги', tr: 'Kendi Kitaplarım');

  // Empty states.
  static String get emptyPurchased => t(
      tk: 'Aýratyn satyn alnan kitap ýok',
      ru: 'Нет отдельно купленных книг',
      tr: 'Ayrıca satın alınmış kitap yok');
  static String get emptyFavorites => t(
      tk: 'Halanan kitap ýok',
      ru: 'Нет избранных книг',
      tr: 'Favori kitap yok');
  static String get emptyReading => t(
      tk: 'Häzir okalýan kitap ýok',
      ru: 'Сейчас нет читаемых книг',
      tr: 'Şu anda okunan kitap yok');
  static String get emptyFinished => t(
      tk: 'Okap gutaran kitap ýok',
      ru: 'Нет прочитанных книг',
      tr: 'Henüz bitirdiğin kitap yok');
  static String get emptyDownloaded => t(
      tk: 'Ýüklenen kitap ýok',
      ru: 'Нет загруженных книг',
      tr: 'İndirilen kitap yok');
  static String get emptyDownloadedSub => t(
      tk: 'Oflaýn okamak üçin kitap ýükläň',
      ru: 'Загрузите книгу для чтения офлайн',
      tr: 'Çevrimdışı okumak için kitap indirin');
  static String get retry =>
      t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');
  static String get loginRequiredTitle => t(
      tk: 'Kitaphanaňyzy görmek üçin hasabyňyza giriň',
      ru: 'Войдите в аккаунт, чтобы увидеть свою библиотеку',
      tr: 'Kitaplığınızı görmek için giriş yapın');
  static String get loginRequiredSub => t(
      tk: 'Kitap goşmak we okamak üçin ilki giriş etmeli',
      ru: 'Чтобы добавлять и читать книги, сначала войдите в аккаунт',
      tr: 'Kitap eklemek ve okumak için önce giriş yapmalısınız');
  static String get offlineBookUnavailable => t(
      tk: 'Bu kitap enjamyňyza ýüklenmändir',
      ru: 'Эта книга не загружена на устройство',
      tr: 'Bu kitap cihazınıza indirilmemiş');

  // Own-books tab.
  static String fileAddError(Object e) => t(
      tk: 'Faýl goşulmady: $e',
      ru: 'Файл не добавлен: $e',
      tr: 'Dosya eklenemedi: $e');
  static String get addFileTitle => t(
      tk: 'EPUB / PDF faýl goş',
      ru: 'Добавить файл EPUB / PDF',
      tr: 'EPUB / PDF dosyası ekle');
  static String get addFileSubtitle => t(
      tk: 'Telefondaky faýllary Reader-da aç',
      ru: 'Открыть файлы с телефона в Reader',
      tr: 'Telefondaki dosyaları Reader\'da aç');
  static String get addedBooks => t(
      tk: 'Goşulan kitaplar', ru: 'Добавленные книги', tr: 'Eklenen kitaplar');
  static String get localOnlyNotice => t(
        tk: 'Bu kitaplar diňe lokal işleýär, serwere ýüklenmeýär.',
        ru: 'Эти книги работают только локально и не загружаются на сервер.',
        tr: 'Bu kitaplar yalnızca yerel olarak çalışır, sunucuya yüklenmez.',
      );

  // Offline library screen.
  static String get noInternetSnackbar => t(
      tk: 'Entek internet ýok',
      ru: 'Пока нет интернета',
      tr: 'Henüz internet yok');
  static String get noInternetTitle =>
      t(tk: 'Internet ýok', ru: 'Нет интернета', tr: 'İnternet yok');
  static String get noInternetSubtitle => t(
      tk: 'Diňe ýüklenen kitaplary okap bilersiňiz',
      ru: 'Вы можете читать только загруженные книги',
      tr: 'Yalnızca indirilen kitapları okuyabilirsiniz');
  static String get checkConnection => t(
      tk: 'Baglanyşygy barla',
      ru: 'Проверить соединение',
      tr: 'Bağlantıyı kontrol et');
  static String get goToLibrary => t(
      tk: 'Kitaphanama git', ru: 'Перейти в библиотеку', tr: 'Kitaplığıma git');
  static String get noOfflineBooksTitle => t(
      tk: 'Oflaýn kitap ýok',
      ru: 'Нет офлайн-книг',
      tr: 'Çevrimdışı kitap yok');
  static String get noOfflineBooksBody => t(
        tk: 'Internete birikdirilende kitaphananyň ähli aýratynlyklary açylar.',
        ru: 'Все функции библиотеки станут доступны при подключении к интернету.',
        tr: 'İnternete bağlandığınızda kütüphanenin tüm özellikleri açılacak.',
      );
}
