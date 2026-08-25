import '../localization/app_locale.dart';

/// One row from `GET /book-languages` — a language a book can be written in
/// ("Türkmençe", "Iňlisçe", ...). Its `id` is what `GET /books/all` takes as
/// `language_id`.
///
/// Unlike [Genre], whose `name` comes back as a plain string, this endpoint
/// returns the name pre-translated into all three UI languages
/// (`{"ru": ..., "tk": ..., "tr": ...}`), so [label] picks the one matching
/// the app's current language instead of the backend deciding.
class BookLanguage {
  final int id;
  final String nameTk;
  final String nameRu;
  final String nameTr;

  const BookLanguage({
    required this.id,
    required this.nameTk,
    required this.nameRu,
    required this.nameTr,
  });

  /// The name in the app's current UI language, falling back to whichever
  /// translation the backend did fill in (Türkmen first, matching [t]'s own
  /// baseline) so a chip never renders blank.
  String get label {
    final preferred = switch (AppLocale.instance.current) {
      AppLanguageCode.tk => nameTk,
      AppLanguageCode.ru => nameRu,
      AppLanguageCode.tr => nameTr,
      // The backend's `GET /book-languages` response has no `en` name yet —
      // empty falls through to the same tk/tr/ru fallback chain below.
      AppLanguageCode.en => '',
    };
    if (preferred.isNotEmpty) return preferred;
    return [nameTk, nameTr, nameRu]
        .firstWhere((n) => n.isNotEmpty, orElse: () => '');
  }

  factory BookLanguage.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>? ?? const {};
    return BookLanguage(
      id: json['id'] as int,
      nameTk: name['tk'] as String? ?? '',
      nameRu: name['ru'] as String? ?? '',
      nameTr: name['tr'] as String? ?? '',
    );
  }
}
