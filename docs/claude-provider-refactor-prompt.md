# Claude için Provider Refactor Promptu

Bu dosyayı Claude'a doğrudan verin. Hedef; Aykitap Flutter uygulamasını
davranışını değiştirmeden, Provider merkezli ve sürdürülebilir bir yapıya
taşımaktır.

## Mevcut denetim özeti

- Kod tabanı `lib/` altında yaklaşık **32.306 Dart satırı** içeriyor.
- **44 Dart dosyası 200 satırı aşıyor**. Bu proje için katı üst sınır 200
  satırdır; üçüncü taraf `packages/` altı hariç tutulur.
- Uygulama Provider kullanıyor: `lib/main.dart` içindeki `MultiProvider`
  uygulama genelindeki 16 `ChangeNotifier`'ı sağlıyor.
- Aynı state nesneleri hem `context.watch/read` hem de statik
  `XxxService.instance` ile çağrılıyor. Bu ikili yaklaşım test etmeyi,
  bağımlılık değiştirmeyi ve widget yeniden çizimlerini takip etmeyi zorlaştırır.
- Reader katmanı hem en büyük hem de en riskli alan: EPUB/PDF/CBZ akışları
  yaşam döngüsü, bookmark, okuma süresi ve sayfa senkronizasyonu bakımından
  tekrar eden kod taşıyor.
- `flutter analyze` derleme hatası göstermedi; ancak lint uyarıları ve en
  az iki kullanılmayan import var. Test klasöründe yalnızca 3 test dosyası var.

## Öncelikli dosyalar

| Öncelik | Dosyalar | Neden |
| --- | --- | --- |
| P0 | `reader_provider.dart` (969), `pdf_reader_screen.dart` (882), `cbz_reader_screen.dart` (866), `reader_view.dart` (701) | Tekrar eden reader davranışı ve çok büyük state/UI sınıfları. Regresyon olasılığı en yüksek alan. |
| P0 | `search_screen.dart` (866), `catalog_book_detail_screen.dart` (672) | Arama, sayfalama, filtre, indirme ve navigation aynı ekranlarda yoğunlaşmış. |
| P1 | `send_gift_sheet.dart` (657), `reader_settings_sheet.dart` (530), `pdf_settings_sheet.dart` (469), `cbz_settings_sheet.dart` (344) | Form, ayar bölümü ve başarı akışları alt bileşenlere ayrılmalı; ortak ayarlar tek kaynaktan render edilmeli. |
| P1 | `wheel_nav_bar.dart` (469), `library_tabs.dart` (449), `search_sheet.dart` (439), `subscription_screen.dart` (352), `streak_screen.dart` (348) | Büyük UI widget'ları; state, veri yükleme ve görünüm ayrıştırılmalı. |
| P2 | `filter_screen.dart` (315), `reader_tab_screen.dart` (307), `settings_screen.dart` (304), `home_screen.dart` (304), `book_open_flow.dart` (299), `book_api_service.dart` (296), `profile_screen.dart` (295) | Ekran, akış ve servis sorumlulukları ayrıştırılmalı. |
| P2 | 200–294 satır arasındaki kalan 25 dosya | Aynı sınır uygulanmalı; domain tabanlı küçük dosyalara bölünmeli. |

200 satır üzerindeki tüm dosyaların tam listesi için aşağıdaki bölüm kullanılmalıdır:

```text
reader_provider.dart (969)                 pdf_reader_screen.dart (882)
search_screen.dart (866)                   cbz_reader_screen.dart (866)
reader_view.dart (701)                     catalog_book_detail_screen.dart (672)
send_gift_sheet.dart (657)                 reader_settings_sheet.dart (530)
pdf_settings_sheet.dart (469)              wheel_nav_bar.dart (469)
library_tabs.dart (449)                    search_sheet.dart (439)
subscription_screen.dart (352)             streak_screen.dart (348)
cbz_settings_sheet.dart (344)              pdf_reflow_service.dart (331)
filter_screen.dart (315)                   reader_tab_screen.dart (307)
settings_screen.dart (304)                 home_screen.dart (304)
book_open_flow.dart (299)                  chapter_list_sheet.dart (298)
book_api_service.dart (296)                profile_screen.dart (295)
catalog_collection_books_screen.dart (294) catalog_author_detail_screen.dart (278)
profile_strings.dart (275)                 shelf_delete.dart (273)
reader_strings.dart (263)                  balance_screen.dart (255)
filter_controller.dart (253)               page_transition_section.dart (249)
book_purchase_screen.dart (248)            offline_library_screen.dart (248)
notes_screen.dart (239)                    contact_us_sheet.dart (235)
pdf_bottom_bar.dart (234)                  reader_bottom_bar.dart (225)
edit_note_sheet.dart (224)                 api_endpoints.dart (221)
book_download_service.dart (220)           book_suggestions_screen.dart (214)
streak_service.dart (208)                  mock_data.dart (205)
```

---

## Claude'a verilecek talimat

```text
Sen Aykitap Flutter uygulamasının kıdemli refactor mühendisisin.

Amaç: Uygulamanın görünümünü, API sözleşmelerini, localization anahtarlarını
ve mevcut kullanıcı akışlarını değiştirmeden Provider mimarisini tutarlı hale
getir. Kodun okunabilir, test edilebilir ve gelecekte güvenle geliştirilebilir
olmasını sağla.

Zorunlu kurallar

1. `packages/` altındaki üçüncü taraf/vendored kodlar hariç hiçbir proje Dart
   dosyası 200 satırdan uzun kalmayacak. Bir dosya 200 satırı geçtiğinde onu
   sorumluluğa göre böl.
2. Her yeni parçanın tek sorumluluğu olacak. Widget, state, API çağrısı,
   dönüşüm/mapper, dialog/sheet ve sabitler aynı dosyada karışmayacak.
3. Tekrar eden görünüm veya davranış iki veya daha fazla ekranda kullanılabiliyorsa
   ortak widget/helper oluştur ve tüm benzer çağrı noktalarını ona geçir.
   Sadece tek feature'a ait parçaları o feature'ın `widgets/`, `controllers/`
   veya `models/` klasöründe tut; gereksiz global abstraction oluşturma.
4. UI, `ChangeNotifier` state'ini `context.watch`, `context.select`,
   `Consumer` ve aksiyonlar için `context.read` ile kullanacak. Widget içinden
   `SomeService.instance` ile state okuma veya state değiştirme yapılmayacak.
   Uygulama ömürlü servisler geçiş boyunca `Provider.value` ile sağlanabilir;
   ancak erişim Provider üzerinden olmalı.
5. Her async UI işleminde `await` sonrasında `if (!mounted) return;` veya
   `if (!context.mounted) return;` koruması bulunacak. Debounce, timer,
   stream, focus node, animation controller ve observer'lar `dispose` içinde
   temizlenecek.
6. API servisi yalnızca HTTP/parse/exception dönüşümü yapacak. UI mesajı,
   snackbar/dialog ve navigation servis katmanında bulunmayacak.
7. `notifyListeners()` yalnızca state gerçekten değiştiğinde çağrılacak.
   Geniş ekranların tamamını `watch` etmek yerine `select` veya küçük
   `Consumer` alanlarıyla yeniden çizim alanını daralt.
8. Public API'leri, route davranışlarını, backend endpoint/body şekillerini ve
   tk/ru/tr çevirilerini koru. Ağır asset, yeni paket veya mimari framework
   ekleme. Provider dışındaki state-management paketlerini ekleme.
9. Her adımda `dart format`, ilgili testler ve `flutter analyze` çalıştır.
   Mevcut kirli worktree'de task ile ilgisiz dosyalara dokunma.

Uygulama sırası

A. Önce `lib/main.dart` içindeki provider envanterini çıkar. Her state
   nesnesi için owner, yükleme metodu, mutasyon metodu ve dinleyen ekranları
   kısa bir markdown notunda belirt.

B. Reader katmanını küçük, test edilebilir birimlere ayır:
   - `ReaderProvider`: reader preference, reader session/lifecycle, progress,
     bookmark ve note sorumluluklarını ayrı notifier/controller veya saf
     yardımcı sınıflara böl.
   - PDF ve CBZ ekranlarından ortak lifecycle, streak, bookmark ve progress
     kodunu shared reader component/controller'a taşı.
   - EPUB, PDF ve CBZ formatına özel render kodunu ayrı bırak.
   - Reader UI parçalarını top bar, bottom bar, settings section, bookmark
     flow ve error/empty state olarak küçük widget dosyalarına ayır.
   - Önce davranışı koruyan testler yaz; özellikle dispose sonrası callback,
     app lifecycle ve sayfa ilerlemesi için test ekle.

C. Ardından büyük feature ekranlarını refactor et:
   - Search: query state, pagination, discover view, sonuç grid'i, filtre
     dönüşü ve arama çubuğunu ayır.
   - Book detail: veri yükleme/access çözümü, satın alma/indirme akışı ve
     içerik görünümünü ayır. `book_open_flow.dart` ortak kullanım için tek
     otorite olarak kalmalı.
   - Profile/payment: form state, sheet/dialog görünümü ve success/error
     feedback'i ayrıştır; ortak form alanlarını tekrar kullan.
   - Library: tab veri kaynakları, offline/owned/purchased davranışlarını
     tekrar etmeyecek şekilde widget/controller katmanına ayır.

D. 200 satır üstündeki kalan tüm dosyaları feature-domain bazlı parçala.
   `api_endpoints.dart` endpoint domainlerine; string dosyalarını feature
   domainlerine ayırmak serbesttir, fakat public çağrı noktalarını tek PR'da
   güncelle ve kırık import bırakma.

E. Test gereksinimleri:
   - Her yeni notifier/controller için loading/success/error ve dispose
     davranışı unit test ile kapsansın.
   - Reader için lifecycle/progress/bookmark regression testleri yazılsın.
   - Search için debounce, sayfalama ve eski response'un yeni query sonucunu
     ezmemesi test edilsin.
   - Balance/hediye/satın alma için başarılı işlemden sonra Provider state'in
     yenilenmesi test edilsin.

Teslim biçimi

1. Refactor öncesi/sonrası dosya ağacını ver.
2. Her aşamada değişen dosyaları, taşınan sorumlulukları ve yeniden kullanılan
   bileşenleri açıkla.
3. 200 satırı aşan proje Dart dosyası kalmadığını komut çıktısıyla kanıtla.
4. `flutter analyze` ve ilgili testlerin sonuçlarını ver.
5. Davranışı veya API sözleşmesini değiştirmek zorunda kalırsan dur; önce
   net gerekçeyi ve iki seçeneği bildir, varsayım yapma.
```

## Refactor sırasında özellikle doğrulanacak noktalar

- `ReaderProvider`, PDF reader ve CBZ reader `WidgetsBindingObserver`
  kullanıyor. Observer ekleme/çıkarma dengesi ve timer cleanup regression
  testleri olmadan taşınmamalı.
- `AccountService`, `SubscriptionService`, `BookAccessService`, bookmark ve
  library store'ları hem singleton hem Provider olarak erişilebilir. Bir
  feature refactor edildiğinde o feature'da doğrudan singleton erişimlerini
  Provider erişimine dönüştürmek gerekir.
- `Balance`, hediye, kitap satın alma ve abonelik tamamlanınca backend
  doğrulamalı refresh yapılmalı; yerelde varsayımsal bakiye azaltılmamalı.
- Arama ve telefon doğrulama gibi debounce kullanan akışlarda eski HTTP
  cevabının yeni kullanıcı girdisini ezmemesi korunmalı.
- Her bottom sheet/dialog kendi controller ve focus node'larını dispose etmeli;
  başarı dialogu ile navigation sırası `mounted` kontrolü sonrası çalışmalı.
