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
}
