# Aýkitap — Shipaton 2026 Kalan Görevler ve Yarın Devam Planı

> Son güncelleme: 27 Ağustos 2026  
> Amaç: Aýkitap'ı güvenli satın alma, ölçülebilir performans, iyi bir demo ve
> eksiksiz mağaza yayınıyla Shipaton başvurusuna hazır hâle getirmek.  
> Önceki geniş plan: [`SHIPATON_2026_IMPLEMENTATION_PLAN.md`](./SHIPATON_2026_IMPLEMENTATION_PLAN.md)

## 1. Shipaton uygunluğu ve hedef kategoriler

- Aýkitap'ın ilk Google Play yayını **11 Ağustos 2026** olduğu için resmi
  **1 Ağustos–30 Eylül 2026** ilk yayın aralığının içindedir. Yeni bundle ID
  gerekmez.
- Son başvuru: **30 Eylül 2026, 23:45 PDT**.
- Başvuru için RevenueCat SDK ile çalışan en az bir gerçek uygulama içi satın
  alma veya abonelik bulunmalıdır.
- En güçlü hedefler:
  1. **RevenueCat Design Award:** kitap keşfi, Card 4 tasarımı, Hero geçişleri,
     reader ve okunma/streak deneyimi.
  2. **HAMM Award:** TMT cüzdan + ülke dışı Store/RevenueCat abonelik modeli.
  3. **RevenueCat Peace Prize:** Türkmence içerik, yerel yazarlar, offline okuma
     ve bilgiye erişim.
  4. **Keep Them Coming Back (OneSignal):** streak, okuma hatırlatmaları ve
     anlamlı geri dönüş kampanyaları.
  5. **#BuildInPublic:** geliştirme süreci, sorunlar ve ölçülen iyileştirmeler
     düzenli paylaşılırsa.
- **Best App for Galaxy şu an hedef değil.** Foldable/Galaxy özel çalışmaları
  kullanıcı kararıyla kapsamdan çıkarıldı.

Resmi kaynaklar:

- [Shipaton 2026 ana sayfa ve kategoriler](https://revenuecat-shipaton-2026.devpost.com/)
- [Shipaton resmi kuralları](https://revenuecat-shipaton-2026.devpost.com/rules)

## 2. Şu anda tamamlananlar

### RevenueCat mobil ve dashboard

- [x] Flutter RevenueCat SDK entegrasyonu mevcut.
- [x] Android ve iOS production **public SDK key** değerleri platforma göre
  seçiliyor. Public key'ler belgeye tekrar yazılmayacak; secret key mobil
  uygulamaya hiçbir zaman konulmayacak.
- [x] Entitlement adı Flutter ve backend tarafında ASCII güvenli biçimde
  **`premium`** olarak eşitlendi.
- [x] RevenueCat'te Android aylık/yıllık ve iOS aylık/yıllık olmak üzere dört
  ürün `premium` entitlement'a bağlandı.
- [x] RevenueCat `default` offering aktif ve iki package içeriyor:
  `$rc_monthly` ile `$rc_annual`.
- [x] Android `MainActivity`, satın alma SDK uyumluluğu için
  `FlutterFragmentActivity` kullanıyor.
- [x] Satın alma, restore ve entitlement değişikliklerini dinleyen mobil akış
  mevcut.
- [x] Satın alma/restore başarı diyaloğu mevcut.
- [x] İlgili RevenueCat Flutter testleri geçti.
- [x] Backend RevenueCat testleri yerelde geçti; canlıya dağıtım yapılmadı.

### Auth, bildirim ve temel ürün

- [x] Firebase Google giriş yerel backend ile çalıştı.
- [x] Firebase Auth kullanıcısı backend hesabına dönüştürülüyor.
- [x] OneSignal Android ve iOS cihazları subscribed görünüyor.
- [x] OneSignal external user eşleme ve tag senkronizasyonu mevcut.
- [x] FCM temel push teslimi korunuyor; OneSignal kampanya/retention katmanı.
- [x] Card 4 numaralı kitap tasarımı uygulandı.
- [x] Home kartları ile kitap detay cover'ı arasında Hero altyapısı mevcut.
- [x] Home bölüm/kart stagger girişleri mevcut.
- [x] Streak/hedef tamamlama efektleri koşullu olarak mevcut.
- [x] Offline/online durum mikro etkileşimi mevcut.
- [x] Reader yalnız reader içinde yatay yönü destekliyor; bütün uygulamayı yatay
  yapmak kapsamda değil.

## 3. Yarın P0 — RevenueCat'i gerçekten satın alınabilir hâle getir

Bu bölüm bitmeden “RevenueCat entegrasyonu tamamlandı” denmemeli.

### 3.1 RevenueCat dashboard temizliği

- [ ] Eski `aykitap_plus` entitlement içindeki ürünleri detach et ve artık
  kullanılmıyorsa entitlement'ı inactive/delete yap. Tek aktif kaynak
  **`premium`** olsun.
- [ ] RevenueCat **Paywalls** bölümünde `default` offering için bir paywall
  oluştur.
- [ ] Paywall'da aylık ve yıllık package'ların ikisinin de göründüğünü kontrol
  et.
- [ ] Restore purchases, Terms ve Privacy bağlantılarını ekle.
- [ ] Paywall'ı **Publish** et ve `default` offering'e bağla.
- [ ] RevenueCat Customer Center kullanılacaksa restore/cancel/manage
  subscription ekranlarını yapılandır; kullanılmayacaksa uygulamadaki native
  restore/manage akışını cihazda doğrula.

### 3.2 Backend developer canlı dağıtımı

Canlı API şu an RevenueCat endpoint'lerini sunmuyor; kod yerelde olsa bile
deployment yapılmadan mobil uygulamanın backend senkronu çalışmaz.

- [ ] Güncel backend branch'ini sunucuya deploy et.
- [ ] Production database migration'larını çalıştır.
- [ ] Production ortamında aşağıdakileri ayarla:
  - `REVENUECAT_ENABLED=true`
  - `REVENUECAT_SECRET_API_KEY=sk_...`
  - `REVENUECAT_WEBHOOK_AUTH=<uzun-rastgele-secret>`
  - `REVENUECAT_ENTITLEMENT_ID=premium`
  - `REVENUECAT_PROJECT_ID=<RevenueCat-project-id>`
- [ ] Secret API key ve webhook secret hiçbir mobil dosyaya, loga veya Git
  commit'ine eklenmesin.
- [ ] RevenueCat dashboard webhook URL'sini
  `https://aykitap.com.tm/api/v1/revenuecat/webhook` olarak ekle ve auth
  header'ını backend ile aynı ayarla.
- [ ] Admin panelde TMT ve USD fiyat/product mapping alanlarını doldur:
  - Türkmenistan: TMT cüzdan/yerel ödeme.
  - Diğer ülkeler: mağazanın lokal para birimi; ekranda fiyat RevenueCat/Store
    package bilgisinden gelsin, elle `$` string'i yazılmasın.
- [ ] `GET /api/v1/revenuecat/config` canlıda 200 dönsün.
- [ ] Top-up products ve kitap store-product endpoint'leri canlıda 200 dönsün.
- [ ] RevenueCat test webhook'u gönder; aynı event ikinci kez gönderildiğinde
  idempotent olduğunu doğrula.
- [ ] Webhook sonrası kullanıcının premium durumu admin panel ve API'de doğru
  görünsün.

### 3.3 Ülke ve fiyat yönlendirmesi

Firebase ile açılan test hesabında `country=null` gözlendi. Bu durumda backend
kullanıcıyı `UNKNOWN/consumption_only` kabul edebilir ve uluslararası satın alma
seçeneklerini gizleyebilir.

- [ ] Uluslararası kayıt/giriş tamamlanınca ülke seçimi iste veya güvenilir bir
  profil güncelleme adımı ekle.
- [ ] Türkmenistan seçilirse TMT akışı göster.
- [ ] Diğer ülkelerde RevenueCat/Store akışı göster.
- [ ] VPN/IP tek başına kalıcı ülke kaynağı olmasın; kullanıcı seçimi profilde
  saklansın ve gerektiğinde değiştirilebilsin.

### 3.4 Android sandbox testi

- [ ] Google Play Console'da tester hesabını license tester/internal testing'e
  ekle.
- [ ] Uygulamayı Play internal/closed track'ten yükle; sideload APK ile gerçek
  Play Billing testi yapılmasın.
- [ ] Release/profile çalıştırmada `Wrong API Key` diyaloğunun artık çıkmadığını
  doğrula.
- [ ] Aylık paket fiyatı Store'dan geliyor.
- [ ] Yıllık paket fiyatı Store'dan geliyor.
- [ ] Satın alma tamamlanınca `premium` aktif oluyor ve kilitli içerik açılıyor.
- [ ] Uygulamayı kapat/aç: premium erişim korunuyor.
- [ ] Çıkış/giriş: aynı backend kullanıcısına entitlement geri bağlanıyor.
- [ ] Restore purchases çalışıyor.
- [ ] İptal/expiry sandbox senaryosunda erişim doğru kapanıyor.
- [ ] Aynı satın alma backend webhook ve mobil CustomerInfo tarafından iki kez
  hak kazandırmıyor.

### 3.5 iOS sandbox/TestFlight testi

- [ ] Xcode → Runner → Signing & Capabilities içinde **In-App Purchase** ekli.
- [ ] App Store Connect Paid Apps Agreement, vergi ve banka bilgileri tamam.
- [ ] Sandbox tester ile aylık/yıllık satın alma ve restore test edildi.
- [ ] App Store ürünleri uygulama sürümüyle review'a gönderildi; “Ready to
  Submit” tek başına production satış için yeterli kabul edilmesin.
- [ ] TestFlight'ta fiyat, satın alma, restore, relaunch ve logout/login testleri
  Android ile aynı şekilde yapıldı.

## 4. Yarın P0 — uygulama performans optimizasyonu

### 4.1 Önce ölç: debug build'e bakarak karar verme

- [ ] Samsung A34 gibi orta segment gerçek cihazda `flutter run --profile` ile
  ölçüm yap.
- [ ] Aynı senaryoyu üç kez kaydet:
  1. soğuk açılış → Home,
  2. Home hızlı yatay/dikey scroll,
  3. kitap detayı → reader açılışı ve 10 sayfa çevirme.
- [ ] Flutter DevTools Performance ve Memory kayıtlarını sakla.
- [ ] Ölçülecek değerler:
  - ilk Flutter frame süresi,
  - splash sonrası Home kullanılabilir olma süresi,
  - UI/raster frame p90/p95,
  - 100 ms üzeri donmalar,
  - Home scroll sırasında bellek ve GC sayısı,
  - kitap detay ve reader açılış süreleri,
  - indirilen JSON ve görsel boyutları.

### 4.2 Doğrulanmış P0 sorun: başlangıç ilk kareyi gereksiz bekliyor

Mevcut `main.dart`, `runApp()` öncesinde RevenueCat `init()` çağrısını await
ediyor. Bu metot yalnız SDK configure etmiyor; ayrıca `getCustomerInfo()` ile
network/store round-trip yapıyor. Tema/locale/analytics, son okunan kitap ve
streak yüklemeleri de ilk kare öncesinde sırayla bekleniyor.

- [ ] `runApp()` mümkün olduğunca erken çağrılsın.
- [ ] RevenueCat configure ile uzak `getCustomerInfo()` yenilemesini ayır.
- [ ] Son bilinen premium durumunu güvenli yerel cache'den hydrate et; uzak
  doğrulamayı ilk kareden sonra asenkron yap.
- [ ] Cache premium gösteriyorsa expiry/restore kurallarıyla yanlış kalıcı erişim
  oluşturma; server/CustomerInfo sonucu gelince tek kaynak katmanı güncellensin.
- [ ] Tema/locale gibi zorunlu küçük yerel okumaları mümkünse paralel çalıştır.
- [ ] Widget, streak ve last-read senkronunu ilk kareden sonra çalıştır; native
  widget verisinin gecikmesi uygulama açılışını bloklamasın.
- [ ] Değişiklikten önce/sonra cold-start ölçümünü belgeye ekle.

### 4.3 Doğrulanmış P0 sorun: zorunlu 2,6 saniye splash

`SplashScreen._bootstrap()` her açılışta `Future.delayed(2600ms)` bekliyor. Bu,
hızlı cihazda bile kullanıcıya ağır uygulama hissi verir.

- [ ] Minimum splash süresini kaldır veya ilk açılışta yaklaşık 600–900 ms,
  sonraki açılışlarda 250–500 ms seviyesinde ölçerek ayarla.
- [ ] Veri hazırsa kullanıcıyı sırf animasyon bitsin diye 2,6 saniye tutma.
- [ ] Veri hazır değilse sonsuz skeleton yerine zaman aşımı + retry/offline state
  göster.
- [ ] Splash animasyonu ile Home prefetch paralel kalabilir.

### 4.4 Doğrulanmış P0 sorun: görsel cache aşırı büyük

`main.dart` decoded image cache'i **3000 görsel / 200 MB** yapıyor. Bu değer
özellikle orta segment Android cihazda heap baskısı, daha sık GC ve scroll jank
oluşturabilir.

- [ ] Profile ölçümünden sonra telefon için başlangıç deneyi olarak yaklaşık
  500–800 entry ve 64–96 MB aralığını test et; tablet için ayrı bütçe gerekirse
  window size class ile belirle.
- [ ] Değerleri körlemesine sabitleme; Home scroll ve geri dönüşte placeholder
  flash ile memory/GC sonucunu birlikte karşılaştır.
- [ ] `NetworkCoverImage` portrait cover için genişliği
  `max(width, height)` üzerinden hesaplamasın. Gerçek çizim width/height ve DPR
  ile doğru `memCacheWidth`/`memCacheHeight` üret.
- [ ] Banner, avatar, cover ve tam ekran backdrop için ayrı thumbnail/decode
  boyutları kullan.
- [ ] Backend/CDN mümkünse küçük/orta/büyük görsel varyantı veya resize parametresi
  sunsun; Home'da orijinal tam çözünürlük indirilmesin.

### 4.5 P1 — Home veri ve rebuild maliyeti

- [ ] `/collections/all` response boyutunu ve decode süresini ölç. Çok büyükse
  Home endpoint'i yalnız görünen ilk N kitap + `nextCursor` dönsün.
- [ ] “See all” ekranı ayrı pagination ile kalan kitapları yüklesin.
- [ ] Banner ve collection cache için ETag/If-None-Match veya kontrollü TTL ekle.
- [ ] `HomeDataService` tek notify ile bütün Home'u gereksiz rebuild ediyorsa
  `Selector`/küçük listenable'lara ayır.
- [ ] Uzun collection listelerinde sadece viewport yakınını üret; eager widget
  ve görsel oluşturma yapma.
- [ ] Ağdan gelen model parsing ölçümde 16 ms frame'i aşıyorsa büyük JSON decode'u
  isolate'a taşı.
- [ ] Hero sırasında source ve destination cover aynı decode boyutunu kullanmalı;
  uçuş sırasında yeniden download/decode yapılmamalı.

### 4.6 P1 — Reader performansı

- [x] EPUB base64 encode işlemi `compute` kullanıyor.
- [x] Büyük CBZ extract işlemi isolate kullanıyor.
- [ ] Reader `onRelocated` her sayfada tüm `ReaderProvider` dinleyicilerini
  rebuild ediyor; yalnız değişen page/progress parçalarını `ValueNotifier` veya
  selector ile ayırmayı ölç ve uygula.
- [ ] Sayfa logları debug'da çok gürültülü ise throttle et; release'de kapalı
  olduğundan emin ol.
- [ ] Progress disk/backend yazımı 2 saniye debounce olarak korunmalı; sayfa
  başına network çağrısı yapılmamalı.
- [ ] EPUB location generation cache'i kitap değişmedikçe yeniden üretilmesin.
- [ ] PDF/CBZ/EPUB açılışında dosya okuma, unzip ve parsing ana isolate'ta uzun
  blok oluşturmadığını Timeline ile doğrula.
- [ ] Reader WebView yeniden build edildiğinde kitabı baştan yüklememeli; tema,
  sheet ve sayaç değişiklikleri WebView key'ini değiştirmemeli.

### 4.7 P1 — log, güvenlik ve release maliyeti

- [x] API interceptor yalnız `kDebugMode` altında ekleniyor.
- [ ] Debug logunda Firebase `idToken`, access token, FCM/APNS token ve auth
  header tam basılmasın; redaction ekle. Bu performanstan önce güvenlik işidir.
- [ ] Büyük response'lar yalnız endpoint/status/byte/time olarak loglansın;
  pretty JSON yazdırılmasın.
- [ ] Release/profile modunda RevenueCat debug logging ve ayrıntılı reader/network
  loglarının kapalı olduğunu doğrula.
- [ ] Backend gzip/brotli ve HTTP cache header'larını kontrol et.

### 4.8 P2 — asset, paket ve arka plan işleri

- [ ] `assets/` şu an yaklaşık **7,9 MB**; 1 MB üzerindeki Play screenshot gibi
  runtime'da gerekmeyen görselleri app bundle'dan çıkar veya WebP/AVIF'e çevir.
- [ ] Kullanılmayan font weight'leri ve büyük animasyon dosyalarını temizle.
- [ ] `flutter build appbundle --analyze-size` ve iOS size report ile en büyük
  paketleri listele. Bu işlem kullanıcı tarafından yayın öncesi yapılabilir.
- [ ] Analytics, push, OneSignal, device fingerprint ve widget sync aynı anda
  boot CPU/network yarışı oluşturuyorsa ilk frame sonrası sıralı düşük öncelik
  kuyruğuna al.
- [ ] Background timer/observer'ların ekran kapalıyken ve logout sonrası doğru
  durduğunu kontrol et.

### 4.9 Performans kabul kapıları

Rakamlar profile build ve gerçek cihazda ölçülecek; debug build kabul testi değil.

- [ ] Orta segment Android cold-start: ilk Flutter frame hedefi **≤ 1,5 sn**,
  Home kullanılabilir hedefi **≤ 2,5 sn** (ağ çok yavaşsa cache/offline state).
- [ ] 60 Hz cihazda Home scroll p95 UI ve raster frame **16,7 ms altında**;
  tekil pahalı frame'ler raporlanmalı.
- [ ] Normal Home scroll sırasında 100 ms üzeri gözle görülür donma kalmamalı.
- [ ] Home → detail Hero uçuşunda placeholder flash ve cover sıçraması olmamalı.
- [ ] Reader ilk sayfa açılışı cached yerel EPUB için hedef **≤ 2 sn**.
- [ ] 10 dakika okuma/scroll sonrasında bellek sürekli yükselmemeli; ekrandan
  çıkınca büyük cover/WebView kaynakları geri bırakılmalı.

## 5. Tasarım ve animasyon kalan doğrulamalar

Kodda animasyon sınıfının bulunması tek başına tamamlandı demek değildir. Aşağıdaki
akışlar profile build'de gerçek cihaz videosuyla doğrulanacak.

- [ ] Home normal kitap kartı → detay Hero: cover source konumundan detaydaki
  cover konumuna akıyor, sola/ortaya yanlış sıçramıyor.
- [ ] Card 4 numaralı kitap → detay Hero: numara uçuşa karışmıyor; yalnız cover
  uçuyor ve detay layout'u doğru hizadan karşılıyor.
- [ ] Collection/genre/search/library/note yazar/kitap giriş noktalarının her
  birinde benzersiz Hero tag var; duplicate Hero exception yok.
- [ ] Geri swipe/back sırasında reverse Hero akıcı.
- [ ] Home stagger ilk yüklemede fark edilir ama yavaşlatmaz; her rebuild'de
  yeniden oynamaz.
- [ ] Streak/hedef efekti yalnız eşik ilk kez tamamlandığında oynar; her Home
  açılışında tekrar etmez.
- [ ] Satın alma başarı/unlock efekti yalnız doğrulanmış purchase/restore sonrası
  oynar; cancel/error durumunda oynamaz.
- [ ] `MediaQuery.disableAnimations` veya reduced-motion durumunda Hero dışı
  dekoratif hareketler azaltılır/atlanır.
- [ ] Animasyonlar yalnız `opacity` ve `transform` ağırlıklı çalışır; büyük blur,
  layout ve sürekli shadow animasyonu scroll sırasında kullanılmaz.

## 6. Shipaton demo ve başvuru paketi

Resmi başvuruda gerekenler:

- [ ] Uygulamanın özellik ve işlevlerini anlatan İngilizce metin.
- [ ] Gerçek cihazda çalışan, **en fazla 2 dakika** YouTube/Vimeo public demo.
- [ ] Google Play/App Store/Samsung Store'da tamamen yayınlanmış uygulama URL'si.
- [ ] 1024×1024 app icon.
- [ ] Cihaz çerçevesiz en az bir **1179×2556** screenshot.
- [ ] Jürinin premium'u açabilmesi için free trial veya promo code.

Önerilen 2 dakikalık demo akışı:

1. **0:00–0:15:** Türkmence kitap erişimi problemi ve Aýkitap ana ekranı.
2. **0:15–0:40:** Card 4/kitap keşfi, yazarlar, Hero ile kitap detayı.
3. **0:40–1:05:** Offline indirme, reader, yatay okuma, streak ve widget sonucu.
4. **1:05–1:30:** RevenueCat paywall, aylık/yıllık gerçek Store fiyatı, sandbox
   purchase ve anlık premium unlock.
5. **1:30–1:45:** TMT yerel model + uluslararası Store modeli ve admin senkronu.
6. **1:45–2:00:** OneSignal anlamlı okuma hatırlatması ve sosyal etki özeti.

Ek kanıtlar:

- [ ] RevenueCat dashboard: `premium`, products, `default` offering ve aktif
  müşteri entitlement ekran görüntüsü.
- [ ] Android ve iOS satın alma/restore kısa ekran kayıtları.
- [ ] OneSignal cihaz/subscription ve örnek streak kampanyası.
- [ ] Performans before/after: cold start, Home scroll ve memory ölçümleri.
- [ ] Privacy Policy, Terms, support email ve account deletion URL'leri çalışıyor.
- [ ] App Store/Play Data Safety ve privacy beyanları Firebase, OneSignal,
  RevenueCat ve analytics kullanımına göre güncel.

## 7. Bilerek kapsam dışında bırakılanlar

Kullanıcı kararıyla aşağıdakiler bu Shipaton sprintinin kalan görevi değildir:

- Samsung foldable özel optimizasyonu ve Best App for Galaxy hedefi.
- Native widget yeniden doğrulama/yeniden tasarım.
- Tüm uygulamayı landscape yapmak; landscape yalnız reader içinde.
- Son dark/light ve İngilizce ekran turu.
- Onboarding içinde 10 TMT açıklamasını yeniden tasarlamak.
- OneSignal dashboard'da ek kurulum testi; Android/iOS subscription zaten
  doğrulandı. Ancak Keep Them Coming Back kategorisi hedeflenirse gerçek Journey
  veya campaign kanıtı ayrıca gerekir.

## 8. Yarın uygulanacak kesin sıra

1. **Profile baseline kaydı al** — kod değiştirmeden önce cold start, Home,
   detail ve reader ölçümleri.
2. **RevenueCat dashboard'u bitir** — eski entitlement temizliği, paywall publish.
3. **Startup P0 düzeltmeleri** — 2,6 sn splash ve `runApp` öncesi RevenueCat/ağ
   beklemesini kaldır.
4. **Image P0 düzeltmeleri** — 200 MB/3000 cache ve yanlış decode boyutları.
5. **Backend deploy** — env, migration, webhook, product mapping ve canlı endpoint.
6. **Android sandbox satın alma/restore testi.**
7. **iOS sandbox/TestFlight satın alma/restore testi.**
8. **Profile ölçümü tekrarla** — before/after değerlerini bu belgeye ekle.
9. **Animasyon cihaz turu** — giriş noktaları, reverse Hero, reduced motion.
10. **Store release ve Devpost paketi** — demo, screenshot, trial/promo, metin.

## 9. Shipaton-ready bitiş tanımı

Uygulama ancak aşağıdakilerin tamamı doğruysa hazır sayılır:

- [ ] En az Android veya iOS production mağaza sürümü Shipaton tarih aralığında
  public ve açılabilir.
- [ ] RevenueCat production key + Store ürünü + `premium` entitlement gerçek
  cihazda satın alma ve restore ile çalışıyor.
- [ ] Backend webhook canlıda event kabul ediyor, doğruluyor ve idempotent
  işliyor.
- [ ] TMT ve uluslararası Store yolları doğru kullanıcıya doğru fiyatı gösteriyor.
- [ ] Cold start/Home/reader profile ölçümleri kabul kapılarını karşılıyor veya
  kalan sapmalar açıkça belgelenmiş.
- [ ] Kritik crash, ANR, ödeme kilidi, duplicate purchase/unlock veya token logu
  yok.
- [ ] Jüri free trial/promo code ile premium özelliği açabiliyor.
- [ ] İki dakikalık demo, screenshot, app icon, mağaza linki ve açıklama Devpost'a
  yüklendi.

