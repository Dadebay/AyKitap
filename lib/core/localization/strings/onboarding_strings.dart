import '../strings_base.dart';

/// Strings for [OnboardingScreen] — the 3 intro pages plus the skip/start
/// controls.
class OnboardingStrings {
  OnboardingStrings._();

  static String get skip =>
      t(tk: 'Geç', ru: 'Пропустить', tr: 'Geç', en: 'Skip');
  static String get start =>
      t(tk: 'Başla', ru: 'Начать', tr: 'Başla', en: 'Start');

  // ── Page 1 ───────────────────────────────────────────────────────────
  static String get page1Title => t(
      tk: '50,000+ kitap\nbir ýerde',
      ru: '50 000+ книг\nв одном месте',
      tr: '50.000+ kitap\nbir arada',
      en: '50,000+ books\nin one place');
  static String get page1Subtitle => t(
        tk: 'Türkmen, rus we iňlis dillerinde\nýüzlerçe kitap sizi garaşýar.',
        ru: 'Сотни книг на туркменском, русском\nи английском языках ждут вас.',
        tr: 'Türkmence, Rusça ve İngilizce\nyüzlerce kitap sizi bekliyor.',
        en: 'Hundreds of books in Turkmen, Russian\nand English are waiting for you.',
      );
  static String get page1Badge =>
      t(tk: '50K+', ru: '50K+', tr: '50K+', en: '50K+');
  static String get page1BadgeLabel =>
      t(tk: 'Kitap', ru: 'Книг', tr: 'Kitap', en: 'Books');

  // ── Page 2 ───────────────────────────────────────────────────────────
  static String get page2Title => t(
      tk: 'Okamak has\nkyn gerek',
      ru: 'Чтение не должно\nбыть трудным',
      tr: 'Okumak bu kadar\nzor olmamalı',
      en: 'Reading shouldn\'t\nbe hard');
  static String get page2Subtitle => t(
        tk: '6 dürli sahypa animasiýasy,\noffline okamak, şrift we tema saýlaň.',
        ru: '6 разных анимаций перелистывания,\nчтение офлайн, выбор шрифта и темы.',
        tr: '6 farklı sayfa animasyonu,\nçevrimdışı okuma, yazı tipi ve tema seçimi.',
        en: '6 different page-turn animations,\noffline reading, font and theme choices.',
      );
  static String get page2Badge => t(tk: '6', ru: '6', tr: '6', en: '6');
  static String get page2BadgeLabel =>
      t(tk: 'Animasiýa', ru: 'Анимаций', tr: 'Animasyon', en: 'Animations');

  // ── Page 3 ───────────────────────────────────────────────────────────
  static String get page3Title => t(
      tk: 'Her gün okaň,\nçempion boluň',
      ru: 'Читайте каждый день,\nстаньте чемпионом',
      tr: 'Her gün okuyun,\nşampiyon olun',
      en: 'Read every day,\nbecome a champion');
  static String get page3Subtitle => t(
        tk: 'Günde 10 min okasaňyz 🔥 alarsyňyz.\n30 günlük streak = 10 TMT bonus!',
        ru: 'Читайте по 10 минут в день и получите 🔥.\n30-дневная серия = бонус 10 TMT!',
        tr: 'Günde 10 dakika okursanız 🔥 kazanırsınız.\n30 günlük seri = 10 TMT bonus!',
        en: 'Read 10 minutes a day to earn 🔥.\n30-day streak = 10 TMT bonus!',
      );
  static String get page3Badge => t(tk: '🔥', ru: '🔥', tr: '🔥', en: '🔥');
  static String get page3BadgeLabel =>
      t(tk: 'Streak', ru: 'Серия', tr: 'Seri', en: 'Streak');
}
