# Aykitap — Refactoring Planı

> Bu doküman, Aykitap Flutter projesinin kod tabanı analizine dayanan, fazlar halinde uygulanacak
> bir refactoring talimatıdır. Amaç: davranışı ve görünümü **birebir koruyarak** kodu daha kısa,
> tekrarsız, SOLID uyumlu ve sürdürülebilir hale getirmek.
>
> **Uygulayıcı için altın kural: Bu bir refactor'dur. Hiçbir ekranın görünümü, animasyonu,
> metni veya davranışı değişmeyecek. Yeni özellik eklenmeyecek.**

---

## 0. Mevcut Durum Özeti (analiz sonucu)

- **10.672 satır**, 60 dart dosyası (`lib/` altında). En büyükler:
  - `lib/modules/home/home_screen.dart` — **781 satır** (12+ private class aynı dosyada)
  - `lib/modules/book_detail/book_detail_screen.dart` — 509
  - `lib/modules/library/library_screen.dart` — 480 (13 class aynı dosyada)
  - `lib/modules/main_nav/main_nav_screen.dart` — 433
  - `lib/modules/profile/settings_screen.dart` — 392, `filter_screen.dart` — 392
  - `lib/modules/profile/profile_screen.dart` — 361, `onboarding_screen.dart` — 344
  - `lib/core/models/book.dart` — 338 (model + 196 satır MockData karışık → SRP ihlali)
- **State management karışık:** Sadece reader modülü Provider kullanıyor. Geri kalan her şey
  `setState` (57 kullanım) + singleton `ChangeNotifier`'lar (`StreakService.instance` gibi)
  + `ListenableBuilder`. `provider` paketi zaten pubspec'te var ama app kökünde `MultiProvider` yok.
- **Tekrarlar:**
  - 10 dosyada birbirinin kopyası `TextField` + `Container(decoration: ...)` sarmalayıcısı
  - 14 dosyada aynı `ElevatedButton` (height 56, borderRadius 16, primary bg) kalıbı
  - 50 `GestureDetector`, 118 `BorderRadius.circular(...)`, 163 `SizedBox(height: ...)`
  - 42 `Navigator.push(context, MaterialPageRoute(builder: ...))` tekrarı
  - `LinearGradient(colors: [Color(0xFFF77E68), Color(0xFFB44BE8)])` 4+ yerde kopyala-yapıştır
  - `app_colors.dart` dışında **60+ hardcoded `Color(0x...)`** kullanımı
  - `_BookCard` home_screen içinde private; benzer kapak/kart çizimleri library, search,
    author, popular, book_detail ekranlarında ayrı ayrı yeniden yazılmış
  - 10 dosyada ham `ScaffoldMessenger.of(context).showSnackBar(...)` tekrarı
- **Kullanılmayan bağımlılıklar** (lib/ altında 0 import): `shimmer`, `cached_network_image`,
  `http`, `dio`, `archive`. (`webview_flutter` da lib'de 0 import — ama
  `packages/flutter_epub_viewer` kendi pubspec'inde bildiriyorsa app pubspec'inden kaldırılabilir,
  build alınarak doğrulanmalı.)
- **İyi durumda olanlar (dokunma / bozma):**
  - `core/localization` yapısı (modül başına `XxxStrings` + `t(tk/ru/tr)`) temiz — **aynen korunacak**
  - `AppColors` (dark/light getter'lı) yaklaşımı pragmatik — korunacak, sadece genişletilecek
  - Servislerdeki açıklayıcı yorumlar korunacak
  - `flutter_epub_viewer` local paketi bu refactor'un **kapsamı dışında**

---

## 1. Hedefler ve Kesin Kurallar

1. **Dosya boyutu:** `lib/modules/` altındaki hiçbir dosya **250 satırı geçmeyecek** (hedef ~200).
   Ekran dosyası sadece iskelet + kompozisyon içerir; parçalar `widgets/` alt klasörüne taşınır.
2. **DRY / Tek kaynak:** Tekrarlanan her UI kalıbı `core/widgets/` altında TEK widget olur,
   her yerde o kullanılır. Refactor sonunda `lib/modules` altında ham `TextField(`,
   ham `ElevatedButton(`, ham `MaterialPageRoute(` **kalmayacak**.
3. **Renk/gradient/spacing token'ları:** `Color(0x...)` sadece `core/theme/` altında yazılabilir.
   Boşluk ve radius değerleri `core/constants/` sabitlerinden gelir.
4. **State management:** Provider standardı. Kökte `MultiProvider`; paylaşılan state
   `context.watch/read/select` ile okunur. `setState` yalnızca ekrana özel geçici UI state'i
   (focus, toggle, animasyon) için kalır.
5. **SOLID:**
   - **S**: Model dosyası model içerir; mock veri ayrı dosyaya; ekran dosyası sadece kompozisyon.
   - **O/D**: Veri erişimi `BookRepository` arayüzü üzerinden; bugün `MockBookRepository`,
     yarın gerçek API implementasyonu takılabilir — ekranlar değişmez.
   - **I**: Dev widget'lar küçük, tek işli widget'lara bölünür.
6. **Davranış birebir korunur.** Şüphede kalırsan görünümü değiştirme, refactor'u küçült.
7. Yeni paket **eklenmeyecek** (mevcut `provider` yeterli).

---

## 2. Faz 0 — Güvenlik Ağı ve Temizlik


4. `analysis_options.yaml`'a şu lint'leri ekle (mevcut `flutter_lints` üstüne):
   ```yaml
   linter:
     rules:
       - prefer_const_constructors
       - prefer_const_literals_to_create_immutables
       - prefer_final_locals
       - avoid_redundant_argument_values
       - directives_ordering
       - sized_box_for_whitespace
       - use_decorated_box
   ```

---

## 3. Faz 1 — Design Token'ları (`core/constants` + `core/theme`)

Yeni dosyalar:

```
lib/core/constants/app_spacing.dart
lib/core/constants/app_radius.dart
lib/core/theme/app_gradients.dart
lib/core/theme/app_text_styles.dart
```

### 3.1 `app_spacing.dart`
```dart
/// Tüm boşluk değerleri buradan gelir; ekranlarda çıplak sayı kullanılmaz.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Ekranların standart yatay içerik dolgusu.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
}
```

### 3.2 `app_radius.dart`
```dart
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brXl = BorderRadius.circular(xl);
}
```

### 3.3 `app_gradients.dart`
Kod tabanındaki tüm tekrar eden gradientler tek yerde:
```dart
abstract final class AppGradients {
  /// Auth ekranlarındaki ikon rozetleri + BookTok koleksiyon kartı (coral → purple).
  static const LinearGradient coralPurple =
      LinearGradient(colors: [Color(0xFFF77E68), Color(0xFFB44BE8)]);
  // ... grep ile bulunan diğer tekrar eden gradientler buraya
}
```

### 3.4 `app_text_styles.dart`
En sık tekrar eden `TextStyle` kalıpları (ör. `fontSize: 17, w700` başlıklar,
`grey2 fontSize: 12.5` alt başlıklar) isimli getter olur:
```dart
abstract final class AppTextStyles {
  static TextStyle get screenTitle => TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800);
  static TextStyle get sectionTitle => TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700);
  static TextStyle get sectionSubtitle => TextStyle(color: AppColors.grey2, fontSize: 12.5);
  static TextStyle get body => TextStyle(color: AppColors.grey2, fontSize: 14.5, height: 1.5);
  static TextStyle get label => TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600);
  static TextStyle get link => TextStyle(color: AppColors.primary, fontSize: 13);
  // AppColors gibi getter olmalı ki dark/light geçişinde doğru renk gelsin.
}
```

### 3.5 Hardcoded renk temizliği
`app_colors.dart` dışındaki 60+ `Color(0x...)`:
- Anlamlı ve tekrar edenler → `AppColors`'a isimli getter olarak taşı
  (ör. `0xFFE86B2C` zaten `primary`'nin varyantı — mevcut token'a bağla).
- MockData kapak renkleri (`_coverColors`) mock veri olduğu için MockData içinde kalabilir.
- Tamamlanınca kontrol: `grep -rn "Color(0x" lib --include="*.dart" | grep -v "core/theme" | grep -v "mock_data"`
  → yalnızca bilinçli istisnalar kalmalı (her istisna için satır içi kısa gerekçe yorumu yaz).

---

## 4. Faz 2 — Ortak Widget Kütüphanesi (`core/widgets`)

> Kuralın özü: "10 TextField yerine 1 custom widget, 10 yerde kullanım."
> Her widget kendi dosyasında, tek işli, parametrik.

```
lib/core/widgets/
  app_text_field.dart      // 10 dosyadaki input kalıbının teki
  primary_button.dart      // 14 dosyadaki 56px buton kalıbının teki
  gradient_icon_badge.dart // auth ekranlarındaki 64x64 gradient ikon kutusu
  section_header.dart      // home'daki başlık + "Ählisi" satırı
  book_cover.dart          // kapak görseli: Image.asset + coverColor fallback + radius
  book_card.dart           // home'daki _BookCard buraya taşınır, public olur
  app_bottom_sheet.dart    // showModalBottomSheet sarmalayıcısı (ortak şekil/renk)
  app_snackbar.dart        // context.showAppSnackBar('...') extension'ı
  icon_circle_button.dart  // _IconBtn / _RoundIconBtn birleşimi
  empty_state.dart         // library'deki _EmptyState buraya, public olur
  settings_tile.dart       // settings/profile'daki satır kalıbı
  app_back_button.dart     // her ekranda tekrarlanan geri ok IconButton'ı
```

Mevcut `core/widgets/` içindeki `streak_flame.dart`, `streak_week_row.dart`,
`profile_avatar.dart` olduğu gibi kalır.

### 4.1 `AppTextField` — referans implementasyon
Mevcut 10 kullanımın ortak paydası (56px, card bg, 16 radius, focus'ta primary border):
```dart
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint,
    this.label,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefix,          // ör. telefon ekranındaki bayrak + '+993' bölümü
    this.maxLines = 1,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });
  // ...alanlar...

  @override
  Widget build(BuildContext context) {
    final field = /* mevcut Container(height:56, card bg, AppRadius.brLg,
                      focus'ta primary border) + içinde TextField deseni */;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [Text(label!, style: AppTextStyles.label), field],
    );
  }
}
```
- Focus border değişimi için widget kendi içinde `ListenableBuilder(listenable: focusNode)`
  kullanmalı — böylece ekranlardaki `onTap: () => setState(() {})` hack'leri silinir.
- OTP kutuları gibi gerçekten farklı olan inputlar zorla bu widget'a sokulmaz;
  onlar kendi modül `widgets/` klasöründe kalır.

### 4.2 `PrimaryButton` — referans implementasyon
```dart
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed, // null → disabled görünüm (mevcut davranış)
    this.loading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Text(label, style: TextStyle(
                color: onPressed != null ? Colors.white : AppColors.grey3,
                fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
```
Kullanım — `phone_login_screen.dart`'taki 18 satır şuna iner:
```dart
PrimaryButton(label: AuthStrings.sendCodeButton, loading: _sending, onPressed: _isValid ? _sendCode : null)
```

### 4.3 `GradientIconBadge`
Kullanıcının örneğindeki 12 satırlık blok tek satıra iner:
```dart
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({super.key, required this.icon, this.size = 64,
      this.gradient = AppGradients.coralPurple});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(gradient: gradient, borderRadius: AppRadius.brXl),
        child: Center(child: HugeIcon(icon: icon, color: Colors.white, size: size * 0.47)),
      );
}
// Kullanım: GradientIconBadge(icon: HugeIcons.strokeRoundedSmartPhone01)
```

### 4.4 `SectionHeader`
`home_screen.dart`'ta 4 kez kopyalanan "başlık + alt başlık + Ählisi linki" satırı:
```dart
SectionHeader(title: ..., subtitle: ..., onSeeAll: ...)
```

### 4.5 `app_snackbar.dart`
```dart
extension AppSnackBar on BuildContext {
  void showAppSnackBar(String message) { /* mevcut ortak stil */ }
}
```
10 dosyadaki ham `ScaffoldMessenger...` çağrıları bununla değiştirilir.

### 4.6 Dokunulabilirlik
Kart/liste öğelerindeki 50 `GestureDetector` görünümü değiştirmeden kalabilir;
ancak yeni ortak widget'ların (`BookCard`, `SettingsTile` vb.) `onTap` parametresi olmalı,
böylece ekranlarda ayrıca `GestureDetector` sarmaya gerek kalmaz.

---

## 5. Faz 3 — Boşluk (Spacing) Modernizasyonu

**Soru: "SizedBox yerine margin kullansam daha az kod olmaz mı?"**
**Cevap: Hayır — `Container(margin:)` daha fazla nesne ve daha fazla satır demek. Doğru modern
çözüm Flutter 3.27+ ile gelen `Column`/`Row` `spacing` parametresidir** (projede Flutter 3.41 var):

```dart
// ÖNCE (163 adet SizedBox'ın kaynağı):
Column(children: [
  const SizedBox(height: 12),
  GradientIconBadge(...),
  const SizedBox(height: 24),
  Text(...),
  const SizedBox(height: 8),
  Text(...),
])

// SONRA:
Column(
  spacing: AppSpacing.md, // elemanlar arası standart boşluk
  children: [GradientIconBadge(...), Text(...), Text(...)],
)
```

Kurallar:
- Bir `Column`/`Row` içindeki `SizedBox(height/width: n)`'lerin **çoğu aynı değerdeyse**
  → `spacing: n` kullan, aykırı tekiller için `SizedBox` bırakılabilir veya `Padding` kullan.
- Kenar boşluğu (dış kenarlardan) → `Padding` (tercihen `AppSpacing.screenPadding`).
- `Container` sadece `decoration` gerektiğinde; sadece boşluk için asla.
- Değerler `AppSpacing` sabitlerinden gelir; `SizedBox(height: 13.7)` gibi tekil değerler
  en yakın token'a yuvarlanmaz — **görünüm korunur**, olduğu gibi bırakılır.

---

## 6. Faz 4 — Model / Veri Katmanı Ayrımı (SRP + DIP)

```
lib/core/models/book.dart        → SADECE modeller (Book, Author, BookSeries,
                                    BookCollection, HomeSection, BookFormat) (~140 satır)
lib/core/data/mock/mock_data.dart → MockData sınıfı buraya taşınır (~200 satır)
lib/core/data/book_repository.dart:

abstract interface class BookRepository {
  List<HomeSection> homeSections();
  List<Book> booksForSection(HomeSection section, {int count});
  List<Book> popularBooks();
  List<BookCollection> collections();
  List<BookSeries> series();
  List<Author> authors();
  List<Book> search(String query);
}

lib/core/data/mock_book_repository.dart → MockData'ya delege eden implementasyon
```

- Ekranlar `MockData.generateBooks(...)` yerine repository'den okur (Provider ile inject:
  `Provider<BookRepository>(create: (_) => MockBookRepository())`).
- Böylece gerçek API geldiğinde sadece yeni bir `ApiBookRepository` yazılır (**Open/Closed**),
  hiçbir ekran dosyası değişmez (**Dependency Inversion**).
- `Book.toJson/fromJson` yorumlarıyla birlikte modelde kalır.

---

## 7. Faz 5 — State Management Standardizasyonu (Provider)

### 7.1 Kök kurulum (`main.dart`)
Mevcut `ListenableBuilder(Listenable.merge([...]))` yerine:
```dart
runApp(MultiProvider(
  providers: [
    ChangeNotifierProvider<AppTheme>.value(value: AppTheme.instance),
    ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
    ChangeNotifierProvider<StreakService>.value(value: StreakService.instance),
    ChangeNotifierProvider<SubscriptionService>.value(value: SubscriptionService.instance),
    ChangeNotifierProvider<NotesStore>.value(value: NotesStore.instance),
    ChangeNotifierProvider<PurchasedBooksStore>.value(value: PurchasedBooksStore.instance),
    ChangeNotifierProvider<OwnBooksStore>.value(value: OwnBooksStore.instance),
    Provider<BookRepository>(create: (_) => MockBookRepository()),
  ],
  child: const AykitapApp(),
));
```
- `AykitapApp.build` içinde `context.watch<AppTheme>()` + `context.watch<AppLocale>()` —
  tema/dil değişince tüm app yeniden kurulur (mevcut davranışla aynı; `main.dart`'taki
  açıklayıcı yorum korunur).
- **Geçiş stratejisi (düşük risk):** Singleton'lar (`.instance`) bu fazda silinmez;
  `.value` ile Provider'a bağlanır. Widget'lar içindeki `ListenableBuilder(listenable:
  XxxService.instance)` kalıpları `context.watch<XxxService>()` / `Consumer` ile değiştirilir.
- Store'larda `.instance` yoksa (kontrol et) aynı kalıba uydur.

### 7.2 Ekran kuralları
- **Yerel geçici UI state** (tab index, focus, animasyon, geçici toggle) → `setState` KALIR.
  Bunları Provider'a taşımak over-engineering'dir; yapma.
- **Paylaşılan/kalıcı state** (streak, satın alınanlar, notlar, abonelik, tema, dil)
  → yalnızca Provider üzerinden okunur. Ekranlarda doğrudan `XxxService.instance` çağrısı kalmamalı.
- **İş mantığı içeren karmaşık ekranlar** için ekran-başı controller çıkar
  (dosya: `modules/<x>/controller/<x>_controller.dart`, `ChangeNotifier`,
  `ChangeNotifierProvider` ile ekrana bağlanır). Bunu SADECE şunlara uygula:
  - `auth/` akışı: telefon formatlama, OTP sayacı, doğrulama mantığı controller'a
  - `filter_screen.dart`: filtre seçim state'i
  - `edit_profile_screen.dart`: avatar/isim kaydetme mantığı
  Diğer ekranlarda mevcut `setState` yeterli — zorla controller üretme.
- Reader modülü zaten Provider kullanıyor — yalnızca isim/dizin tutarlılığı için gözden geçir,
  davranışına dokunma.

---

## 8. Faz 6 — Navigasyon Yardımcısı

42 adet `Navigator.push(context, MaterialPageRoute(builder: (_) => X()))` tekrarı için
`lib/core/navigation/app_navigator.dart`:
```dart
extension AppNavigator on BuildContext {
  Future<T?> push<T>(Widget screen) =>
      Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));

  void pop<T>([T? result]) => Navigator.pop(this, result);
}
// Kullanım: context.push(BookDetailScreen(book: book));
```
- Named-route / go_router'a GEÇME — bu app için gereksiz; sadece tekrarı öldür.
- Reader'daki `ChangeNotifierProvider.value` ile sarılan özel push'lar olduğu gibi kalabilir.

---

## 9. Faz 7 — Büyük Dosyaların Bölünmesi (≤ 200-250 satır)

Desen: her modülde ekran dosyası iskelet olur, parçalar `widgets/` alt klasörüne gider.
Private `_Xxx` class'ları taşınırken public yapılır (`_BookCard` → `BookCard` vb.).

| Kaynak dosya | Bölünme |
|---|---|
| `home_screen.dart` (781) | `home_screen.dart` (~150: Scaffold + sliver listesi) + `widgets/home_header.dart`, `widgets/banner_carousel.dart`, `widgets/rank_shelf_card.dart` (`_RankShelf` modeliyle), `widgets/collection_card.dart`, `widgets/author_avatar.dart`, `widgets/home_section_row.dart` (`_buildSection` + `SectionHeader` kullanımı). `_BookCard` → `core/widgets/book_card.dart` |
| `book_detail_screen.dart` (509) | ekran + `widgets/detail_meta_bar.dart` (`_MetaStat`, `_MetaDivider`), `widgets/genre_tag.dart`, `widgets/mini_book_card.dart`; `_RoundIconBtn` → `core/widgets/icon_circle_button.dart` ile birleşir |
| `library_screen.dart` (480) | ekran (~120) + `widgets/shelf_grid.dart` (`_ShelfGrid`, `_ShelfRow`, `_ShelfBookCover`, `_CornerBadge`), `widgets/library_tabs.dart` (Reading/Downloaded/Purchased/Own tab'ları), `_EmptyState` → `core/widgets/empty_state.dart` |
| `main_nav_screen.dart` (433) | ekran + `widgets/wheel_nav_bar.dart` (`_WheelNavBar` + `_DiskPainter` birlikte — birbirine sıkı bağlılar, ayırma) |
| `settings_screen.dart` (392) | ekran + `widgets/` (dil seçici sheet, tema satırı vb.); satır kalıbı → `core/widgets/settings_tile.dart` |
| `filter_screen.dart` (392) | ekran + `widgets/filter_chips.dart` vb. + `controller/filter_controller.dart` |
| `profile_screen.dart` (361) | ekran + `widgets/profile_header.dart`, `widgets/profile_menu.dart` |
| `onboarding_screen.dart` (344) | ekran + `widgets/onboarding_page.dart` |
| `notes_screen.dart` (321) | ekran + `widgets/note_card.dart`, not ekleme sheet'i ayrı dosya |
| `otp_verify_screen.dart` (302) | ekran + `widgets/otp_code_row.dart` + controller |
| `splash_screen.dart` (299) | ekran + `widgets/` (logo/animasyon parçaları) |
| `edit_profile_screen.dart` (286) | ekran + `widgets/avatar_picker.dart` |
| `subscription_screen.dart` (260) | ekran + `widgets/plan_card.dart` |
| `book.dart` (338) | Faz 4'te zaten bölündü |

Kurallar:
- Bölme SADECE taşıma + public yapma + import düzeltmedir; widget ağacı değişmez.
- Bir parçayı taşırken önce `core/widgets`'ta genel karşılığı var mı diye bak
  (ör. kapak çizimi → `BookCover`); varsa onu kullan, yoksa modülün `widgets/`'ına koy.
- İki modül aynı parçayı kullanıyorsa parça `core/widgets`'a çıkar
  (`SeriesCard` şu an `all_series_screen.dart` içinde tanımlı ve home da kullanıyor →
  `core/widgets/series_card.dart`'a taşı).

---

## 10. Faz 8 — Son Kontrol ve Kabul Kriterleri

Her fazdan sonra ve en sonda:

```bash
flutter analyze                 # 0 issue
flutter test                    # mevcut boot testi geçmeli
flutter build ios --no-codesign --debug   # veya: flutter build apk --debug
```

Grep tabanlı kabul kriterleri (hepsi boş/istisnasız dönmeli):
```bash
# 1) modules altında ham TextField kalmadı (AppTextField hariç):
grep -rn "TextField(" lib/modules --include="*.dart" | grep -v "AppTextField"
# 2) modules altında ham ElevatedButton kalmadı:
grep -rn "ElevatedButton(" lib/modules --include="*.dart"
# 3) modules altında MaterialPageRoute kalmadı:
grep -rn "MaterialPageRoute" lib/modules --include="*.dart"
# 4) theme/mock dışında hardcoded renk kalmadı:
grep -rn "Color(0x" lib --include="*.dart" | grep -v "core/theme" | grep -v "mock"
# 5) 250 satırı aşan modül dosyası kalmadı:
find lib/modules -name "*.dart" | xargs wc -l | awk '$1 > 250 && $2 != "total"'
# 6) Widget içinden doğrudan singleton erişimi kalmadı:
grep -rn "\.instance" lib/modules --include="*.dart"
```

Manuel doğrulama (simülatörde):
- Onboarding → telefon girişi → OTP → isim → ana ekran akışı çalışıyor
- Home'daki tüm carousel/section'lar aynı görünüyor
- Tema (dark/light) ve dil (tk/ru/tr) değiştirme tüm ekranları güncelliyor
- Kitap detay → satın alma → kütüphane akışı çalışıyor
- EPUB/PDF okuyucu açılıyor, streak sayacı ilerliyor

---

## 11. Yapılmayacaklar (bilinçli kararlar)

- **go_router / bloc / riverpod / get_it eklenmeyecek** — mevcut ölçek için Provider yeterli.
- **`AppColors`'ın static-getter yaklaşımı `ThemeExtension`'a çevrilmeyecek** — çalışıyor,
  tema geçişi app kökünden rebuild ile çözülmüş durumda; büyük risk, sıfır kullanıcı faydası.
- **Lokalizasyon `intl/arb`'a taşınmayacak** — mevcut `t(tk/ru/tr)` yapısı bu proje için
  daha okunur ve çevirmen ekibi yok.
- **`flutter_epub_viewer` local paketi refactor edilmeyecek.**
- **Mock veri "gerçekçi" hale getirilmeyecek** — sadece dosya olarak taşınacak.

## 12. Uygulama Sırası ve Commit Planı

| # | Faz | Commit mesajı |
|---|---|---|
| 1 | Faz 0 | `chore: git baseline, drop unused deps, tighten lints` |
| 2 | Faz 1 | `refactor(core): add spacing/radius/gradient/text-style tokens` |
| 3 | Faz 2 | `refactor(core): shared widget library (AppTextField, PrimaryButton, ...)` |
| 4 | Faz 3 | `refactor(ui): replace SizedBox spacers with Column/Row spacing tokens` |
| 5 | Faz 4 | `refactor(data): split models from MockData, add BookRepository` |
| 6 | Faz 5 | `refactor(state): root MultiProvider, screens read services via Provider` |
| 7 | Faz 6 | `refactor(nav): context.push extension, remove raw MaterialPageRoute` |
| 8 | Faz 7 | `refactor(modules): split oversized screens into widgets/ (<250 lines)` |
| 9 | Faz 8 | `chore: final analyze/test/build verification` |

Her adımda: değişiklik → `flutter analyze` → uygulamayı aç, 2-3 ekran gez → commit.
Bir faz tamamlanmadan sonrakine geçme.
