import '../strings_base.dart';

/// User-facing fallback messages for failures that never supplied a safe,
/// localized backend message.
class ApiErrorStrings {
  ApiErrorStrings._();

  static String get requestTimedOut => t(
        tk: 'Soragyň wagty gutardy. Internet baglanyşygyňyzy barlaň.',
        ru: 'Время ожидания истекло. Проверьте подключение к интернету.',
        tr: 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
        en: 'The request timed out. Check your internet connection.',
      );

  static String get couldNotConnect => t(
        tk: 'Internete birigip bolmady.',
        ru: 'Не удалось подключиться к интернету.',
        tr: 'İnternete bağlanılamadı.',
        en: 'Could not connect to the internet.',
      );

  static String get unknownError => t(
        tk: 'Näbelli ýalňyşlyk ýüze çykdy.',
        ru: 'Произошла неизвестная ошибка.',
        tr: 'Bilinmeyen bir hata oluştu.',
        en: 'An unknown error occurred.',
      );

  /// Backend messages that arrive in English whatever the reader's language.
  /// The backend sends no error *code*, so these are matched on their text
  /// (loosely: casing and punctuation are ignored) and swapped for a
  /// localized message; null means "no translation known, show it as-is".
  ///
  /// To cover another English backend message, add a case here — every
  /// [ApiException] built from a server response goes through it.
  static String? localizeServerMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('subscription-only') || m.contains('subscription only')) {
      return subscriptionOnlyBook;
    }
    return null;
  }

  static String get subscriptionOnlyBook => t(
        tk: 'Bu kitap diňe abuna bilen elýeterli.',
        ru: 'Эта книга доступна только по подписке.',
        tr: 'Bu kitap yalnızca abonelikle okunabilir.',
        en: 'This book is available with a subscription only.',
      );
}
