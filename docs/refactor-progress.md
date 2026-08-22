# Provider refactor — ilerleme durumu

Bu dosya `docs/claude-provider-refactor-prompt.md`'daki görevin ilerlemesini
takip eder. Token/oturum bittiğinde başka bir Claude/AI oturumu buradan devam
edebilsin diye tutuluyor. **Her tamamlanan dosyadan sonra bu listeyi
güncelle.**

## Durma noktası (bu oturum burada bitti)

- **TÜM LİSTE TAMAMLANDI.** `find lib -name "*.dart" | xargs wc -l | sort -n |
  awk '$1>200'` artık boş — `packages/` hariç 200 satırı aşan proje dosyası
  kalmadı. 0 `flutter analyze` hatası, 8/8 test.
- Bu oturumda önce **yarım kalmış bozuk bir önceki bölme** düzeltildi:
  `book_api_service.dart` daha önce (bu dosyanın güncellenmediği bir oturumda)
  `book_list_api_service.dart`'a bölünmüştü ama 9 çağıran dosya
  (`book_access_service.dart`, `catalog_author_detail_screen.dart`,
  `library_screen.dart`, `search_screen.dart`/`search_screen_discover.dart`/
  `search_screen_search.dart` (part dosyaları), `catalog_book_detail_screen.dart`,
  `catalog_genre_books_screen.dart`) hâlâ eski `BookApiService.listBooks`'u
  çağırıyordu → `flutter test` derleme hatası veriyordu (`flutter analyze`
  bunu ilk bakışta göstermemişti, tail'de kesilmişti). Hepsi
  `BookListApiService.listBooks`'a + doğru import'a çevrildi.
- Ardından kalan 5 dosya (200-350 satır arası) tamamlandı:
  `book_list_api_service.dart`, `edit_profile_screen.dart`,
  `filter_controller.dart`, `book_request_sheet.dart`,
  `pdf_reflow_service.dart` (detay aşağıda).
- Hiçbir şey commit edilmedi. `git status` ile değişen/yeni dosyaları gör.
  **Not:** `_StreakServiceReporting` gibi private extension'lara SADECE
  private (`_` ile başlayan) metodlar taşınabilir — public API (örn.
  `loadHistory`/`loadMoreHistory`) ana dosyada kalmalı, aksi halde başka
  dosyalardan erişilemez oluyor (private extension'ın public üyeleri bile
  yalnızca aynı library/`part` grubu içinden görünür). Bu hata bu oturumda
  yapılıp `flutter analyze` ile hemen yakalandı, düzeltildi.
  **Kullanıcı talebi (bu turdan itibaren):** dosya bölerken aynı zamanda
  Provider kullanımını da düzelt — bir widget/State metodu
  `XxxService.instance` ile state okuyor/değiştiriyorsa VE `XxxService`
  `main.dart`'ta `ChangeNotifierProvider` olarak kayıtlıysa,
  `context.read<XxxService>()` (aksiyon) / `context.watch<XxxService>()`
  (build içinde render) ile değiştir. Kayıtlı olmayan servisler
  (`AnalyticsService`, `BookPurchaseApiService` gibi stateless/event
  servisler) `.instance`/static olarak kalmalı — bunlar reaktif state değil.
  Kontrol için: `grep -n "ChangeNotifierProvider" lib/main.dart`.
  **Yöntem notu (önemli, string sınıfları için):** string sabit sınıfları
  `part`/extension ile bölünemiyor (static member — bkz. üstteki "Yöntem"
  bölümü madde 5). Bunun yerine: dosyayı zaten var olan `// ── Section ──`
  yorumlarına (ya da dosya adı yorumlarına) göre gruplara ayır, her grubun
  gerçek çağıranlarını `grep -rl` ile bul, en temiz (en az dosyaya yayılan,
  en büyük) grubu yeni bir `XxxStrings` sınıfına taşı, çağıran
  dosyalardaki import + `EskiSınıf.` önekini güncelle (`part of` dosyalarda
  ana dosyanın import listesini güncelle). 200 altına inene kadar tekrarla.
- Hiçbir şey commit edilmedi (kullanıcı istemedi). `git status` ile
  değişen/yeni dosyaları gör.
- Devam etmeden önce mutlaka çalıştır: `flutter analyze` (0 hata olmalı) ve
  `flutter test` (8 test geçmeli) — bu oturumun sonunda ikisi de temizdi.

## Yöntem (önemli — devam eden oturum bunu bilmeli)

Her büyük dosya için aynı desen kullanıldı:

1. **StatefulWidget/State sınıfları** → `part`/`part of` + `extension X on
   _PrivateState { ... }` ile bölündü. Alanlar (fields) tek dosyada
   (ana dosya) kalmak zorunda — Dart bir class'ın field'larını dosyalar
   arasında bölmeye izin vermiyor. Metodlar sorumluluğa göre ayrı `part`
   dosyalarına taşındı.
   - **Kritik tuzak 1**: `notifyListeners()`/`setState()` `@protected` —
     extension'lardan doğrudan çağrılamaz. Ana sınıfa `void _notify()
     => notifyListeners();` (Provider) veya `void _setState(VoidCallback fn)
     => setState(fn);` (State) adında ince bir sarmalayıcı ekle, tüm
     extension'lar onu çağırsın.
   - **Kritik tuzak 2**: `static const` alanlar extension'lardan unqualified
     erişilemez — `ClassName._alanAdi` şeklinde nitelendirilmeli.
2. **Bağımsız StatelessWidget'lar** (parametre alan, sadece UI çizen) → ayrı
   dosyalara taşındı, sınıf adı public yapıldı (private `_Foo` → public
   `Foo`), gerekirse `widgets/` klasörüne kondu.
3. **Birebir kopyalanan kod** (2-3 reader ekranında aynı widget/servis) →
   paylaşılan tek dosyaya çıkarıldı (örn. `ReaderStreakPing`,
   `ReaderSliderRow`, `ReaderSheetHeader`).
4. Her dosya değişikliğinden sonra: `dart format` + `flutter analyze` (sadece
   değişen dosyalar, sonra tüm proje) + `flutter test`. Hiçbir adımda hata
   bırakılmadı.
5. **String sabit sınıfları** (`ReaderStrings`, `ProfileStrings`,
   `ApiEndpoints` gibi salt-`static` sınıflar) bilerek atlandı — bunlar
   `part`/extension ile bölünemiyor (static member'lar extension'a taşınamaz),
   bölmek her çağrı noktasını (`ReaderStrings.xxx` gibi) değiştirmeyi
   gerektirir, bu da düşük risk ama yüksek "değişen dosya sayısı" demek.
   Gerekirse ayrı bir görev olarak ele alınmalı.

## Bitti (TAMAMI — 200 satır üstü proje dosyası kalmadı, `find lib -name "*.dart" | xargs wc -l | sort -n | awk '$1>200'` boş dönüyor)

Reader modülü (13 dosya, tamamen):
`reader_provider.dart`, `pdf_reader_screen.dart`, `cbz_reader_screen.dart`,
`reader_view.dart`, `reader_settings_sheet.dart`, `pdf_settings_sheet.dart`,
`cbz_settings_sheet.dart`, `search_sheet.dart`, `reader_tab_screen.dart`,
`chapter_list_sheet.dart`, `page_transition_section.dart`,
`pdf_bottom_bar.dart`, `reader_bottom_bar.dart`

Diğer:
- `lib/modules/search/search_screen.dart` (866→8 dosya)
- `lib/modules/book_detail/catalog_book_detail_screen.dart` (672→3 dosya +
  5 widget dosyası)
- `lib/modules/profile/book_suggestions_screen.dart` (214→2 dosya)
- `lib/modules/profile/widgets/contact_us_sheet.dart` (235→3 dosya)
- `lib/modules/library/widgets/shelf_delete.dart` (273→4 dosya)
- `lib/modules/author/catalog_author_detail_screen.dart` (278→5 dosya)
- `lib/modules/home/catalog_collection_books_screen.dart` (294→6 dosya)
- `lib/modules/profile/widgets/edit_note_sheet.dart` (224→2 dosya)
- `lib/modules/profile/notes_screen.dart` (239→3 dosya)
- `lib/modules/library/offline_library_screen.dart` (248→4 dosya)
- `lib/modules/profile/profile_screen.dart` (295→3 dosya: ana dosya +
  `profile_screen_session.dart` + `profile_screen_entries.dart`, part/extension
  deseni — `_setState` sarmalayıcı ile)
- `lib/modules/home/home_screen.dart` (304→3 dosya: ana dosya +
  `home_screen_sections.dart` (part/extension, collection-bölüm render) +
  `widgets/home_reload_state.dart` (bağımsız StatelessWidget, `_HomeReloadState`
  → public `HomeReloadState`))
- `lib/modules/profile/settings_screen.dart` (304→2 dosya: ana dosya (181) +
  `widgets/settings_confirm_dialog.dart` (75) — `_confirmLogout` ve
  `_confirmDeleteAccount` neredeyse birebir aynıydı (ikon/renk/metin dışında),
  tek parametreli `showSettingsConfirmDialog(...)` fonksiyonuna çıkarıldı;
  ikisinin de onConfirm'i aynı `_clearSessionAndClose()` — davranış aynen
  korundu, "delete account" da aslında sadece oturumu temizliyor, ayrı bir
  silme API'si çağırmıyor (bu refactor'ın kapsamı dışında, dokunulmadı))
- `lib/modules/filter/filter_screen.dart` (315→5 dosya: ana dosya (86) +
  `widgets/filter_quick_sections.dart` (117, Dil/Žanr/Format/Çap senesi
  kartı) + `widgets/filter_language_genre_options.dart` (132, dil/žanr
  chip listelerinin loading/empty/failed durumları) +
  `widgets/filter_sort_and_clear.dart` (86, sıralama kartı + "Filtri
  arassala" satırı) + `widgets/filter_bottom_bar.dart` (53) — zaten
  `StatelessWidget` + `ChangeNotifierProvider<FilterController>` olduğu
  için part/extension deseni gerekmedi, her parça kendi
  `context.watch/read<FilterController>()` çağırıyor)
- `lib/modules/streak/streak_screen.dart` (348→6 dosya: ana dosya (63) +
  `widgets/streak_summary_card.dart` (35) + `widgets/streak_week_card.dart`
  (34) + `widgets/streak_monthly_card.dart` (136, `_showLastMonth` toggle
  state'i artık `StreakScreen`'de değil kendi `StatefulWidget`'ında —
  başka hiçbir yerin bu state'i bilmesine gerek yok) +
  `widgets/streak_info_card.dart` (39) + `widgets/streak_history_list.dart`
  (168, `_dayLabel` helper + loading/empty/list/load-more) — hepsi kendi
  `context.watch<StreakService>()` çağırıyor, ana ekran artık sadece
  `initState`'te `load()`/`loadHistory()` tetikleyip kartları diziyor)
- `lib/modules/library/widgets/library_tabs.dart` (449→3 dosya, dosya
  silindi): `widgets/downloaded_tab.dart` (162, `DownloadedTab` — kendi
  başına bağımsızdı) + `widgets/api_books_tab.dart` (177, widget + State
  fields + `initState`/`dispose`/`build` + `_setState` sarmalayıcı) +
  `widgets/api_books_tab_actions.dart` (140, `part of` + extension:
  `_load`/`_loadOfflineShadow`/`_openBook`/`_confirmDelete`/`_unfavorite`/
  `_remove`). `library_screen.dart`'taki import iki yeni dosyaya
  güncellendi.
- `lib/modules/main_nav/widgets/wheel_nav_bar.dart` (469→5 dosya): ana
  dosya (186) + `wheel_nav_bar_disk_painter.dart` (67, `_DiskPainter` →
  public `DiskPainter`, tamamen bağımsızdı) + `wheel_nav_bar_geometry.dart`
  (69, `part of` — tüm `static const` geometri/timing sabitleri artık
  library-level const, `_WheelNavBarState.` niteleyicisi gerekmiyor) +
  `wheel_nav_bar_gestures.dart` (97, `part of` + extension: sürükleme
  matematiği) + `wheel_nav_bar_icons.dart` (115, `part of` + extension:
  `_buildIcons`). `git diff` ile doğrulandı — saf mekanik taşıma, hiçbir
  sayı/formül/timing değişmedi.
- `lib/core/localization/strings/reader_strings.dart` (263→187, artı 4 yeni
  sınıf dosyası): `reader_search_strings.dart` (65, in-book search —
  sadece `search_sheet_header.dart`/`search_sheet_results.dart`
  kullanıyordu) + `reader_notes_strings.dart` (55, selection toolbar +
  add-note sheet — birlikte taşındı çünkü çağıranların çoğu ikisini de
  kullanıyordu) + `reader_continue_strings.dart` (35, "continue reading"
  boş durumu — sadece 2 dosya) + `reader_bookmark_strings.dart` (37,
  bookmark — 7 dosyaya yayılıyordu, bazıları artık 2-3 string importu
  taşıyor). Toplam ~15 çağıran dosyada import + `ReaderStrings.` →
  `ReaderXxxStrings.` güncellendi (`part of` dosyalarda ana dosyanın
  import listesi güncellendi).
- `lib/core/localization/strings/profile_strings.dart` (275→196, artı 1
  yeni sınıf dosyası): `profile_feedback_strings.dart` (92,
  `book_request_sheet.dart` + `report_problem_sheet.dart` birleştirildi —
  ikisi de aynı "Iber" (`send`) düğmesini paylaşıyordu, ikisi de tam swap
  oldu). `reportProblemEntryTitle` ayrıca `profile_screen_entries.dart`
  (part of `profile_screen.dart`) tarafından menü satırı etiketi olarak
  kullanılıyordu — o dosya artık iki string importu taşıyor.
- `lib/core/network/api_endpoints.dart` (221, dosya SİLİNDİ) → 7 domain
  dosyasına bölündü: `auth_endpoints.dart` (27), `book_endpoints.dart` (60),
  `payment_endpoints.dart` (40), `streak_endpoints.dart` (24),
  `feedback_endpoints.dart` (18), `catalog_endpoints.dart` (37, birden çok
  `*_api_service.dart` public/no-auth metadata uçlarını paylaşıyor),
  `account_endpoints.dart` (47, aynı şekilde birkaç servis paylaşıyor).
  **Önemli bulgu:** her `ApiEndpoints.` çağıran dosya (`grep -o` ile
  kontrol edildi) yalnızca TEK domain'den sabit kullanıyordu — tek istisna
  `subscription_screen.dart`/`payment_webview_screen.dart`'taki
  `[ApiEndpoints.paymentOrders]` referansları, onlar da sadece dokümantasyon
  yorumuydu (gerçek kod değil). Bu yüzden HİÇBİR çağıran dosya çift import
  gerektirmedi — hepsi tam swap. 2 test dosyası da güncellendi
  (`test/support/fake_dio_adapter.dart`,
  `test/modules/reader/reader_provider_lifecycle_test.dart` — sadece
  `streakReport` kullanıyorlardı, ilk `flutter analyze` bunları `lib/`
  içinde aramadığım için kaçırmıştı, ikinci geçişte yakalandı).
- `lib/core/data/mock/mock_data.dart` (205→163) — **bölme değil, ölü kod
  silme.** `grep -rn "MockData\."` tüm `lib/`+`test/` ağacında tek bir
  gerçek çağıran buldu (`reading_note.dart`'ın `MockData.generateBooks`
  kullanımı); geri kalan her referans yalnızca doc-comment'ti. `homeSections`,
  `collections`, `series`/`_series()`, `popularSearches`,
  `quickFilterChips`, `books` (sabit 50'lik havuz) — hiçbiri hiçbir yerden
  okunmuyordu (`HomeScreen` gerçek API'ye geçmiş, mock referansı sadece
  tarihsel doc-comment olarak kalmış). Silindi; `generateBooks`'un
  kendisinin ihtiyaç duyduğu `_titles`/`authors`/`_coverColors`/
  `_coverImages`/`genrePool` korundu.
- `lib/core/services/book_download_service.dart` (227→92, artı
  `book_download_service_impl.dart` (153)): `ChangeNotifier` singleton,
  `part`/extension deseni ile bölündü. Ana dosyada widget/State'lerde
  kullanılan aynı tuzak — `notifyListeners()` `@protected`, extension'dan
  çağrılamıyor — `void _notify() => notifyListeners();` sarmalayıcısı
  eklendi. `static final _downloader` (Dio instance) private static olduğu
  için extension'dan `BookDownloadService._downloader` diye nitelendirildi.
  `_safeFileName` statik metod yerine part dosyasında plain private
  top-level fonksiyon yapıldı (sadece kendi içinde kullanılıyordu).
- `lib/modules/payment/book_purchase_screen.dart` (324→154, artı 3 widget
  dosyası): `widgets/book_purchase_summary_card.dart` (89, kapak+başlık),
  `widgets/book_purchase_price_card.dart` (90, fiyat/bakiye kırılımı + `_row`
  helper), `widgets/book_purchase_confirm_button.dart` (57, sticky buton).
  **Provider düzeltmesi:** `_confirm()`/`_offerTopUp()` içindeki
  `AccountService.instance.balanceManat/refresh()` ve
  `BookAccessService.instance.markPurchased()` çağrıları
  `context.read<AccountService>()`/`context.read<BookAccessService>()`'e
  çevrildi (ikisi de `main.dart`'ta provider). `AnalyticsService.instance`
  ve `BookPurchaseApiService.buy()` dokunulmadı — provider'da kayıtlı
  değiller, stateless. Satın alma mantığının kendisi (istek sırası, hata
  yönetimi, bakiye server'dan yeniden okunması) birebir aynı kaldı.

Ayrıca: `lib/core/services/streak_service.dart`'a test için
`resetForTest()` eklendi (davranış değişmedi).

Test dosyası: `test/modules/reader/reader_provider_lifecycle_test.dart` (8
test — dispose/lifecycle/progress/bookmark regresyonlarını kapsıyor). Test
altyapısı: `test/support/fake_dio_adapter.dart` (gerçek ağ isteği atmadan
DioClient'ı test etmek için).

## Kalan — kolaydan zora sıralı öneri

### Kolay — TAMAMLANDI ✅ (hepsi bitti)

### Orta (StatefulWidget, orta karmaşıklıkta state, para/ödeme YOK)
- [x] `lib/modules/profile/settings_screen.dart` (304) — TAMAMLANDI
- [x] `lib/modules/filter/filter_screen.dart` (315) — TAMAMLANDI
- [x] `lib/modules/streak/streak_screen.dart` (348) — TAMAMLANDI
- [x] `lib/modules/library/widgets/library_tabs.dart` (449) — TAMAMLANDI
- [x] `lib/modules/main_nav/widgets/wheel_nav_bar.dart` (469) — TAMAMLANDI

### Zor / dikkatli yapılmalı (para/ödeme, kritik singleton, çok-caller servis)
- [x] `lib/modules/payment/book_purchase_screen.dart` (248) — TAMAMLANDI
- [x] `lib/modules/profile/balance_screen.dart` (255) — TAMAMLANDI
- [x] `lib/modules/payment/subscription_screen.dart` (352) — TAMAMLANDI
- [x] `lib/modules/profile/widgets/send_gift_sheet.dart` (657) — TAMAMLANDI
- [x] `lib/modules/book_detail/book_open_flow.dart` (299) — TAMAMLANDI
- [x] `lib/core/services/streak_service.dart` (240) — TAMAMLANDI
- [x] `lib/core/services/book_api_service.dart` (296) — TAMAMLANDI (daha önceki
      oturumda `book_list_api_service.dart`'a bölünmüştü, bu oturumda sadece
      kırık çağıranlar düzeltildi — bkz. yukarı)
- [x] `lib/core/services/pdf_reflow_service.dart` (350) — TAMAMLANDI
- [x] `lib/modules/filter/controller/filter_controller.dart` (253) — TAMAMLANDI

### Bu oturumda ayrıca bitirilen (200-350 satır arası, listeye sonradan eklenmiş)
- [x] `lib/core/services/book_list_api_service.dart` (224) — TAMAMLANDI
- [x] `lib/modules/profile/edit_profile_screen.dart` (235) — TAMAMLANDI
- [x] `lib/modules/profile/book_request_sheet.dart` (254) — TAMAMLANDI

### Atlandı (mekanik olarak bölünemiyor, ayrı görev gerekir) — kullanıcı isteğiyle şimdi bitiriliyor
- [x] `lib/core/localization/strings/reader_strings.dart` (263) — TAMAMLANDI
- [x] `lib/core/localization/strings/profile_strings.dart` (275) — TAMAMLANDI
- [x] `lib/core/network/api_endpoints.dart` (221) — TAMAMLANDI (dosya silindi)
- [x] `lib/core/data/mock/mock_data.dart` (205) — TAMAMLANDI (ölü kod silindi)
- [x] `lib/core/services/book_download_service.dart` (220) — TAMAMLANDI

### Kontrol edildi — kalan yok

`find lib -name "*.dart" | xargs wc -l | sort -n | awk '$1>200'` (packages/
hariç) artık boş dönüyor. 200 satır üstü hiçbir proje Dart dosyası kalmadı.

## Sonra: Phase C/D/E (dosya bölmekten bağımsız, mimari işler)

Plan dosyası `docs/claude-provider-refactor-prompt.md`'de tanımlı, henüz
başlanmadı:
- `docs/provider-inventory.md`'deki dual-access sınıfları düzelt (özellikle
  `AppTheme` 20 dosyada `.instance`, `AccountService` 12 dosyada,
  `BookAccessService` 10 dosyada) — widget'ları `context.watch/read`'e taşı.
- Arama/ödeme/kütüphane akışları için ek regresyon testleri (debounce,
  sayfalama, satın alma sonrası state yenilenmesi).
- 200 satır üstü dosya kalmadığını kanıtlayan komut çıktısı.

## Doğrulama komutları (her adımdan sonra çalıştırılmalı)

```bash
dart format <değişen dosyalar>
flutter analyze <değişen dosyalar>   # hızlı kontrol
flutter analyze                       # tam proje, 0 hata olmalı
flutter test                          # 8 test geçmeli
find lib -name "*.dart" | xargs wc -l | sort -n | awk '$1>200'  # kalan liste
```
- lib/modules/profile/balance_screen.dart (255->84, artı 3 widget dosyası):
  widgets/balance_history_tab_toggle.dart (66, segmented control - public
  BalanceTab enum artık burada tanımlı), widgets/balance_card_payments_list.dart
  (56), widgets/balance_history_list.dart (96, _HistoryEmpty dahil).
  Provider düzeltmesi: tek düzeltme _buildHistoryEmpty()'deki
  AppTheme.instance.isDark -> context.watch<AppTheme>().isDark (build
  içinde render kararı, tema değişince yeniden çizilmeli). Gerisi zaten
  context.watch/read<BalanceController>()/<AccountService>()
  kullanıyordu, dokunulmadı.
- lib/modules/payment/subscription_screen.dart (404->116, artı 5 dosya):
  subscription_plan_helpers.dart (30, top-level bestSubscriptionPlanIndex/
  subscriptionPlanLabel - hem ana State hem SubscriptionPlanList widget'ı
  kullanıyor), subscription_screen_actions.dart (146, part/extension:
  _loadTariffs/_startCheckout/_showInsufficientBalanceDialog/
  _choosePaymentMethod/_payWithPromoCode/_payWithBank), artı 3 widget
  dosyası (subscription_header.dart 92, subscription_checkout_button.dart
  60, subscription_plan_list.dart 79).
  Provider düzeltmesi: SubscriptionService.instance.load()/subscribe() ve
  AccountService.instance.refresh()/balanceManat -> context.read<>().
  Tek davranış eklentisi: _payWithPromoCode()'da redeemPromoCode ile
  AccountService.instance.refresh() arasında mounted kontrolü YOKTU (çünkü
  .instance context'e ihtiyaç duymuyordu); context.read<AccountService>()'e
  geçince context'in hâlâ geçerli olması gerektiği için bir
  "if (!mounted) return;" eklendi - bu tek yer, plan dosyasının kural 5'i
  zaten bunu istiyordu (her async sonrası mounted koruması). Geri kalan
  her şey (istek sırası, hata yönetimi, bakiye/webview akışı) birebir aynı.
- lib/modules/profile/widgets/send_gift_sheet.dart (657->165, artı 7 dosya):
  widgets/gift_sheet_frame.dart (48, dönen sweep-gradient çerçeve, public
  GiftSheetFrame), widgets/gift_hero.dart (82), widgets/gift_section_label.dart
  (41, yeni paylaşılan numaralı adım etiketi), widgets/gift_amount_section.dart
  (147, preset/miktar alanı), widgets/gift_phone_section.dart (134, telefon
  alanı + yeni public enum GiftUserCheckStatus, eskiden private
  _UserCheckStatus'tü), widgets/gift_submit_button.dart (92),
  widgets/send_gift_sheet_actions.dart (78, part/extension:
  _formatPhone/_onPhoneChanged/_checkUser/_submit). Provider düzeltmesi:
  _submit()'teki AccountService.instance.refresh() ->
  context.read<AccountService>().refresh(), bir "if (!mounted) return;"
  eklendi (subscription_screen_actions.dart'taki aynı desen). Para transferi
  mantığının kendisi (checkUserExists debounce'u, sendToFriend çağrı sırası,
  hata yönetimi) birebir aynı kaldı.
- lib/modules/book_detail/book_open_flow.dart (299->125, artı 2 dosya):
  book_open_flow_actions.dart (161, part/extension:
  _login/_topUp/_downloadAndOpen/_offerPurchasedExport/_pickFile/_openReader)
  + lib/modules/reader/utils/catalog_book_opener.dart (54, top-level
  openCatalogBookFile fonksiyonu — BookOpenFlow sınıfıyla ilgisi yok, kendi
  dosyasına taşındı; 4 çağıran dosyanın importu güncellendi:
  reader_tab_screen.dart, downloaded_tab.dart, api_books_tab.dart,
  catalog_book_detail_screen.dart — sonuncusu hem BookOpenFlow hem
  openCatalogBookFile kullandığı için iki import da kaldı). **"Tek otorite"
  kısıtı korundu:** read()/buy() (asıl akış kontrolü, retry mantığı) ana
  dosyada bir arada kaldı, sadece private yardımcı metodlar part dosyasına
  taşındı — hiçbir kontrol akışı bölünmedi. Provider düzeltmesi:
  BookAccessService/AccountService/DownloadedFilesStore/BookDownloadService/
  DownloadedBooksStore/ReadingBooksStore/LastReadBookStore hepsi
  main.dart'ta provider olduğu için `.instance` -> context.read<>() oldu.
  _downloadAndOpen() tüm provider'larını herhangi bir await'ten ÖNCE tek
  seferde yakalayıp yerel değişkende tutuyor (sonra context.read'i tekrar
  çağırmaya gerek kalmıyor). _login()'in iki çağrısı eskiden hiçbir mounted
  kontrolünden önce çalışıyordu (.instance context'e ihtiyaç duymadığı
  için) — context.read'e geçince bir "if (!context.mounted) return false;"
  eklendi. AnalyticsService.instance dokunulmadı (provider'da kayıtlı değil).
- lib/core/services/streak_service.dart (240->155, artı
  streak_service_reporting.dart (107)): ChangeNotifier singleton, aynı
  book_download_service deseni — `void _notify() => notifyListeners();`
  sarmalayıcısı eklendi. Ana dosyada kaldı: fields, getters, resetForTest,
  load/refresh, loadHistory/loadMoreHistory (public API — bkz. aşağıdaki
  not), recordActiveSeconds/recordPageRead/flushResidual. Part dosyasına
  taşındı: sadece private metodlar — _loadHistoryPage/_report/_applyReport/
  _mergeToday/_showRewards. **Tuzak (bu dosyada ilk kez düşüldü):**
  loadHistory/loadMoreHistory ilk denemede part dosyasındaki private
  extension'a taşınmıştı — private bir extension'ın PUBLIC üyeleri bile
  yalnızca aynı library (aynı `part`/`part of` grubu) içinden görünür,
  streak_screen.dart/streak_history_list.dart gibi ayrı dosyalardan
  görünmez oldu (`flutter analyze`: undefined_method/undefined_getter).
  Düzeltme: ikisi de ana dosyaya geri taşındı, sadece gerçekten private
  (`_` önekli) metodlar extension'da kaldı — book_download_service.dart'ta
  zaten kullanılan doğru desen buydu. Provider düzeltmesi: **kasıtlı olarak
  yapılmadı** — `_showRewards()`'taki `AccountService.instance.refresh()`
  `.instance` olarak bırakıldı, çünkü StreakService bir widget/State değil;
  kendi BuildContext'i yok, `_showRewards` içindeki `context` değişkeni
  `rootNavigatorKey`'den çekilen tek seferlik nullable bir değer (sadece
  dialog göstermek için) — refresh'i buna bağlamak, dialog gösterilemediği
  her an refresh'i sessizce atlamak demek olurdu, bu mekanik değil gerçek
  bir davranış değişikliği olur. resetForTest() dokunulmadı, davranışı aynı.

### Bu oturumda bitirilen son 5 dosya

- **Önce düzeltme (bölme değil):** `book_api_service.dart` → önceki bir
  oturumda `book_list_api_service.dart`'a (`listBooks` + fan-out/merge)
  bölünmüştü ama 9 çağıran dosya güncellenmemiş kalmıştı (`flutter test`
  derleme hatası veriyordu). Hepsi `BookListApiService.listBooks`'a çevrildi;
  `book_api_service.dart` kendisi zaten 87 satır (getBookById/
  updateProgress/deleteProgress/likeBook/unlikeBook/removeBoughtBook) —
  ayrıca bölünmesine gerek yoktu.
- `lib/core/services/book_list_api_service.dart` (224→132, artı
  `book_list_api_fanout.dart` (98)): private static `_listBooksFanOut`/
  `_mergeSorted` static-sınıf metodlarıydı (extension'a taşınamaz — sadece
  static üye), bunun yerine `part`'a **top-level private fonksiyon** olarak
  taşındı (book_download_service.dart'taki `_safeFileName` deseninin aynısı).
  `listBooks` çağrısı fan-out içinde `BookListApiService.listBooks(...)` diye
  nitelendirildi (artık aynı class'ın static üyesi değil, top-level'dan
  class'a çağrı).
- `lib/modules/profile/edit_profile_screen.dart` (235→152, artı 3 widget
  dosyası): `widgets/edit_profile_avatar_section.dart` (48, avatar + kamera
  rozeti), `widgets/edit_profile_fields.dart` (58, kullanıcı adı + telefon
  alanları), `widgets/edit_profile_save_button.dart` (36). Saf UI ayrıştırma,
  state/network mantığına dokunulmadı. Provider gerekmedi — bu ekran zaten
  `AuthSession`/`AuthApiService` static çağırıyordu, ikisi de provider'da
  kayıtlı değil.
- `lib/modules/filter/controller/filter_controller.dart` (253→175, artı
  `filter_enums.dart` (84)): `SortBy`/`BookFormatFilter` enum'ları + label
  extension'ları + `kDefaultSortBy` ayrı dosyaya taşındı,
  `filter_controller.dart`'ta `export 'filter_enums.dart';` eklendi — bu
  sayede `search_screen.dart`'ın `show BookFormatFilter, ..., kDefaultSortBy`
  gibi seçici import'ları dahil hiçbir çağıran dosya değişmedi.
  `kDefaultYearRange` (RangeValues) `FilterController`'a özgü olduğu için
  ana dosyada kaldı.
- `lib/modules/profile/book_request_sheet.dart` (254→167, artı 3 widget
  dosyası): `widgets/book_request_field.dart` (49, eski private `_FieldLabel`/
  `_TextField` → public `BookRequestFieldLabel`/`BookRequestTextField`),
  `widgets/book_request_language_chips.dart` (44), `widgets/
  book_request_submit_button.dart` (38). `core/widgets/app_text_field.dart`
  diye genel bir text field zaten var ama farklı yükseklik/focus-border
  davranışı olduğu için ona geçilmedi (görünümü değiştirmemek için) —
  sadece mekanik taşıma yapıldı.
- `lib/core/services/pdf_reflow_service.dart` (350→159, artı
  `pdf_reflow_epub_builder.dart` (152) + `pdf_reflow_epub_templates.dart`
  (58)): `ChangeNotifier` değil ama instance-metodlu bir singleton
  (`PdfReflowService._()` + `static final instance`), bu yüzden diğer
  singleton servislerdeki `part`/`extension on PdfReflowService` deseni
  aynen uygulandı. Üç parça: ana dosyada tespit/cache API'si
  (`reflowEpubPathFor`/`cachedReflowEpubPath`/`isImageOnlyPdf`/
  `deleteCacheFor`/`_looksLikeTextPdf`/`_cacheDirFor`), builder dosyasında
  metin çıkarma (`_buildEpub`/`_paragraphsFor`/`_splitLongBlock`/
  `_escapeXml`/`_stripXmlIllegalChars`), templates dosyasında XHTML/OPF
  şablonları (`_chapterXhtml`/`_navXhtml`/`_contentOpf`/`_containerXml`).
  `_pagesPerChapter` gibi ana dosyada kalan `static const`'lar extension'dan
  `PdfReflowService._pagesPerChapter` diye nitelendirildi (Kritik tuzak 2).
  Provider düzeltmesi **yapılmadı** — ChangeNotifier değil, reaktif state
  taşımıyor (cache dosyaları disk üzerinde), streak_service.dart'taki
  `AccountService.instance` gibi bilinçli olarak `.instance` kaldı.

Doğrulama: her dosyadan sonra `dart format` + `flutter analyze` (0 hata) +
`flutter test` (8/8) çalıştırıldı, son olarak tüm proje için de tekrarlandı.
