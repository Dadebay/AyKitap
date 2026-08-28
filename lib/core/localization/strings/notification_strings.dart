import '../strings_base.dart';

/// Strings for the one-time notification-permission explanation dialog and
/// its Settings row.
class NotificationStrings {
  NotificationStrings._();

  static String get promptTitle => t(
        tk: 'Okamagy ýatlatmagymyza rugsat beriň',
        ru: 'Разрешите напоминать о чтении',
        tr: 'Okumayı hatırlatmamıza izin verin',
        en: 'Let us remind you to read',
      );
  static String get promptBody => t(
        tk: 'Streak-iňiz ýitmez ýaly, okap ýören kitabyňyzy dowam etdirmek üçin '
            'seýrek habarnamalar ibereris. Islän wagtyňyz Sazlamalardan '
            'öçürip bilersiňiz.',
        ru: 'Будем изредка напоминать вернуться к книге, чтобы не потерять '
            'серию чтения. Отключить можно в любой момент в Настройках.',
        tr: 'Serinizi kaybetmemeniz için okuduğunuz kitaba dönmenizi ara sıra '
            'hatırlatacağız. İstediğiniz zaman Ayarlar\'dan kapatabilirsiniz.',
        en: 'We\'ll send the occasional nudge to pick your book back up so you '
            'don\'t lose your streak. You can turn this off in Settings at any '
            'time.',
      );
  static String get promptAllow => t(
        tk: 'Rugsat ber',
        ru: 'Разрешить',
        tr: 'İzin ver',
        en: 'Allow',
      );
  static String get promptNotNow => t(
        tk: 'Häzir däl',
        ru: 'Не сейчас',
        tr: 'Şimdi değil',
        en: 'Not now',
      );

  // settings_screen.dart
  static String get settingsLabel => t(
        tk: 'Habarnamalar',
        ru: 'Уведомления',
        tr: 'Bildirimler',
        en: 'Notifications',
      );
  static String get statusOn =>
      t(tk: 'Açyk', ru: 'Включены', tr: 'Açık', en: 'On');

  /// The switch already says "off" — the subtitle's job is to say what turning
  /// it back on would get you, not to repeat the state.
  static String get settingsSubtitleOff => t(
        tk: 'Öçük — okamak ýatlatmalary gelmeýär',
        ru: 'Выключены — напоминания о чтении не приходят',
        tr: 'Kapalı — okuma hatırlatmaları gelmiyor',
        en: 'Off — no reading reminders',
      );

  /// Shown when the OS itself refused the prompt — on Android and iOS a
  /// second denial is final, and only the system settings page can undo it.
  static String get openSystemSettingsHint => t(
        tk: 'Habarnamalary telefonyň sazlamalaryndan açyp bilersiňiz.',
        ru: 'Уведомления можно включить в настройках телефона.',
        tr: 'Bildirimleri telefon ayarlarından açabilirsiniz.',
        en: 'You can turn notifications on from your phone\'s settings.',
      );
}
