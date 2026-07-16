import '../strings_base.dart';

/// Strings for the rest of the "profile" module: [FinanceScreen],
/// [BookRequestSheet], [EditProfileScreen], [NotesScreen], and
/// [ProfileScreen]. (Settings has its own `SettingsStrings`.)
class ProfileStrings {
  ProfileStrings._();

  // Shared across finance_screen.dart and profile_screen.dart.
  static String get finance => t(tk: 'Maliýe', ru: 'Финансы', tr: 'Finans');
  static String balanceManat(Object amount) => t(
        tk: '$amount manat',
        ru: '$amount манат',
        tr: '$amount manat',
      );

  // finance_screen.dart
  static String get balance => t(tk: 'Balans', ru: 'Баланс', tr: 'Bakiye');
  static String get promoCodeHint => t(tk: 'Promo kod', ru: 'Промокод', tr: 'Promosyon kodu');
  static String get promoCheckingMock => t(
        tk: 'Promo kod barlanýar (mock)',
        ru: 'Промокод проверяется (мок)',
        tr: 'Promosyon kodu kontrol ediliyor (mock)',
      );
  static String get use => t(tk: 'Ulan', ru: 'Применить', tr: 'Kullan');
  static String get topUpWithCard => t(
        tk: 'Bank kartasy bilen doldurmak',
        ru: 'Пополнить банковской картой',
        tr: 'Banka kartıyla yükle',
      );

  // book_request_sheet.dart
  static String get languageTurkmen => t(tk: 'Türkmen dili', ru: 'Туркменский язык', tr: 'Türkmence');
  static String get languageTurkish => t(tk: 'Türk dili', ru: 'Турецкий язык', tr: 'Türkçe');
  static String get languageRussian => t(tk: 'Rus dili', ru: 'Русский язык', tr: 'Rusça');
  static String get languageEnglish => t(tk: 'Iňlis dili', ru: 'Английский язык', tr: 'İngilizce');
  static String get languageOther => t(tk: 'Beýleki', ru: 'Другое', tr: 'Diğer');
  static String get requestSentMock => t(
        tk: 'Haýyşyňyz iberildi (mock)',
        ru: 'Ваш запрос отправлен (мок)',
        tr: 'İsteğiniz gönderildi (mock)',
      );
  static String get bookRequestTitle => t(tk: 'Kitap haýyşy', ru: 'Запрос книги', tr: 'Kitap talebi');
  static String get bookRequestSubtitle => t(
        tk: 'Programmada ýok kitaby haýyş ediň',
        ru: 'Запросите книгу, которой нет в приложении',
        tr: 'Uygulamada olmayan bir kitabı talep edin',
      );
  static String get bookTitleLabel => t(tk: 'Kitap ady', ru: 'Название книги', tr: 'Kitap adı');
  static String get bookTitleHint => t(
        tk: 'Mysal: Ýitgi we tapyş',
        ru: 'Например: Потеря и находка',
        tr: 'Örnek: Kayıp ve Buluş',
      );
  static String get authorNameLabel => t(tk: 'Ýazar ady', ru: 'Имя автора', tr: 'Yazar adı');
  static String get authorNameHint => t(
        tk: 'Mysal: Osman Ödäýew',
        ru: 'Например: Осман Одаев',
        tr: 'Örnek: Osman Ödeýew',
      );
  static String get languageLabel => t(tk: 'Dili', ru: 'Язык', tr: 'Dili');
  static String get send => t(tk: 'Iber', ru: 'Отправить', tr: 'Gönder');

  // edit_profile_screen.dart (defaultReaderName also used by profile_screen.dart;
  // save also used by notes_screen.dart)
  static String get defaultReaderName => t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu');
  static String get editProfileTitle => t(tk: 'Profili üýtget', ru: 'Изменить профиль', tr: 'Profili düzenle');
  static String get usernameLabel => t(tk: 'Ulanyjy ady', ru: 'Имя пользователя', tr: 'Kullanıcı adı');
  static String get usernameHint => t(
        tk: 'Ulanyjy adyňyzy giriziň',
        ru: 'Введите имя пользователя',
        tr: 'Kullanıcı adınızı girin',
      );
  static String get phoneNumberLabel => t(tk: 'Telefon belgisi', ru: 'Номер телефона', tr: 'Telefon numarası');
  static String get save => t(tk: 'Ýatda sakla', ru: 'Сохранить', tr: 'Kaydet');
  static String imageNotSelected(Object error) => t(
        tk: 'Surat saýlanmady: $error',
        ru: 'Изображение не выбрано: $error',
        tr: 'Resim seçilmedi: $error',
      );
  static String get chooseAvatarTitle => t(tk: 'Awatar saýla', ru: 'Выберите аватар', tr: 'Avatar seç');
  static String get chooseOwnPhoto => t(
        tk: 'Öz suratyňyzy saýlaň',
        ru: 'Выберите своё фото',
        tr: 'Kendi fotoğrafınızı seçin',
      );
  static String get presetAvatars => t(tk: 'Taýyn awatarlar', ru: 'Готовые аватары', tr: 'Hazır avatarlar');

  // notes_screen.dart (cancel also used within notes_screen.dart's edit sheet)
  static String get deleteNoteConfirmTitle => t(
        tk: 'Noty pozmak isleýärsiňizmi?',
        ru: 'Удалить заметку?',
        tr: 'Notu silmek istiyor musunuz?',
      );
  static String get actionIrreversible => t(
        tk: 'Bu amal yzyna gaýtarylmaýar.',
        ru: 'Это действие необратимо.',
        tr: 'Bu işlem geri alınamaz.',
      );
  static String get delete => t(tk: 'Poz', ru: 'Удалить', tr: 'Sil');
  static String get cancel => t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç');
  static String get notesTitle => t(tk: 'Notlar', ru: 'Заметки', tr: 'Notlar');
  static String get noNotesYet => t(tk: 'Entäk not ýok', ru: 'Пока нет заметок', tr: 'Henüz not yok');
  static String get goToBook => t(tk: 'Kitaba geç', ru: 'Перейти к книге', tr: 'Kitaba git');
  static String get editNoteTitle => t(tk: 'Noty redaktirle', ru: 'Редактировать заметку', tr: 'Notu düzenle');
  static String get editNoteSubtitle => t(
        tk: 'Alyntyňyzy üýtgediň',
        ru: 'Измените свою цитату',
        tr: 'Alıntınızı düzenleyin',
      );
  static String get noteTextHint => t(tk: 'Alyntyňyzy ýazyň', ru: 'Напишите свою цитату', tr: 'Alıntınızı yazın');

  // profile_screen.dart
  static String get profileTitle => t(tk: 'Profil', ru: 'Профиль', tr: 'Profil');
  static String get loginHeading => t(tk: 'Hasabyňyza giriň', ru: 'Войдите в аккаунт', tr: 'Hesabınıza giriş yapın');
  static String get loginBody => t(
        tk: 'Kitaplaryňyzy, streak-iňizi we balansyňyzy\ngörmek üçin giriş ediň.',
        ru: 'Войдите, чтобы видеть свои книги,\nстрик и баланс.',
        tr: 'Kitaplarınızı, serinizi ve bakiyenizi\ngörmek için giriş yapın.',
      );
  static String get login => t(tk: 'Giriş et', ru: 'Войти', tr: 'Giriş yap');
  static String get subscription => t(tk: 'Abunalyk', ru: 'Подписка', tr: 'Abonelik');
  static String get daysLeft => t(tk: '12 gün galdy', ru: 'Осталось 12 дней', tr: '12 gün kaldı');
  static String get subscribeNow => t(tk: 'Abuna ýazyl', ru: 'Оформить подписку', tr: 'Abone ol');
  static String streakDays(Object count) => t(
        tk: '$count gün yzly-yzyna',
        ru: '$count дней подряд',
        tr: 'Arka arkaya $count gün',
      );
  static String bestStreak(Object count) => t(
        tk: 'Iň gowy netije: $count gün',
        ru: 'Лучший результат: $count дней',
        tr: 'En iyi sonuç: $count gün',
      );
  static String get settingsEntryTitle => t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar');
  static String get viewAllNotes => t(tk: 'Ähli notlary gör', ru: 'Смотреть все заметки', tr: 'Tüm notları gör');
  static String get viewAllBookmarks => t(tk: 'Ähli bellikleri gör', ru: 'Смотреть все закладки', tr: 'Tüm yer imlerini gör');
  static String get bookmarksTitle => t(tk: 'Bellikler', ru: 'Закладки', tr: 'Yer imleri');
  static String get bookmarksEmpty => t(
        tk: 'Entäk bellik ýok.\nKitap okap, sahypany belläň.',
        ru: 'Пока нет закладок.\nОткройте книгу и отметьте страницу.',
        tr: 'Henüz yer imi yok.\nBir kitap açıp sayfa işaretleyin.',
      );
  static String get sendBookRequest => t(
        tk: 'Kitap haýyşy iber',
        ru: 'Отправить запрос книги',
        tr: 'Kitap talebi gönder',
      );
}
