# Aýkitap

Türkmen dilindäki mobil kitaphana — Flutter bilen ýazylan e-kitap okamak programmasy.
EPUB, PDF we CBZ formatlaryny goldaýar; kitap gözlemek, satyn almak/abuna ýazylmak,
internetsiz okamak we okaýyş statistikasy ýaly mümkinçilikleri bar.

**Platformalar:** Android (`com.aykitap.aykitap`) we iOS (`com.aykitap.aykitap`, minimum iOS 15.6)
**Dart SDK:** `>=3.6.0 <4.0.0` · **State management:** Provider · **Wersiýa:** `1.0.0+1`

---

## Mümkinçilikler

### Okyjy (reader)
Üç sany aýry okyjy bar, her formatyň öz talabyna görä:

| Format | Ekran | Nähili işleýär |
|---|---|---|
| EPUB | `reader_view.dart` | `sakura_epub` (epub.js + WebView) — tekst gaýtadan ýerleşýär |
| PDF | `pdf_reader_screen.dart` | Native PDFium (`flutter_pdfview`) — asyl sahypa suratlary |
| CBZ | `cbz_reader_screen.dart` | Arhiwden çykarylan sahypa suratlary (manga üçin) |

- **PDF-den tekste geçmek** — tekst gatlagy bar PDF-i bir gezek EPUB-a öwrüp
  ([`PdfReflowService`](lib/core/services/pdf_reflow_service.dart)), şol bir gaýtadan
  ýerleşýän okyjyda açmak: şrift, tema, bellikler, gözleg — hemmesi işleýär.
  **Deslapky görnüş — asyl PDF sahypalary**; tekst görnüşi "Sazlamalar → Tekst görnüşi"
  arkaly saýlanýar. Skanirlenen (diňe surat) PDF-lerde öwürjek tekst ýok, şonuň üçin
  olar hemişe sahypa görnüşinde galýar.
- Reňk tertibi (Ak / Sary / Gijr), sahypa ölçegi, ekranyň ýagtylygy, göz goraýyş (gök
  ýagtylyk süzgüji), sahypalap ýa-da dowamly aýlaw
- Bellikler (bookmark), alyntylar we notlar, kitabyň içinde gözleg, bölüm sanawy
- Okalan ýer we prosent awtomatiki ýatda saklanýar

### Kitaphana we gözleg
- **Kitaplyk** — Okaýanlarym / Okap gutaranlarym / Ýüklenenler / Satyn Alnanlar /
  Halaýanlarym / Öz kitaplarym
- **Gözleg** — kitap ýa-da ýazar boýunça, žanr çipleri, doly filtr sahypasy
  (žanr, dil, format, çap senesi, tertip), aşak aýlanyňda indiki sahypa awtomatiki
  ýüklenýär
- **Baş sahypa** — kolleksiýalar, bannerler, žanrlar, ýazarlar
- Öz kitabyňy açmak: telefondan faýl saýlap ýa-da başga programmadan "Open with"
  arkaly (Android `MainActivity.kt`, iOS `AppDelegate.swift`)

### Hasap, töleg we abunalyk
- Telefon belgisi + SMS kod (OTP) bilen giriş
- Balans doldurmak — bank karty (`PaymentWebViewScreen`) ýa-da promo kod
  (`PaymentMethodSheet` haýsysydygyny soraýar)
- Kitaby aýratyn satyn almak ýa-da abuna ýazylmak
- **Elýeterlilik düzgüni** ([`BookAccessService`](lib/core/services/book_access_service.dart)):
  `satyn alnan > abunalyk > satyn al > balans doldur`.
  Satyn alnan kitap hemişe okalýar; abunalyk arkaly açylan kitap abunalyk gutaranda ýapylýar.

### Okaýyş yzygiderliligi (streak)
Okap oturan wagtyň her 60 sekuntda serwere habar berilýär (`POST /streaks/report`);
gündelik maksat, iň gowy netije, sowgatlar (balans / mugt abunalyk) —
[`StreakService`](lib/core/services/streak_service.dart).

### Işjeňlik statistikasy (app-activity)
Programmada geçirilen umumy foreground wagty (`POST /users/app-activity`) —
admin panelindäki "Iň işjeň ulanyjylar" sanawy şundan gelýär. Streak-den
tapawudy: ol diňe **okaýyş** wagtyny, bu bolsa **islendik ekrandaky** wagty
hasaplaýar. [`AppActivityService`](lib/core/services/app_activity_service.dart).

Programma agram salmaz ýaly gurlan — nobat (queue) ýok, retry loop ýok,
background service ýok. Ýatda saklanýan zat: **bir integer we bir taýmer**.

- Her 60 sekuntda bir hasabat (ýygy ibermegiň peýdasy ýok — serwer 15 sekuntdan
  ýygy gelenleri sanamaýar, klient hem şoňa görä ibermeýär)
- Şowsuz bolsa aýratyn request ýatda saklanmaýar, diňe san goşulýar; bir hepde
  offline bolsaň hem ýat bir integer bolup galýar we birikeniňde **bir** request
  bilen gidýär
- Jogaby näbelli (timeout) hasabat gaýtalanmaýar — serwerde dublikat aýyrma ýok,
  gaýtalasaň iki gezek sanalardy
- **Hereketsizlik barlagy:** 10 minutlap hiç hili degme bolmasa sagat durýar
  (okyjy ekrany açyk goýlup ýatylsa statistika çişmesin diýip). Degen badyňa
  ýene işläp başlaýar.

### Beýlekiler
- **Üç dil:** Türkmen (tk), Rus (ru), Türk (tr) — modul boýunça bölünen
  `core/localization/strings/`. Dil çalşylanda `Accept-Language` header hem
  üýtgeýär, ýagny serwerden gelýän kitap atlary/žanrlar hem terjime bolýar.
- Garaňky / ýagty tema
- Firebase Analytics we push habarnamalar (Firebase Messaging + lokal habarnamalar)
- Internetsiz işlemek: ýüklenen faýllar, satyn alnanlaryň sanawy we soňky okalan
  kitap enjamda saklanýar

---

## Arhitektura

```
lib/
├── core/
│   ├── localization/   # t(tk:, ru:, tr:) — modul boýunça setirler
│   ├── models/         # API jogaplarynyň Dart modelleri
│   ├── navigation/     # context.push(), rootNavigatorKey
│   ├── network/        # DioClient, ApiEndpoints, ApiConfig, ApiException
│   ├── services/       # API hyzmatlary + ýerli ammarlar (aşakda serediň)
│   ├── theme/          # AppColors, AppTheme
│   └── widgets/        # Umumy widgetler (snackbar, cover image, ...)
├── modules/            # Her ekran öz bukjasynda
│   ├── auth/  author/  book_detail/  filter/  home/  library/
│   ├── main_nav/  onboarding/  payment/  profile/
│   └── reader/  search/  splash/  streak/
└── main.dart           # MultiProvider + MaterialApp
packages/
├── sakura_epub/        # EPUB okyjy (epub.js + inappwebview)
└── flutter_pdfview/    # pub-daky 1.4.4-iň üýtgedilen nusgasy (aşakda serediň)
```

### State management — Provider

[`main.dart`](lib/main.dart) 16 sany `ChangeNotifier` hyzmatyny `MultiProvider`-e
`.value` bilen berýär. Hemmesi singleton (`Xxx.instance`), sebäbi olara widget
agajyndan daşarda hem ýüzlenilýär (mysal üçin native "Open with" callback-i).

**Möhüm düzgün:** widget `build()` içinde hyzmatyň maglumatyny okajak bolsaň,
`Xxx.instance` diýip däl-de, **`context.watch<Xxx>()`** arkaly oka. Ýogsam
`notifyListeners()` işläninde ol widget täzelenmeýär — daşyndan bildirmeýän, tapmasy
kyn ýalňyşlyk. (Diňe callback-iň içinde giç ulanylýan bolsa `.instance` dogry.)

Esasy hyzmatlar:

| Hyzmat | Işi |
|---|---|
| `AccountService` | `/users/me` — ulanyjy, balans |
| `SubscriptionService` | Abunalygyň möhleti, satyn almak |
| `BookAccessService` | Kim haýsy kitaby okap bilýär (ýokardaky düzgün) |
| `BookDownloadService` | Faýl ýüklemek + prosent (kitap id boýunça) |
| `DownloadedFilesStore` / `DownloadedBooksStore` | Enjamdaky faýllar we tekje |
| `ReadingBooksStore` / `LastReadBookStore` | Okalýanlar, soňky okalan ýer |
| `NotesStore` / `BookmarksStore` | Bellikler we notlar |
| `HomeDataService` | Baş sahypanyň maglumatlary |
| `StreakService` | Okaýyş yzygiderliligi |
| `OwnBooksStore` | Ulanyjynyň öz import eden faýllary |

### Network

Ähli soraglar bir [`DioClient`](lib/core/network/dio_client.dart) arkaly geçýär:
bearer token, `Accept-Language`, we 401 gelende awtomatiki çykyş + login ekrany
([`SessionExpiryHandler`](lib/core/services/session_expiry_handler.dart)).

API salgysy [`api_config.dart`](lib/core/network/api_config.dart) faýlynda:

```dart
baseUrl      = '<PRIVATE_API_ENDPOINT>'  // API
mediaBaseUrl = '<PRIVATE_MEDIA_ENDPOINT>'         // suratlar/faýllar
```

---

## Üýtgedilen (vendored) paketler

`packages/` içindäkiler pub-dan göçürilip, üstünde düzediş edilen nusgalar.
**Pub-daky wersiýa täzelenende bu düzedişler awtomatiki gelmez** — el bilen
göçürmeli.

### `packages/flutter_pdfview` (pub 1.4.4-den)
Pub-daky nusga Dart tarapyndan çözüp bolmaýan iki meseläni goýýar:

1. **`fitEachPage` işlemeýär.** Parametr Dart-da bar, ýöne native tarapa hiç
   iberilmeýär (Java-da `.fitEachPage(...)` setiri komment içinde). Netijede
   AndroidPdfViewer-iň deslapky `false` gymmaty berkidilýär: kiçi sahypalar
   **kitabyň iň uly sahypasyna görä** ölçelýär. Kitaba soňundan goşulan uly
   mahabat sahypalary bar bolsa, kitabyň öz sahypalary kiçelip, iki gapdalynda
   boş zolak bilen görkezilýär. → Işjeňleşdirildi.
2. **iOS-da sahypa aralygyny ýapyp bolanok.** `autoSpacing` Android-de hakykatdan
   hem aralygy dolandyrýar, ýöne iOS-da şol bir baýdak PDFKit-iň `autoScales`-ine
   birikdirilen ("sahypany ekrana sygdyr"). iOS-da aralyk `pageBreakMargins`-de,
   ol bolsa daşary çykarylmandyr. → Täze `pageSpacing` parametri goşuldy
   (Android-de `spacing`, iOS-da `pageBreakMargins`).

### `packages/sakura_epub`
EPUB okyjy (epub.js + `flutter_inappwebview`) — annotasiýa, gözleg, temalar.

---

## Başlamak

Gerekli zatlar: [Flutter SDK](https://docs.flutter.dev/get-started/install),
Android Studio we/ýa-da Xcode.

```bash
flutter pub get
flutter run
```

Derňew (analyzer):

```bash
flutter analyze
```

> ⚠️ `test/` bukjasy häzir boş — awtomatiki test ýazylmadyk. `flutter test` işlese-de,
> hiç zat barlamaýar.

### Build

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Google Play üçin
flutter build ios --release          # iOS (Xcode-da archive etmeli)
```

---

## Publish etmezden öň ⚠️

- [ ] **Release signing.** `android/app/build.gradle.kts` häzirem **debug açary**
      bilen gol çekýär (`signingConfig = signingConfigs.getByName("debug")` —
      faýlda TODO hökmünde bellenen). Google Play üçin öz keystore-ňi döretmeli.
- [ ] **API salgysy.** `api_config.dart` gönüden-göni IP salgy ulanýar (`http://`,
      HTTPS däl). Önümçilik (production) domeni bilen çalyşmaly.
- [ ] **Wersiýa belgisi.** `pubspec.yaml` → `version: 1.0.0+1`.
- [ ] **Firebase konfigurasiýasy.** `google-services.json`,
      `GoogleService-Info.plist` we `lib/firebase_options.dart` repozitoriýa
      goşulan we `.gitignore`-da ýok. Açyk (public) repo bolsa, bulary aýyrmaly.
- [ ] Enjamda elde barlamak — awtomatiki test ýok.

---

## Ýazuw düzgünleri

- Setirler hemişe `core/localization/strings/` içinde, `t(tk:, ru:, tr:)` bilen.
  Ekranyň içinde göni ýazylan tekst goýmaly däl.
- Reňkler `AppColors` arkaly (garaňky/ýagty temany özi çözýär).
- Täze ekran açmak: `context.push(EkranAdy())`.
- Kodyň içindäki kommentler **näme üçin** beýle edilendigini düşündirýär —
  esasan hem platforma çäklendirmeleri we tapylan ýalňyşlyklar barada. Üýtgetmezden
  öň okamaly.

## Lisenziýa

Häzirlikçe lisenziýa kesgitlenmedik.
