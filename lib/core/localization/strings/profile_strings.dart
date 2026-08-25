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
      t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu', en: 'Reader');
  static String get editProfileTitle => t(
      tk: 'Profili üýtget',
      ru: 'Изменить профиль',
      tr: 'Profili düzenle',
      en: 'Edit profile');
  static String get usernameLabel => t(
      tk: 'Ulanyjy ady',
      ru: 'Имя пользователя',
      tr: 'Kullanıcı adı',
      en: 'Username');
  static String get usernameHint => t(
        tk: 'Ulanyjy adyňyzy giriziň',
        ru: 'Введите имя пользователя',
        tr: 'Kullanıcı adınızı girin',
        en: 'Enter your username',
      );
  static String get phoneNumberLabel => t(
      tk: 'Telefon belgisi',
      ru: 'Номер телефона',
      tr: 'Telefon numarası',
      en: 'Phone number');
  static String get save =>
      t(tk: 'Ýatda sakla', ru: 'Сохранить', tr: 'Kaydet', en: 'Save');
  static String imageNotSelected(Object error) => t(
        tk: 'Surat saýlanmady: $error',
        ru: 'Изображение не выбрано: $error',
        tr: 'Resim seçilmedi: $error',
        en: 'No image selected: $error',
      );
  static String get chooseAvatarTitle => t(
      tk: 'Awatar saýla',
      ru: 'Выберите аватар',
      tr: 'Avatar seç',
      en: 'Choose an avatar');
  static String get chooseOwnPhoto => t(
        tk: 'Öz suratyňyzy saýlaň',
        ru: 'Выберите своё фото',
        tr: 'Kendi fotoğrafınızı seçin',
        en: 'Choose your own photo',
      );
  static String get presetAvatars => t(
      tk: 'Taýyn awatarlar',
      ru: 'Готовые аватары',
      tr: 'Hazır avatarlar',
      en: 'Preset avatars');

  // notes_screen.dart (cancel also used within notes_screen.dart's edit sheet)
  static String get deleteNoteConfirmTitle => t(
        tk: 'Noty pozmak isleýärsiňizmi?',
        ru: 'Удалить заметку?',
        tr: 'Notu silmek istiyor musunuz?',
        en: 'Delete this note?',
      );
  static String get actionIrreversible => t(
        tk: 'Bu amal yzyna gaýtarylmaýar.',
        ru: 'Это действие необратимо.',
        tr: 'Bu işlem geri alınamaz.',
        en: 'This action can\'t be undone.',
      );
  static String get delete =>
      t(tk: 'Poz', ru: 'Удалить', tr: 'Sil', en: 'Delete');
  static String get cancel =>
      t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç', en: 'Cancel');
  static String get notesTitle =>
      t(tk: 'Notlar', ru: 'Заметки', tr: 'Notlar', en: 'Notes');
  static String get noNotesYetTitle => t(
      tk: 'Ilkinji belligiňizi ediň',
      ru: 'Сделайте первую заметку',
      tr: 'İlk notunuzu oluşturun',
      en: 'Make your first note');
  static String get noNotesYetSubtitle => t(
        tk: 'Kitap okaýarkaň bir ýeri saýlap belläň — alyntyňyz we pikiriňiz şu ýerde toplanar.',
        ru: 'Выделите отрывок во время чтения — ваши цитаты и мысли соберутся здесь.',
        tr: 'Kitap okurken bir yeri seçip işaretleyin — alıntılarınız ve notlarınız burada toplanır.',
        en: 'Select a passage while reading — your quotes and thoughts will collect here.',
      );
  static String get goToBook => t(
      tk: 'Kitaba geç',
      ru: 'Перейти к книге',
      tr: 'Kitaba git',
      en: 'Go to book');
  static String get editNoteTitle => t(
      tk: 'Noty redaktirle',
      ru: 'Редактировать заметку',
      tr: 'Notu düzenle',
      en: 'Edit note');
  static String get editNoteSubtitle => t(
        tk: 'Alyntyňyzy üýtgediň',
        ru: 'Измените свою цитату',
        tr: 'Alıntınızı düzenleyin',
        en: 'Change your quote',
      );
  static String get noteTextHint => t(
      tk: 'Alyntyňyzy ýazyň',
      ru: 'Напишите свою цитату',
      tr: 'Alıntınızı yazın',
      en: 'Write your quote');
  static String get noteColorLabel => t(
      tk: 'Bellik reňki',
      ru: 'Цвет заметки',
      tr: 'Not rengi',
      en: 'Note color');

  // profile_screen.dart
  static String get profileTitle =>
      t(tk: 'Profil', ru: 'Профиль', tr: 'Profil', en: 'Profile');
  static String get loginHeading => t(
      tk: 'Hasabyňyza giriň',
      ru: 'Войдите в аккаунт',
      tr: 'Hesabınıza giriş yapın',
      en: 'Sign in to your account');
  static String get loginBody => t(
        tk: 'Kitaplaryňyzy, streak-iňizi we balansyňyzy\ngörmek üçin giriş ediň.',
        ru: 'Войдите, чтобы видеть свои книги,\nстрик и баланс.',
        tr: 'Kitaplarınızı, serinizi ve bakiyenizi\ngörmek için giriş yapın.',
        en: 'Sign in to see your books,\nstreak and balance.',
      );
  static String get login =>
      t(tk: 'Giriş et', ru: 'Войти', tr: 'Giriş yap', en: 'Sign in');
  static String get subscription =>
      t(tk: 'Abunalyk', ru: 'Подписка', tr: 'Abonelik', en: 'Subscription');
  static String subscriptionActiveUntil(String date) => t(
        tk: 'Işjeň — $date çenli',
        ru: 'Активна до $date',
        tr: 'Aktif — $date tarihine kadar',
        en: 'Active — until $date',
      );
  static String get subscribeNow => t(
      tk: 'Abuna ýazyl',
      ru: 'Оформить подписку',
      tr: 'Abone ol',
      en: 'Subscribe now');
  static String get subscriptionActiveStatus =>
      t(tk: 'Işjeň', ru: 'Активна', tr: 'Aktif', en: 'Active');
  static String get subscriptionAllBooksUnlocked => t(
        tk: 'Ähli kitaplar siziň üçin açyk',
        ru: 'Все книги доступны для вас',
        tr: 'Tüm kitaplar sizin için açık',
        en: 'Every book is unlocked for you',
      );
  static String get subscriptionExpiryLabel => t(
      tk: 'Gutarýan senesi',
      ru: 'Действует до',
      tr: 'Bitiş tarihi',
      en: 'Valid until');
  static String subscriptionDaysLeft(Object count) => t(
        tk: '$count gün galdy',
        ru: 'Осталось дней: $count',
        tr: '$count gün kaldı',
        en: '$count days left',
      );
  static String get subscriptionManage => t(
        tk: 'Abunalygy dolandyr',
        ru: 'Управлять подпиской',
        tr: 'Aboneliği yönet',
        en: 'Manage subscription',
      );
  static String streakDays(Object count) => t(
        tk: '$count gün yzly-yzyna',
        ru: '$count дней подряд',
        tr: 'Arka arkaya $count gün',
        en: '$count days in a row',
      );
  static String bestStreak(Object count) => t(
        tk: 'Iň gowy netije: $count gün',
        ru: 'Лучший результат: $count дней',
        tr: 'En iyi sonuç: $count gün',
        en: 'Best streak: $count days',
      );
  // widgets/balance_card.dart
  static String get balanceTitle =>
      t(tk: 'Balansym', ru: 'Мой баланс', tr: 'Bakiyem', en: 'My balance');
  static String get balanceSubtitle => t(
        tk: 'Abunalyk we kitap satyn almak üçin',
        ru: 'Для подписки и покупки книг',
        tr: 'Abonelik ve kitap satın almak için',
        en: 'For subscriptions and book purchases',
      );
  static String get topUpBalance =>
      t(tk: 'Doldur', ru: 'Пополнить', tr: 'Yükle', en: 'Top up');

  // balance_screen.dart
  static String get balanceHistoryTitle => t(
      tk: 'Balans taryhy',
      ru: 'История баланса',
      tr: 'Bakiye geçmişi',
      en: 'Balance history');
  static String get balanceHistoryEmptyTitle => t(
      tk: 'Entek hiç zat ýok',
      ru: 'Пока ничего нет',
      tr: 'Henüz bir şey yok',
      en: 'Nothing here yet');
  static String get balanceHistoryEmptySubtitle => t(
        tk: 'Doldurmalar we satyn alan zatlaryňyz şu ýerde görkeziler.',
        ru: 'Здесь будут показаны пополнения и покупки.',
        tr: 'Yüklemeler ve satın aldıklarınız burada gösterilir.',
        en: 'Your top-ups and purchases will show up here.',
      );
  static String get balanceBookPurchase => t(
      tk: 'Kitap satyn alyndy',
      ru: 'Книга куплена',
      tr: 'Kitap satın alındı',
      en: 'Book purchased');
  static String get balanceTopUp => t(
      tk: 'Balans dolduryldy',
      ru: 'Баланс пополнен',
      tr: 'Bakiye yüklendi',
      en: 'Balance topped up');
  static String get balanceOtherActivity => t(
      tk: 'Balans hereketi',
      ru: 'Операция по балансу',
      tr: 'Bakiye işlemi',
      en: 'Balance activity');
  static String get cardPaymentsTitle => t(
      tk: 'Kart arkaly tölegler',
      ru: 'Платежи картой',
      tr: 'Kartla ödemeler',
      en: 'Card payments');
  static String get cardPaymentsEmpty => t(
        tk: 'Kart arkaly töleg ýok',
        ru: 'Платежей картой пока нет',
        tr: 'Henüz kartla ödeme yok',
        en: 'No card payments yet',
      );
  static String get cardPaymentsEmptySubtitle => t(
        tk: 'Kart bilen eden tölegleriňiz şu ýerde görkeziler.',
        ru: 'Здесь будут показаны ваши платежи картой.',
        tr: 'Kartla yaptığınız ödemeler burada gösterilecek.',
        en: 'Your card payments will show up here.',
      );

  static String get settingsEntryTitle =>
      t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar', en: 'Settings');
  static String get viewAllNotes =>
      t(tk: 'Bellikler', ru: 'Заметки', tr: 'Notlar', en: 'Notes');
  static String get sendBookRequest => t(
        tk: 'Kitap haýyşy iber',
        ru: 'Отправить запрос книги',
        tr: 'Kitap talebi gönder',
        en: 'Send a book request',
      );

  // book_suggestions_screen.dart / widgets/book_suggestion_card.dart
  static String get myBookRequestsTitle => t(
        tk: 'Kitap haýyşlarym',
        ru: 'Мои запросы книг',
        tr: 'Kitap taleplerim',
        en: 'My book requests',
      );
  static String get noSuggestionsYet => t(
        tk: 'Entäk haýyş ýok.\nAşakdaky düwme bilen kitap haýyş ediň.',
        ru: 'Пока нет запросов.\nЗапросите книгу кнопкой ниже.',
        tr: 'Henüz talep yok.\nAşağıdaki düğmeyle kitap talep edin.',
        en: 'No requests yet.\nRequest a book with the button below.',
      );
  static String get retry => t(
      tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');
  static String get suggestionStatusPending => t(
      tk: 'Garaşylýar', ru: 'На рассмотрении', tr: 'Beklemede', en: 'Pending');
  static String get suggestionStatusAccepted =>
      t(tk: 'Kabul edildi', ru: 'Принято', tr: 'Kabul edildi', en: 'Accepted');
  static String get suggestionStatusRejected =>
      t(tk: 'Ret edildi', ru: 'Отклонено', tr: 'Reddedildi', en: 'Rejected');
  static String get newBookRequest => t(
      tk: 'Täze haýyş',
      ru: 'Новый запрос',
      tr: 'Yeni talep',
      en: 'New request');
  static String get deleteBookRequest => t(
      tk: 'Haýyşy poz',
      ru: 'Удалить запрос',
      tr: 'Talebi sil',
      en: 'Delete request');
  static String deleteBookRequestConfirm(String name) => t(
        tk: '“$name” kitaphana haýyşyňyzy pozmak isleýärsiňizmi?',
        ru: 'Удалить запрос книги «$name»?',
        tr: '“$name” kitap talebini silmek istiyor musunuz?',
        en: 'Delete your request for “$name”?',
      );
  static String get bookRequestDeleted => t(
      tk: 'Kitap haýyşy pozuldy',
      ru: 'Запрос книги удалён',
      tr: 'Kitap talebi silindi',
      en: 'Book request deleted');
}
