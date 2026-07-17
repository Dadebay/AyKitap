# Reader Düzeltme Listesi (EPUB / PDF / CBZ)

> Amaç: Üç formatın da **sorunsuz ve hızlı açılması**. Öncelik sırası: P0 (kritik, önce bunlar) → P1 (önemli) → P2 (isteğe bağlı).
> İlgili dosyalar her maddede belirtildi. `flutter analyze` şu an 0 error / 0 warning veriyor (sadece stil lint'leri var), yani sorunlar davranışsal.

---

## P0 — Kritik (kitabın açılmasını/devam etmesini bozan şeyler)

### 1. EPUB: Kaldığı yerden devam etme yarışı (race condition) — en önemli düzeltme
**Dosyalar:** `lib/modules/reader/provider/reader_provider.dart` (satır ~302-306), `lib/modules/reader/views/reader_view.dart` (`_buildEpubViewer`), `packages/sakura_epub/lib/assets/webpage/html/epubView.js` (`toProgress`, satır 2453)

- Şu an konum sadece **yüzde (progress)** olarak kaydediliyor ve açılıştan sonra sabit `600ms` gecikmeyle `toProgressPercentage(_progress)` çağrılıyor.
- JS tarafındaki `toProgress()` → `book.locations.cfiFromPercentage(progress)` kullanıyor. Ama `book.locations.generate(1600)` **asenkron** ve büyük kitaplarda 600ms'den uzun sürüyor → `cfiFromPercentage` undefined döner → kitap **baştan açılır** ya da yanlış sayfaya gider.

**Düzeltme:**
1. `ReaderProvider._saveProgress()` içinde `_currentCfi`'yi de kaydet: `prefs.setString('book_${_bookId}_cfi', _currentCfi)`.
2. `initialize()` içinde kaydedilmiş CFI'yi oku ve bir `String? savedCfi` getter'ı ile dışarı ver.
3. `ReaderScreen._buildEpubViewer` içinde `EpubViewer(initialCfi: provider.savedCfi, ...)` geç — `EpubViewer` zaten `initialCfi` destekliyor (`epub_viewer.dart` → `loadBook()` → `rendition.display(cfi)`), locations beklemeden doğru yere açılır.
4. `onEpubLoaded` içindeki 600ms'lik `Future.delayed(...toProgressPercentage)` bloğunu **sil** (CFI yoksa, sadece eski kayıtlar için progress fallback bırakılabilir).
5. Ek güvenlik: `epubView.js` `toProgress()` içine guard ekle: `if (!book.locations || !book.locations.length()) return;`

### 2. EPUB: Bozuk dosyada sonsuz yükleme ekranı (hata durumu yok)
**Dosyalar:** `packages/sakura_epub/lib/src/epub_viewer.dart`, `packages/sakura_epub/lib/assets/webpage/html/epubView.js` (satır 932: `rendition.on('displayError', ...)`), `lib/modules/reader/views/reader_view.dart`

- JS tarafı `displayError` olayında `callHandler('displayError')` çağırıyor ama **Dart tarafında bu handler hiç kayıtlı değil** (`addJavaScriptHandlers()` içinde yok). `book.open()` çağrısının da `.catch`'i yok.
- Sonuç: bozuk/uyumsuz bir EPUB açılırsa kullanıcı **sonsuza kadar yükleme animasyonunda** kalıyor (PDF ve CBZ'nin hata ekranı var, EPUB'un yok).

**Düzeltme:**
1. `EpubViewer`'a `VoidCallback? onEpubLoadFailed` parametresi ekle; `addJavaScriptHandlers()` içinde `displayError` handler'ı kaydet ve bu callback'i çağır.
2. `epubView.js` içinde `book.open(uint8Array)` ve `rendition.display()` promise'lerine `.catch(...)` ekleyip `callHandler('displayError')` tetikle.
3. `ReaderScreen`'e PDF okuyucudaki gibi bir hata durumu ekle (`_error != null` → hata ekranı; yükleme overlay'ini kapat).
4. Emniyet kemeri: `ReaderScreen`'de 30 sn'lik bir timeout — `onEpubLoaded` gelmezse hata ekranına düş.

### 3. EPUB: Android geri tuşu/jesti ilerlemeyi kaydetmiyor (PopScope yok)
**Dosya:** `lib/modules/reader/views/reader_view.dart`

- `saveAndClose()` sadece top bar'daki geri okuna bağlı. Sistem geri jesti/tuşu ile çıkılırsa: debounce timer'ı iptal olur, **son ilerleme kaydedilmez** (dispose'da `_saveProgress` çağrılmıyor).

**Düzeltme:** `Scaffold`'u `PopScope` ile sar:
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    await provider.saveAndClose();
    if (context.mounted) Navigator.of(context).pop();
  },
  child: Scaffold(...),
)
```
(PDF/CBZ ekranlarında `dispose()` içinde `_saveProgress()` çağrıldığı için oralar idare ediyor; yine de aynı PopScope kalıbı oralara da eklenebilir — P2.)

### 4. PDF: "Koyu zemin" ayarı sayfayı invert ediyor + iOS'ta hiç çalışmıyor
**Dosya:** `lib/modules/reader/views/pdf_reader_screen.dart` (satır 333: `nightMode: _darkGutter`)

- `_darkGutter` hem arkaplan rengini hem `PDFView.nightMode`'u sürüyor. `nightMode` Android'de **sayfanın kendisini renk-invert eder** — taranmış kitap/manga sayfaları negatif film gibi görünür. iOS'ta `nightMode` flutter_pdfview'da desteklenmez, yani ayar iOS'ta sessizce hiçbir şey yapmaz.

**Düzeltme:** `nightMode`'u `_darkGutter`'dan ayır:
- En basit ve güvenli: `nightMode: false` sabitle; `_darkGutter` yalnızca `backgroundColor`/gutter rengini kontrol etsin (ayarın adı zaten "koyu zemin").
- İstenirse ayrı bir "Geceleri renkleri ters çevir (yalnız Android)" anahtarı olarak geri eklenebilir.

### 5. CBZ: Ekran erken kapatılırsa crash (`late final _pageController`)
**Dosya:** `lib/modules/reader/views/cbz_reader_screen.dart` (satır 54, 95, 224)

- `_pageController` async `_bootstrap()` içinde oluşturuluyor. Kullanıcı extraction bitmeden geri çıkarsa `dispose()` → `_pageController.dispose()` → **LateInitializationError crash**.

**Düzeltme:** Controller'ı `initState`'te senkron oluştur (`PageController()`), restore edilen sayfaya extraction bitince `jumpToPage` ile git; ya da `PageController? _pageController` yapıp dispose'da null-check.

### 6. CBZ: Büyük dosyada OOM + UI donması (main isolate'ta zip decode)
**Dosya:** `lib/modules/reader/views/cbz_reader_screen.dart` (`_extract`, satır 104-182)

- `File(...).readAsBytes()` ile **tüm zip belleğe** alınıyor, `ZipDecoder().decodeBytes` + sayfa yazma işlemleri **main isolate'ta** çalışıyor. 200-500MB'lık bir manga cildi bellek şişirir; extraction sırasında yükleme animasyonu bile donar.

**Düzeltme:** Extraction'ı `Isolate.run()` içine taşı (dosya yolu + hedef klasör parametre, dönüşte sayfa yolları listesi). `archive` paketinin `InputFileStream` + `ZipDecoder().decodeStream(...)` yolunu kullanarak zip'i belleğe komple almadan aç. Natural sort (`_compareNatural`) aynen isolate'a taşınır.

---

## P1 — Önemli (okuyucu kalitesini belirgin etkileyen)

### 7. EPUB: Sayfa sayıları her açılışta yeniden hesaplanıyor (locations cache yok)
**Dosyalar:** `packages/sakura_epub/lib/assets/webpage/html/epubView.js` (satır 1025: `book.locations.generate(1600)`), `epub_controller.dart`, `reader_provider.dart`

- Her kitap açılışında locations sıfırdan üretiliyor; büyük kitapta sayfa numarası / progress bar saniyeler boyunca 0 kalıyor.

**Düzeltme:** epub.js'in hazır API'si var: ilk üretimden sonra `book.locations.save()` çıktısını (JSON string) yeni bir JS handler ile Flutter'a gönder → `book_{id}_locations` olarak dosyaya/prefs'e kaydet. Sonraki açılışta `loadBook`'a parametre olarak geçir → `book.ready` içinde varsa `book.locations.load(json)`, yoksa `generate(1600)`. Açılışta sayfa sayısı anında gelir.

### 8. EPUB: Highlight'lar kalıcı değil
**Dosyalar:** `lib/modules/reader/views/reader_view.dart` (`_highlight`), `lib/core/services/notes_store.dart`

- `addHighlight(cfi: ...)` sadece o oturumda WebView'a çiziliyor; `NotesStore` **CFI'yi kaydetmiyor** (yalnız metin). Kitap yeniden açıldığında tüm highlight'lar sayfadan kaybolur.

**Düzeltme:** `ReadingNote` modeline `cfi` (ve `bookId`) alanı ekle, `_highlight` kaydederken CFI'yi de yaz. `ReaderProvider.onEpubLoaded` (rendition kurulumunda) o kitabın notlarını dolaşıp `epubController.addHighlight(cfi: ...)` ile yeniden uygula. Not/highlight silinince `removeHighlight` çağır.

### 9. TÜMÜ: `hashCode` ile bookId üretimi — ilerleme/yer imi kaybı riski
**Dosyalar:** `lib/modules/library/offline_library_screen.dart:61-68`, `lib/modules/library/widgets/own_books_tab.dart:56-63`, `lib/modules/book_detail/book_detail_screen.dart:~90`, `lib/modules/home/widgets/bundled_books_debug_screen.dart:94-98`, PDF/CBZ ekranlarındaki `widget.filePath.hashCode` fallback'leri

- Progress/bookmark anahtarları `book.id.hashCode` / `filePath.hashCode` üzerine kurulu. Dart'ta `hashCode` **çalıştırmalar arası stabil olmak zorunda değil** (özellikle Dart sürüm yükseltmelerinde değişebilir) → bir güncellemede tüm okuma ilerlemeleri ve yer imleri "kaybolabilir".

**Düzeltme:** Anahtar olarak string id'nin kendisini kullan. En az invaziv yol: reader ekranlarının `bookId` parametresini `String`'e çevirmek yerine, stabil bir hash kullan (ör. `crypto` zaten bağımlılıkta: `md5.convert(utf8.encode(id))` ilk 8 byte → int). Tek bir `int stableBookKey(String id)` helper'ı yazıp `hashCode` geçen tüm çağrı noktalarında onu kullan.

### 10. EPUB: `checkEpubLoaded` yanlış şeyi kontrol ediyor
**Dosya:** `packages/sakura_epub/lib/src/epub_controller.dart` (satır 389)

- Sadece `webViewController == null` bakıyor; WebView hazır ama **kitap henüz yüklenmemişken** çağrılan komutlar (tema, font, display...) JS'te sessizce kayboluyor (rendition undefined).

**Düzeltme:** Controller'a `bool _bookLoaded` flag'i ekle (displayed handler'ında set edilir); yüklenmeden gelen komutları ya at (log'la) ya da küçük bir kuyrukta bekletip `onEpubLoaded`'da uygula.

### 11. PDF: Ham hata mesajı kullanıcıya gösteriliyor
**Dosya:** `lib/modules/reader/views/pdf_reader_screen.dart` (satır 343-346)

- `onError: (error) => _error = error.toString()` — kullanıcı "PlatformException(...)" gibi teknik metin görüyor. Şifreli PDF'ler de bu yolla patlıyor.

**Düzeltme:** Hata metnini kullanıcı dostu genel bir mesaja çevir (`ReaderStrings`'e "Bu PDF açılamadı, dosya bozuk veya şifreli olabilir" tarzı yeni string); ham hatayı sadece `log`'a yaz.

### 12. CBZ: Restore edilen sayfa clamp edilmiyor
**Dosya:** `lib/modules/reader/views/cbz_reader_screen.dart` (`_bootstrap` / `_extract`)

- Kaydedilmiş `_initialPage`, dosya değiştiyse/az sayfalıysa `itemCount`'u aşabilir → boş görünüm.

**Düzeltme:** Extraction bitince `_initialPage = _initialPage.clamp(0, _totalPages - 1)` uygula, sonra controller'ı o sayfaya konumlandır.

### 13. CBZ: Bellek — sayfalar tam çözünürlükte decode ediliyor
**Dosya:** `lib/modules/reader/views/cbz_reader_screen.dart` (satır 407)

- `Image.file(File(path), fit: _fit)` — 3000-4000px taranmış sayfalar tam boy decode olur; PageView komşu sayfaları da tutunca düşük RAM'li cihazlarda kasma/OOM.

**Düzeltme:** `cacheWidth: (MediaQuery.width * devicePixelRatio).round()` ver (zoom kalitesi için ~2x tolere edilebilir). İsteğe bağlı: bir sonraki sayfayı `precacheImage` ile ısıt.

### 14. CBZ: Extraction cache sınırsız büyüyor
**Dosyalar:** `lib/modules/reader/views/cbz_reader_screen.dart` (`_cacheDirFor`), `lib/core/services/own_books_store.dart` (`remove`)

- `cbz_pages/<hash>` klasörleri hiç silinmiyor; kitap kütüphaneden silinse bile diskte kalıyor.

**Düzeltme:** `OwnBooksStore.remove()` içinde, silinen kitap CBZ ise aynı hash ile cache klasörünü de sil (hash fonksiyonunu ortak bir helper'a çıkar). İsteğe bağlı: uygulama açılışında toplam boyut belli bir eşiği aşarsa en eski klasörleri temizle.

### 15. UX tutarsızlığı: Top bar'daki yer imi ikonu
**Dosyalar:** `lib/modules/reader/views/reader_view.dart` (satır 141: `onBookmark: () => _showBookmarks(...)`), `pdf_reader_screen.dart` / `cbz_reader_screen.dart` (`onBookmark: _toggleBookmark`)

- Aynı ikon EPUB'da **yer imleri listesini açıyor**, PDF/CBZ'de **yer imini aç/kapat yapıyor**. Kullanıcı için kafa karıştırıcı.

**Düzeltme (öneri):** Üçünde de tek dokunuş = toggle; listeye erişim alt bardan (EPUB'da bookmarks sheet'e alt bardan bir giriş ekle ya da uzun basış = liste).

---

## P2 — İsteğe bağlı iyileştirmeler (P0/P1 bittiyse)

### 16. PDF motorunu `pdfrx`'e taşımayı değerlendir (büyük ama en etkili iş)
- `flutter_pdfview` bakımı zayıf ve özellik seti dar: **arama yok, TOC/outline yok, metin seçimi yok**, zoom + `swipeHorizontal` kombinasyonu sorunlu.
- `pdfrx` (pdfium tabanlı, aktif bakımda): metin arama, metin seçimi, outline (bölüm listesi), link tıklama, şifreli PDF desteği, esnek zoom. PDF okuyucuyu EPUB kalitesine yaklaştırır ve #4/#11'deki sorunları kökten çözer. Mevcut `PdfBottomBar`/sheet'ler aynen kullanılabilir.

### 17. EPUB: Kitabın base64 ile JS köprüsünden taşınması
- Dosya tamamen okunup base64'e çevrilip (%33 büyüme) `callAsyncJavaScript` argümanı olarak geçiyor; JS'te byte-byte `atob` döngüsü var (`epubView.js` satır 63-71). Görsel ağırlıklı büyük EPUB'larda açılışı yavaşlatan ana etken.
- Orta vadede: kitabı `getApplicationDocumentsDirectory` altına açıp InAppWebView'ın custom scheme handler'ı ile dosyadan servis etmek (base64 köprüsünü kaldırır). En azından bilinen sınırlama olarak kayıtta dursun.

### 18. Streak sayacı arka planda da çalışıyor
- `Timer.periodic` (EPUB/PDF/CBZ, 30sn ping) uygulama arka plandayken de tetiklenebilir → "okuma süresi" şişer. `WidgetsBindingObserver` ile `paused`'da timer'ı durdur, `resumed`'da başlat.

### 19. CBZ: Zoom'dayken sayfa kaydırma çakışması + double-tap zoom yok
- `InteractiveViewer` zoom > 1 iken `PageView` swipe'ı araya girebiliyor. `TransformationController` dinleyip zoom > 1 iken `PageView.physics: NeverScrollableScrollPhysics()` yap. Double-tap ile 2x zoom ekle (manga okuyucularda standart).

### 20. CBZ: Manga için sağdan-sola okuma yönü
- Ayarlara "Okuma yönü: LTR/RTL" ekle → `PageView(reverse: true)`. Japon mangaları için standart beklenti.

### 21. iOS'ta `cbz` uzantısı file_picker'da seçilemeyebilir
**Dosya:** `lib/modules/library/widgets/own_books_tab.dart:40`
- `allowedExtensions: ['cbz']` iOS'ta bilinen bir UTType'a eşlenmeyebilir → dosya seçicide cbz'ler gri görünebilir. Gerçek cihazda test et; sorun varsa iOS için `FileType.any` + seçim sonrası uzantı doğrulaması yap.

### 22. Format tespiti içerik imzasıyla doğrulanabilir
- Şu an yalnız uzantıya bakılıyor (`own_books_store.dart:41-46`, bilinmeyen her şey EPUB sayılıyor). Picker 3 uzantıyla sınırlı olduğundan şimdilik yeterli; istenirse ilk 4 byte kontrolü (`PK` = zip/epub/cbz, `%PDF`) eklenebilir.

### 23. Kozmetik lint temizliği
- `flutter analyze` 134 info veriyor (çoğu `directives_ordering`, `prefer_const_constructors`). Reader dosyalarındakiler tek seferde temizlenebilir; davranışa etkisi yok.

---

## Önerilen uygulama sırası (Sonnet için)

1. **#1** CFI ile devam etme (en görünür kazanç, küçük değişiklik)
2. **#2** EPUB hata durumu + **#3** PopScope
3. **#5** CBZ crash + **#12** clamp (küçük, hızlı)
4. **#4** PDF nightMode ayrıştırma (tek satırlık davranış düzeltmesi + settings sheet metni)
5. **#6** CBZ isolate extraction
6. **#7** locations cache, **#8** highlight kalıcılığı
7. **#9** stabil bookId (dikkat: mevcut kayıtlı ilerlemelerle uyumluluk için tek seferlik migration düşünülebilir — eski `hashCode` anahtarı varsa yeni anahtara kopyala)
8. Kalan P1/P2 maddeleri

### Test kontrol listesi (her düzeltmeden sonra)
- [ ] Büyük bir EPUB aç (assets/books içindeki Sarah J. Maas epub'ı), kapat, tekrar aç → **aynı sayfadan** devam ediyor mu?
- [ ] Uzantısı .epub yapılmış bozuk bir dosya aç → hata ekranı geliyor mu (sonsuz loading yok)?
- [ ] Android geri jesti ile çık → ilerleme kaydedildi mi?
- [ ] PDF'te koyu zemin aç → manga sayfası negatif görünmüyor mu? (Death Note pdf'leri ile)
- [ ] CBZ açılırken hemen geri çık → crash yok mu?
- [ ] Büyük CBZ açarken animasyon akıcı mı (donma yok mu)?
- [ ] Highlight ekle, kitabı kapat-aç → highlight sayfada duruyor mu?
