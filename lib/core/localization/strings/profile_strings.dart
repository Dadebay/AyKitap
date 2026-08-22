import '../strings_base.dart';

/// Strings for the rest of the "profile" module: [BookRequestSheet],
/// [ReportProblemSheet], [EditProfileScreen], [NotesScreen], and
/// [ProfileScreen]. (Settings has its own `SettingsStrings`.)
class ProfileStrings {
  ProfileStrings._();

  // book_request_sheet.dart / report_problem_sheet.dart
  // Moved to ProfileFeedbackStrings — see that file.

  // edit_profile_screen.dart (defaultReaderName also used by profile_screen.dart;
  // save also used by notes_screen.dart)
  static String get defaultReaderName =>
      t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu');
  static String get editProfileTitle =>
      t(tk: 'Profili üýtget', ru: 'Изменить профиль', tr: 'Profili düzenle');
  static String get usernameLabel =>
      t(tk: 'Ulanyjy ady', ru: 'Имя пользователя', tr: 'Kullanıcı adı');
  static String get usernameHint => t(
        tk: 'Ulanyjy adyňyzy giriziň',
        ru: 'Введите имя пользователя',
        tr: 'Kullanıcı adınızı girin',
      );
  static String get phoneNumberLabel =>
      t(tk: 'Telefon belgisi', ru: 'Номер телефона', tr: 'Telefon numarası');
  static String get save => t(tk: 'Ýatda sakla', ru: 'Сохранить', tr: 'Kaydet');
  static String imageNotSelected(Object error) => t(
        tk: 'Surat saýlanmady: $error',
        ru: 'Изображение не выбрано: $error',
        tr: 'Resim seçilmedi: $error',
      );
  static String get chooseAvatarTitle =>
      t(tk: 'Awatar saýla', ru: 'Выберите аватар', tr: 'Avatar seç');
  static String get chooseOwnPhoto => t(
        tk: 'Öz suratyňyzy saýlaň',
        ru: 'Выберите своё фото',
        tr: 'Kendi fotoğrafınızı seçin',
      );
  static String get presetAvatars =>
      t(tk: 'Taýyn awatarlar', ru: 'Готовые аватары', tr: 'Hazır avatarlar');

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
  static String get noNotesYetTitle => t(
      tk: 'Ilkinji belligiňizi ediň',
      ru: 'Сделайте первую заметку',
      tr: 'İlk notunuzu oluşturun');
  static String get noNotesYetSubtitle => t(
        tk: 'Kitap okaýarkaň bir ýeri saýlap belläň — alyntyňyz we pikiriňiz şu ýerde toplanar.',
        ru: 'Выделите отрывок во время чтения — ваши цитаты и мысли соберутся здесь.',
        tr: 'Kitap okurken bir yeri seçip işaretleyin — alıntılarınız ve notlarınız burada toplanır.',
      );
  static String get goToBook =>
      t(tk: 'Kitaba geç', ru: 'Перейти к книге', tr: 'Kitaba git');
  static String get editNoteTitle =>
      t(tk: 'Noty redaktirle', ru: 'Редактировать заметку', tr: 'Notu düzenle');
  static String get editNoteSubtitle => t(
        tk: 'Alyntyňyzy üýtgediň',
        ru: 'Измените свою цитату',
        tr: 'Alıntınızı düzenleyin',
      );
  static String get noteTextHint => t(
      tk: 'Alyntyňyzy ýazyň',
      ru: 'Напишите свою цитату',
      tr: 'Alıntınızı yazın');
  static String get noteColorLabel =>
      t(tk: 'Bellik reňki', ru: 'Цвет заметки', tr: 'Not rengi');

  // profile_screen.dart
  static String get profileTitle =>
      t(tk: 'Profil', ru: 'Профиль', tr: 'Profil');
  static String get loginHeading => t(
      tk: 'Hasabyňyza giriň',
      ru: 'Войдите в аккаунт',
      tr: 'Hesabınıza giriş yapın');
  static String get loginBody => t(
        tk: 'Kitaplaryňyzy, streak-iňizi we balansyňyzy\ngörmek üçin giriş ediň.',
        ru: 'Войдите, чтобы видеть свои книги,\nстрик и баланс.',
        tr: 'Kitaplarınızı, serinizi ve bakiyenizi\ngörmek için giriş yapın.',
      );
  static String get login => t(tk: 'Giriş et', ru: 'Войти', tr: 'Giriş yap');
  static String get subscription =>
      t(tk: 'Abunalyk', ru: 'Подписка', tr: 'Abonelik');
  static String subscriptionActiveUntil(String date) => t(
        tk: 'Işjeň — $date çenli',
        ru: 'Активна до $date',
        tr: 'Aktif — $date tarihine kadar',
      );
  static String get subscribeNow =>
      t(tk: 'Abuna ýazyl', ru: 'Оформить подписку', tr: 'Abone ol');
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
  // widgets/balance_card.dart
  static String get balanceTitle =>
      t(tk: 'Balansym', ru: 'Мой баланс', tr: 'Bakiyem');
  static String get balanceSubtitle => t(
        tk: 'Abunalyk we kitap satyn almak üçin',
        ru: 'Для подписки и покупки книг',
        tr: 'Abonelik ve kitap satın almak için',
      );
  static String get topUpBalance =>
      t(tk: 'Doldur', ru: 'Пополнить', tr: 'Yükle');

  // balance_screen.dart
  static String get balanceHistoryTitle =>
      t(tk: 'Balans taryhy', ru: 'История баланса', tr: 'Bakiye geçmişi');
  static String get balanceHistoryEmptyTitle => t(
      tk: 'Entek hiç zat ýok', ru: 'Пока ничего нет', tr: 'Henüz bir şey yok');
  static String get balanceHistoryEmptySubtitle => t(
        tk: 'Doldurmalar we satyn alan zatlaryňyz şu ýerde görkeziler.',
        ru: 'Здесь будут показаны пополнения и покупки.',
        tr: 'Yüklemeler ve satın aldıklarınız burada gösterilir.',
      );
  static String get balanceBookPurchase => t(
      tk: 'Kitap satyn alyndy', ru: 'Книга куплена', tr: 'Kitap satın alındı');
  static String get balanceTopUp =>
      t(tk: 'Balans dolduryldy', ru: 'Баланс пополнен', tr: 'Bakiye yüklendi');
  static String get balanceOtherActivity =>
      t(tk: 'Balans hereketi', ru: 'Операция по балансу', tr: 'Bakiye işlemi');
  static String get cardPaymentsTitle => t(
      tk: 'Kart arkaly tölegler', ru: 'Платежи картой', tr: 'Kartla ödemeler');
  static String get cardPaymentsEmpty => t(
        tk: 'Kart arkaly töleg ýok',
        ru: 'Платежей картой пока нет',
        tr: 'Henüz kartla ödeme yok',
      );
  static String get cardPaymentsEmptySubtitle => t(
        tk: 'Kart bilen eden tölegleriňiz şu ýerde görkeziler.',
        ru: 'Здесь будут показаны ваши платежи картой.',
        tr: 'Kartla yaptığınız ödemeler burada gösterilecek.',
      );

  static String get settingsEntryTitle =>
      t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar');
  static String get viewAllNotes =>
      t(tk: 'Bellikler', ru: 'Заметки', tr: 'Notlar');
  static String get sendBookRequest => t(
        tk: 'Kitap haýyşy iber',
        ru: 'Отправить запрос книги',
        tr: 'Kitap talebi gönder',
      );

  // book_suggestions_screen.dart / widgets/book_suggestion_card.dart
  static String get myBookRequestsTitle => t(
        tk: 'Kitap haýyşlarym',
        ru: 'Мои запросы книг',
        tr: 'Kitap taleplerim',
      );
  static String get noSuggestionsYet => t(
        tk: 'Entäk haýyş ýok.\nAşakdaky düwme bilen kitap haýyş ediň.',
        ru: 'Пока нет запросов.\nЗапросите книгу кнопкой ниже.',
        tr: 'Henüz talep yok.\nAşağıdaki düğmeyle kitap talep edin.',
      );
  static String get retry =>
      t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');
  static String get suggestionStatusPending =>
      t(tk: 'Garaşylýar', ru: 'На рассмотрении', tr: 'Beklemede');
  static String get suggestionStatusAccepted =>
      t(tk: 'Kabul edildi', ru: 'Принято', tr: 'Kabul edildi');
  static String get suggestionStatusRejected =>
      t(tk: 'Ret edildi', ru: 'Отклонено', tr: 'Reddedildi');
  static String get newBookRequest =>
      t(tk: 'Täze haýyş', ru: 'Новый запрос', tr: 'Yeni talep');
  static String get deleteBookRequest =>
      t(tk: 'Haýyşy poz', ru: 'Удалить запрос', tr: 'Talebi sil');
  static String deleteBookRequestConfirm(String name) => t(
        tk: '“$name” kitaphana haýyşyňyzy pozmak isleýärsiňizmi?',
        ru: 'Удалить запрос книги «$name»?',
        tr: '“$name” kitap talebini silmek istiyor musunuz?',
      );
  static String get bookRequestDeleted => t(
      tk: 'Kitap haýyşy pozuldy',
      ru: 'Запрос книги удалён',
      tr: 'Kitap talebi silindi');
}
