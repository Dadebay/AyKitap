import '../strings_base.dart';

/// Strings for the auth flow: [PhoneLoginScreen], [OtpVerifyScreen], and
/// [NameEntryScreen].
class AuthStrings {
  AuthStrings._();

  // ── Phone login ──────────────────────────────────────────────────────
  static String get phoneLoginTitle => t(
      tk: 'Giriş / Hasaba durmak',
      ru: 'Вход / Регистрация',
      tr: 'Giriş / Kayıt ol',
      en: 'Sign in / Sign up');
  static String get phoneLoginSubtitle => t(
        tk: 'Telefon belgiňizi giriziň, size SMS arkaly\ntassyklama kody ibereris.',
        ru: 'Введите свой номер телефона, мы отправим вам\nпроверочный код по SMS.',
        tr: 'Telefon numaranızı girin, size SMS ile\nonay kodu göndereceğiz.',
        en: 'Enter your phone number and we\'ll send you\na verification code by SMS.',
      );
  static String get phoneNumberLabel => t(
      tk: 'Telefon belgisi',
      ru: 'Номер телефона',
      tr: 'Telefon numarası',
      en: 'Phone number');
  static String get phoneHint => t(
      tk: 'XX XX XX XX',
      ru: 'XX XX XX XX',
      tr: 'XX XX XX XX',
      en: 'XX XX XX XX');

  static String get sendCodeButton => t(
      tk: 'SMS kod ibermek',
      ru: 'Отправить SMS-код',
      tr: 'SMS kodu gönder',
      en: 'Send SMS code');
  static String get genericError => t(
        tk: 'Näbelli ýalñyşlyk ýüze çykdy. Gaýtadan synanyşyň.',
        ru: 'Произошла неизвестная ошибка. Попробуйте снова.',
        tr: 'Bilinmeyen bir hata oluştu. Tekrar deneyin.',
        en: 'Something went wrong. Please try again.',
      );
  static String get termsPrefix => t(
      tk: 'Dowam etmek bilen ',
      ru: 'Продолжая, вы соглашаетесь с ',
      tr: 'Devam ederek ',
      en: 'By continuing, you agree to the ');
  static String get termsLink => t(
      tk: 'Ulanyş Şertlerine',
      ru: 'Условиями использования',
      tr: 'Kullanım Şartları\'nı',
      en: 'Terms of Use');
  static String get termsSuffix => t(
      tk: ' razylaşýarsyňyz.', ru: '.', tr: ' kabul etmiş olursunuz.', en: '.');

  // ── International login (Firebase: email/password, Google, Apple) ─────
  static String get otherMethodsLink => t(
      tk: 'Başga usul bilen dowam et',
      ru: 'Продолжить другим способом',
      tr: 'Başka bir yöntemle devam et',
      en: 'Continue with another method');
  static String get internationalLoginTitle =>
      t(tk: 'Giriş', ru: 'Вход', tr: 'Giriş yap', en: 'Sign in');
  static String get internationalLoginSubtitle => t(
        tk: 'E-poçta, Google ýa-da Apple bilen giriň.',
        ru: 'Войдите через email, Google или Apple.',
        tr: 'E-posta, Google veya Apple ile giriş yap.',
        en: 'Sign in with email, Google, or Apple.',
      );
  static String get continueWithGoogle => t(
      tk: 'Google bilen dowam et',
      ru: 'Продолжить через Google',
      tr: 'Google ile devam et',
      en: 'Continue with Google');
  static String get continueWithApple => t(
      tk: 'Apple bilen dowam et',
      ru: 'Продолжить через Apple',
      tr: 'Apple ile devam et',
      en: 'Continue with Apple');
  static String get orDivider =>
      t(tk: 'ýa-da', ru: 'или', tr: 'veya', en: 'or');
  static String get emailLabel =>
      t(tk: 'E-poçta', ru: 'Эл. почта', tr: 'E-posta', en: 'Email');
  static String get passwordLabel =>
      t(tk: 'Parol', ru: 'Пароль', tr: 'Şifre', en: 'Password');
  static String get emailSignInButton =>
      t(tk: 'Girmek', ru: 'Войти', tr: 'Giriş yap', en: 'Sign in');
  static String get emailRegisterButton => t(
      tk: 'Hasap döret',
      ru: 'Создать аккаунт',
      tr: 'Hesap oluştur',
      en: 'Create account');
  static String get emailTogglePrefixHaveAccount => t(
      tk: 'Hasabyňyz barmy? ',
      ru: 'Уже есть аккаунт? ',
      tr: 'Zaten hesabın var mı? ',
      en: 'Already have an account? ');
  static String get emailTogglePrefixNoAccount => t(
      tk: 'Hasabyňyz ýokmy? ',
      ru: 'Ещё нет аккаунта? ',
      tr: 'Hesabın yok mu? ',
      en: 'Don\'t have an account? ');
  static String get emailToggleToSignIn =>
      t(tk: 'Gir', ru: 'Войти', tr: 'Giriş yap', en: 'Sign in');
  static String get emailToggleToRegister =>
      t(tk: 'Döret', ru: 'Создать', tr: 'Oluştur', en: 'Create one');

  static String get firebaseErrorInvalidEmail => t(
      tk: 'E-poçta salgysy nädogry.',
      ru: 'Неверный адрес электронной почты.',
      tr: 'E-posta adresi geçersiz.',
      en: 'That email address looks invalid.');
  static String get firebaseErrorWrongPassword => t(
      tk: 'E-poçta ýa-da parol nädogry.',
      ru: 'Неверный email или пароль.',
      tr: 'E-posta veya şifre hatalı.',
      en: 'Incorrect email or password.');
  static String get firebaseErrorUserNotFound => t(
      tk: 'Bu e-poçta bilen hasap tapylmady.',
      ru: 'Аккаунт с таким email не найден.',
      tr: 'Bu e-posta ile bir hesap bulunamadı.',
      en: 'No account found with that email.');
  static String get firebaseErrorEmailInUse => t(
      tk: 'Bu e-poçta eýýäm ulanylýar.',
      ru: 'Этот email уже используется.',
      tr: 'Bu e-posta zaten kullanılıyor.',
      en: 'That email is already in use.');
  static String get firebaseErrorWeakPassword => t(
      tk: 'Parol gaty ýönekeý — azyndan 6 nyşan giriziň.',
      ru: 'Слишком простой пароль — минимум 6 символов.',
      tr: 'Şifre çok zayıf — en az 6 karakter girin.',
      en: 'That password is too weak — use at least 6 characters.');
  static String get firebaseErrorNetwork => t(
      tk: 'Internet baglanyşygyny barlaň.',
      ru: 'Проверьте подключение к интернету.',
      tr: 'İnternet bağlantınızı kontrol edin.',
      en: 'Check your internet connection.');

  // ── OTP verify ───────────────────────────────────────────────────────
  static String get otpTitle => t(
      tk: 'Kody giriziň',
      ru: 'Введите код',
      tr: 'Kodu girin',
      en: 'Enter the code');
  static String get otpSentPrefix => t(
      tk: 'Şu belgä SMS iberdik: ',
      ru: 'Мы отправили SMS на номер: ',
      tr: 'Bu numaraya SMS gönderdik: ',
      en: 'We sent an SMS to: ');
  static String get resendAction => t(
      tk: 'Kody täzeden iber',
      ru: 'Отправить код повторно',
      tr: 'Kodu tekrar gönder',
      en: 'Resend code');
  static String get confirmButton =>
      t(tk: 'Tassykla', ru: 'Подтвердить', tr: 'Onayla', en: 'Confirm');
  static String get resendSnackbar => t(
      tk: 'Täze SMS kod iberildi',
      ru: 'Новый SMS-код отправлен',
      tr: 'Yeni SMS kodu gönderildi',
      en: 'A new SMS code was sent');
  static String get otherDeviceTitle => t(
      tk: 'Başga enjamda açyk',
      ru: 'Открыто на другом устройстве',
      tr: 'Başka bir cihazda açık',
      en: 'Open on another device');
  static String get otherDeviceBody => t(
        tk: 'Bu hasap häzir başga bir enjamda ulanylýar. Dowam etseňiz, öňki enjamdaky sessiýa awtomatik ýapylar.',
        ru: 'Этот аккаунт сейчас используется на другом устройстве. Если вы продолжите, сеанс на предыдущем устройстве будет автоматически завершён.',
        tr: 'Bu hesap şu anda başka bir cihazda kullanılıyor. Devam ederseniz, önceki cihazdaki oturum otomatik olarak kapatılacaktır.',
        en: 'This account is currently in use on another device. If you continue, the session on that device will be signed out automatically.',
      );
  static String get otherDeviceConfirm => t(
        tk: 'Dowam et, öňki enjamy çykar',
        ru: 'Продолжить, выйти на прошлом устройстве',
        tr: 'Devam et, önceki cihazdan çıkış yap',
        en: 'Continue, sign out other device',
      );
  static String get cancel =>
      t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç', en: 'Cancel');

  // ── Name entry ───────────────────────────────────────────────────────
  static String get nameEntryTitle => t(
      tk: 'Adyňyzy giriziň',
      ru: 'Введите ваше имя',
      tr: 'Adınızı girin',
      en: 'Enter your name');
  static String get nameEntrySubtitle => t(
        tk: 'Hasabyňyzy tamamlamak üçin adyňyzy ýazmaly.',
        ru: 'Чтобы завершить регистрацию, укажите своё имя.',
        tr: 'Hesabınızı tamamlamak için adınızı yazmalısınız.',
        en: 'Enter your name to finish setting up your account.',
      );
  static String get nameLabel =>
      t(tk: 'Adyňyz', ru: 'Ваше имя', tr: 'Adınız', en: 'Your name');
  static String get nameHint => t(
      tk: 'Meselem: Aýgül',
      ru: 'Например: Айгуль',
      tr: 'Örneğin: Aygül',
      en: 'E.g. Aygul');
  static String get continueButton =>
      t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et', en: 'Continue');

  // ── Welcome bonus (new-account signup only) ─────────────────────────────
  static String get welcomeBonusTitle => t(
      tk: 'Hoş geldiňiz! 🎉',
      ru: 'Добро пожаловать! 🎉',
      tr: 'Hoş geldin! 🎉',
      en: 'Welcome! 🎉');

  /// [amount] is the signed-in user's real balance right after signup
  /// (`GET /users/me`'s `balance`), not a hardcoded figure — the backend
  /// credits the welcome gift as part of account creation, so this always
  /// states what's actually sitting in the account rather than a number
  /// that could drift from whatever the backend is configured to grant.
  static String welcomeBonusBody(String amount) => t(
        tk: 'Sowgat hökmünde balansyňyza $amount TMT goşduk! Muny 1 hepdelik Plus abunalygyny satyn almak ýa-da bir kitap satyn alyp okamak üçin ulanyp bilersiňiz.',
        ru: 'Мы начислили $amount TMT на ваш баланс в подарок! Используйте их, чтобы купить недельную подписку Plus или один платный электронную книгу.',
        tr: 'Hediye olarak bakiyene $amount TMT ekledik! Bunu 1 haftalık Plus aboneliği satın almak ya da bir kitap satın alıp okumak için kullanabilirsin.',
        en: 'We added $amount TMT to your balance as a gift! Use it to get a 1-week Plus subscription or buy a book to read.',
      );
  static String get welcomeBonusCta =>
      t(tk: 'Başlaýyn!', ru: 'Начать', tr: 'Başlayalım!', en: 'Let\'s start!');
}
