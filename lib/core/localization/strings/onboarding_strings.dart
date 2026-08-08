import '../strings_base.dart';

/// Strings for [OnboardingScreen] — the 3 intro pages plus the skip/start
/// controls.
class OnboardingStrings {
  OnboardingStrings._();

  static String get skip => t(tk: 'Geç', ru: 'Пропустить', tr: 'Geç');
  static String get start => t(tk: 'Başla', ru: 'Начать', tr: 'Başla');

  // ── Page 1 ───────────────────────────────────────────────────────────
  static String get page1Title => t(tk: '50,000+ kitap\nbir ýerde', ru: '50 000+ книг\nв одном месте', tr: '50.000+ kitap\nbir arada');
  static String get page1Subtitle => t(
        tk: 'Türkmen, rus we iňlis dillerinde\nýüzlerçe kitap sizi garaşýar.',
        ru: 'Сотни книг на туркменском, русском\nи английском языках ждут вас.',
        tr: 'Türkmence, Rusça ve İngilizce\nyüzlerce kitap sizi bekliyor.',
      );
  static String get page1Badge => t(tk: '50K+', ru: '50K+', tr: '50K+');
  static String get page1BadgeLabel => t(tk: 'Kitap', ru: 'Книг', tr: 'Kitap');

  // ── Page 2 ───────────────────────────────────────────────────────────
  static String get page2Title => t(tk: 'Okamak has\nkyn gerek', ru: 'Чтение не должно\nбыть трудным', tr: 'Okumak bu kadar\nzor olmamalı');
  static String get page2Subtitle => t(
        tk: '6 dürli sahypa animasiýasy,\noffline okamak, şrift we tema saýlaň.',
        ru: '6 разных анимаций перелистывания,\nчтение офлайн, выбор шрифта и темы.',
        tr: '6 farklı sayfa animasyonu,\nçevrimdışı okuma, yazı tipi ve tema seçimi.',
      );
  static String get page2Badge => t(tk: '6', ru: '6', tr: '6');
  static String get page2BadgeLabel => t(tk: 'Animasiýa', ru: 'Анимаций', tr: 'Animasyon');

  // ── Page 3 ───────────────────────────────────────────────────────────
  static String get page3Title => t(tk: 'Her gün okaň,\nçempion boluň', ru: 'Читайте каждый день,\nстаньте чемпионом', tr: 'Her gün okuyun,\nşampiyon olun');
  static String get page3Subtitle => t(
        tk: 'Günde 10 min okasaňyz 🔥 alarsyňyz.\n30 günlük streak = 10 TMT bonus!',
        ru: 'Читайте по 10 минут в день и получите 🔥.\n30-дневная серия = бонус 10 TMT!',
        tr: 'Günde 10 dakika okursanız 🔥 kazanırsınız.\n30 günlük seri = 10 TMT bonus!',
      );
  static String get page3Badge => t(tk: '🔥', ru: '🔥', tr: '🔥');
  static String get page3BadgeLabel => t(tk: 'Streak', ru: 'Серия', tr: 'Seri');
}
