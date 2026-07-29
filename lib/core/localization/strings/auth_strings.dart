import '../strings_base.dart';

/// Strings for the auth flow: [PhoneLoginScreen], [OtpVerifyScreen], and
/// [NameEntryScreen].
class AuthStrings {
  AuthStrings._();

  // ── Phone login ──────────────────────────────────────────────────────
  static String get phoneLoginTitle => t(tk: 'Giriş / Hasaba durmak', ru: 'Вход / Регистрация', tr: 'Giriş / Kayıt ol');
  static String get phoneLoginSubtitle => t(
        tk: 'Telefon belgiňizi giriziň, size SMS arkaly\ntassyklama kody ibereris.',
        ru: 'Введите свой номер телефона, мы отправим вам\nпроверочный код по SMS.',
        tr: 'Telefon numaranızı girin, size SMS ile\nonay kodu göndereceğiz.',
      );
  static String get phoneNumberLabel => t(tk: 'Telefon belgisi', ru: 'Номер телефона', tr: 'Telefon numarası');
  static String get phoneHint => t(tk: 'XX XX XX XX', ru: 'XX XX XX XX', tr: 'XX XX XX XX');

  static String get sendCodeButton => t(tk: 'SMS kod ibermek', ru: 'Отправить SMS-код', tr: 'SMS kodu gönder');
  static String get genericError => t(
        tk: 'Näbelli säwlik ýüze çykdy. Gaýtadan synanyşyň.',
        ru: 'Произошла неизвестная ошибка. Попробуйте снова.',
        tr: 'Bilinmeyen bir hata oluştu. Tekrar deneyin.',
      );
  static String get termsPrefix => t(tk: 'Dowam etmek bilen ', ru: 'Продолжая, вы соглашаетесь с ', tr: 'Devam ederek ');
  static String get termsLink => t(tk: 'Ulanyş Şertlerine', ru: 'Условиями использования', tr: 'Kullanım Şartları\'nı');
  static String get termsSuffix => t(tk: ' razylaşýarsyňyz.', ru: '.', tr: ' kabul etmiş olursunuz.');

  // ── OTP verify ───────────────────────────────────────────────────────
  static String get otpTitle => t(tk: 'Kody giriziň', ru: 'Введите код', tr: 'Kodu girin');
  static String get otpSentPrefix => t(tk: 'Şu belgä SMS iberdik: ', ru: 'Мы отправили SMS на номер: ', tr: 'Bu numaraya SMS gönderdik: ');
  static String get resendAction => t(tk: 'Kody täzeden iber', ru: 'Отправить код повторно', tr: 'Kodu tekrar gönder');
  static String get confirmButton => t(tk: 'Tassykla', ru: 'Подтвердить', tr: 'Onayla');
  static String get resendSnackbar => t(tk: 'Täze SMS kod iberildi', ru: 'Новый SMS-код отправлен', tr: 'Yeni SMS kodu gönderildi');
  static String get otherDeviceTitle => t(tk: 'Başga enjamda açyk', ru: 'Открыто на другом устройстве', tr: 'Başka bir cihazda açık');
  static String get otherDeviceBody => t(
        tk: 'Bu hasap häzir başga bir enjamda ulanylýar. Dowam etseňiz, öňki enjamdaky sessiýa awtomatik ýapylar.',
        ru: 'Этот аккаунт сейчас используется на другом устройстве. Если вы продолжите, сеанс на предыдущем устройстве будет автоматически завершён.',
        tr: 'Bu hesap şu anda başka bir cihazda kullanılıyor. Devam ederseniz, önceki cihazdaki oturum otomatik olarak kapatılacaktır.',
      );
  static String get otherDeviceConfirm => t(
        tk: 'Dowam et, öňki enjamy çykar',
        ru: 'Продолжить, выйти на прошлом устройстве',
        tr: 'Devam et, önceki cihazdan çıkış yap',
      );
  static String get cancel => t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç');

  // ── Name entry ───────────────────────────────────────────────────────
  static String get nameEntryTitle => t(tk: 'Adyňyzy giriziň', ru: 'Введите ваше имя', tr: 'Adınızı girin');
  static String get nameEntrySubtitle => t(
        tk: 'Hasabyňyzy tamamlamak üçin adyňyzy ýazmaly.',
        ru: 'Чтобы завершить регистрацию, укажите своё имя.',
        tr: 'Hesabınızı tamamlamak için adınızı yazmalısınız.',
      );
  static String get nameLabel => t(tk: 'Adyňyz', ru: 'Ваше имя', tr: 'Adınız');
  static String get nameHint => t(tk: 'Meselem: Aýgül', ru: 'Например: Айгуль', tr: 'Örneğin: Aygül');
  static String get continueButton => t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et');
}
