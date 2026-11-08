# Aýkitap Journey — Shipaton 2026 Uygulama Planı

> Amaç: Aýkitap'ın var olan güçlü e-kitap okuyucusunu; estetik, erişilebilir,
> alışkanlık kurduran ve gelir modeli net olan **Shipaton uygulamasına**
> dönüştürmek. Bu belge, her bölümün Sonnet'e ayrı ayrı verilebilmesi için
> uygulanabilir görevler halinde yazılmıştır.

## Uygulama iş bölümü

- **Sonnet:** English localization, theme tokenları, gradient icon badge, profil
  light-theme düzeni ve yazar kartlarının statik UI'sı. Ayrı, uygulanabilir
  promptlar: [`SONNET_TRANSLATION_THEME_TASKS.md`](SONNET_TRANSLATION_THEME_TASKS.md).
- **Codex:** Hero/route geçişleri, AnimationController/gesture davranışları,
  reader motion, streak kutlaması, motion performansı ve effect doğrulaması.
- **Sonra birlikte:** RevenueCat, OneSignal, foldable, yayın ve Devpost teslimi.

## 0. Önce uygunluk ve yayın kararı

### Kritik kural

Shipaton'a sunulacak uygulamanın ilk herkese açık mağaza sürümü **31 Temmuz -
30 Eylül 2026** arasında yayınlanmış olmalıdır. Daha önce App Store, Google
Play veya Galaxy Store'da yayınlanmış bir uygulamanın yalnızca güncellenmiş
sürümü kabul edilmez. Uygulama ABD'den indirilebilir olmalı; jüri için ücretsiz
deneme veya premium'u açan promo kod sağlanmalıdır.

Kaynak: [Shipaton resmi kuralları](https://revenuecat-shipaton-2026.devpost.com/rules).

### Karar

- Mevcut `com.aykitap.aykitap` uygulamasının Google Play ilk çıkış tarihi
  **11 Ağustos 2026**. Bu, Shipaton yayın penceresinin içindedir; dolayısıyla
  aynı uygulama Shipaton'a uygundur ve yeni bundle ID gerekmez.
- Bu, uygulamanın 31 Temmuz 2026'dan önce App Store, Google Play veya Galaxy
  Store'da başka bir herkese açık sürümünün bulunmadığı varsayımıyla geçerlidir.
- Aýkitap Journey, mevcut Aýkitap'ın Shipaton sunum başlığı ve ürün hikâyesidir;
  ayrı bir mağaza uygulaması değildir.
- Bundan sonraki güncellemeler (RevenueCat, tasarım, İngilizce, OneSignal ve
  foldable) mevcut uygulamanın yeni sürümleri olarak güvenle yayınlanabilir.
- Ürün hikâyesi: **Turkmence okuma alışkanlığı + kültürel keşif + offline
  okuma yolculuğu.**
- Kitap kapakları, metinleri ve yazar verileri için yayınlama/dağıtım hakkı
  doğrulanmalı. Başvurudaki işin sahibi ekip olmalıdır.

## 1. Hedef kategoriler

Bir proje birden fazla normal ödül kategorisinde değerlendirilebilir. Tek
Influencer Award seçilebilir; bu uygulama için buna odaklanmak gerekli değil.

| Öncelik | Kategori | Neden Aýkitap Journey |
|---|---|---|
| 1 | RevenueCat Design Award | Okuma deneyimi, kitap açılışı, hareket sistemi ve foldable iki sayfa görünümü çok güçlü bir görsel hikâye verir. |
| 2 | RevenueCat Peace Prize | Turkmence içerik, yerel yazarların keşfi, offline erişim ve okuma alışkanlığı toplum faydası anlatısı oluşturur. |
| 3 | HAMM Award | Ücretsiz başlangıç kredisi + etik Premium abonelik + kitap paketleri, net gelir stratejisi sunar. |
| 4 | #BuildInPublic Award | Her hafta tasarım, kullanıcı geri bildirimi ve yayın ilerlemesi kısa videolarla paylaşılabilir. |
| 5 | Best App for Galaxy | Büyük ekran ve katlanabilir cihaz için gerçek iki sayfa okuyucu deneyimi yapılırsa ek adaylık. |
| 6 | Keep Them Coming Back | OneSignal ile düşünceli okuma yolculukları ve kampanyalar uygulanırsa ek adaylık. |

Resmi değerlendirme özellikle Design Award için yenilik, estetik, eğlenceli
animasyon ve akıcı etkileşimleri; Peace Prize için etki ve uygulanabilirliği;
HAMM için fiyatlama/paywall/gelir stratejisini istiyor. Kaynak:
[değerlendirme ölçütleri](https://revenuecat-shipaton-2026.devpost.com/rules).

## 2. Ürün hikâyesi ve ana deneyim

### Tek cümlelik pitch

**Aýkitap Journey, Turkmence kitapları offline okuyup her gün küçük bir okuma
ritüeli oluşturarak kişisel bir kültür yolculuğuna dönüştüren mobil uygulama.**

### Kullanıcı yolculuğu

1. Kullanıcı seçtiği amaçla başlar: rahatla, öğren, alışkanlık kur, yerel
   yazar keşfet.
2. Uygulama üç kitaplık kişisel "Bu haftanın yolu" önerir.
3. Kullanıcı bir kitabın kapağından doğrudan okuma ekranına akar.
4. Okunan sayfalar günün okuma halkasını ve haftalık yol haritasını doldurur.
5. Her günün hedefi tamamlanınca küçük, sakin bir kutlama görülür.
6. Ücretsiz kullanıcı 10 TMT karşılama bakiyesiyle ister bir kitabı satın
   alır, ister bir haftalık abonelik alır.
7. Premium ekranı baskıcı değil, kullanıcının o anki ihtiyacına uygun değer
   teklifini gösterir: sınırsız katalog, derin istatistik, temalar ve okuma
   yolları.

## 3. Mevcut projede bulunan temel

Halihazırda yararlanılacak parçalar:

- EPUB, PDF ve CBZ okuyucular; indirilmiş/offline kitaplar.
- Home katalog rafları, banner carousel, arama, yazar ve kitap detay ekranları.
- Okuma serisi ve geçmişi (`StreakService`).
- Notlar, yer imleri, okuma ilerlemesi ve son okunan kitap.
- Onboarding, shimmer, Lottie, splash, özel wheel navigation ve bazı geçişler.
- Bakiye/top-up, kitap satın alma ve backend tabanlı abonelik ekranı.
- Firebase Analytics ve push altyapısı.

Bu nedenle önce mevcut çalışmayı kırmadan **paylaşılan motion sistemi**
oluşturulacak; ardından yalnızca yüksek değerli anlar geliştirilecek.

## 4. Motion sistemi — bütün animasyonların kuralı

### İlkeler

- Animasyon dekorasyon değil; yön, neden-sonuç veya başarı hissi vermeli.
- Okuyucuda hareket sakin olmalı: 160–260 ms mikro etkileşim, 280–420 ms
  sayfa/ekran geçişi. Uzun ve sürekli hareket yalnızca splash/başarı anlarında.
- `MediaQuery.disableAnimations` ve azaltılmış hareket tercihi desteklenmeli.
- Her animasyon 60 fps hedeflemeli; büyük blur, tüm ekranda opacity ve ağır
  `BackdropFilter` sadece küçük alanlarda kullanılmalı.
- `AnimationController` olan her `State` içinde `dispose()` zorunlu.
- Kitap kapakları ve ağır reader widget'ları animasyon sırasında yeniden
  oluşturulmamalı; `RepaintBoundary`, `child` parametresi ve sabit anahtarlar
  kullanılmalı.

### Sonnet görevi 01 — temel motion tokenları

```text
Aýkitap Flutter projesinde merkezi bir motion sistemi oluştur. Mevcut tema
dosyalarının stilini koru. lib/core/theme/app_motion.dart ekle ve kısa/orta/uzun
süreler, standart eğriler, spring benzeri eğriler, reduced-motion yardımcıları
tanımla. Kullanıcının reduce motion tercihini MediaQuery.disableAnimations ile
uyumlu şekilde uygula. Önce yalnızca yeni dosyayı ve gerekli minimum exportları
ekle; mevcut ekranların davranışını değiştirme. flutter analyze çalıştır.
```

Önerilen tokenlar:

| Token | Değer | Kullanım |
|---|---:|---|
| `instant` | 120 ms | ikon/opacity |
| `quick` | 180 ms | press ve seçim |
| `standard` | 260 ms | kart, chip, sheet |
| `emphasis` | 420 ms | hero ve ekran girişi |
| `celebration` | 700 ms | başarı anı |
| `easeOut` | `Cubic(0.16, 1, 0.3, 1)` | giriş |
| `easeInOut` | `Cubic(0.65, 0, 0.35, 1)` | yer değiştirme |

## 4A. İngilizce dil desteği

### Yapılabilirlik ve mevcut durum

Evet, İngilizce eklemek zor değildir; ancak doğru yapılması gerekir. Projede
zaten merkezi `AppLocale`, `t(...)` çeviri yardımcısı ve modül bazlı string
dosyaları var. Şu an yalnız `tk`, `ru` ve `tr` dilleri tanımlı. İngilizce için
bir `en` enum değeri, Flutter locale listesi ve bütün kullanıcıya görünen
metinlerin İngilizce karşılığı gerekir.

**Kural:** Yeni UI metinleri doğrudan widget içine yazılmamalı; ilgili
`lib/core/localization/strings/*_strings.dart` dosyasına eklenmelidir. Böylece
Shipaton demosu ve mağaza ekran görüntüleri tamamen İngilizce hazırlanabilir.

### Sonnet görevi 01A — İngilizce altyapısı

```text
Aýkitap Flutter projesindeki AppLocale, localization_delegates ve strings_base
yapısını incele. AppLanguageCode enumuna `en` ekle; supported locales, Intl
locale mapping ve ayarlar ekranındaki dil seçicisini İngilizce için güncelle.
t(...) çeviri helper'ına opsiyonel `en` parametresi ekle; İngilizce çeviri
eksikse geçici olarak Türkmenceye düşsün. Flutter'ın Material/Cupertino
localization davranışını bozma. Uygulama ilk dilinin Türkmen kalmasını koru.
flutter analyze ve ilgili widget testlerini çalıştır.
```

### Sonnet görevi 01B — tam İngilizce içerik geçişi

```text
lib/core/localization/strings altındaki tüm kullanıcıya görünen string
dosyalarını sistematik olarak incele. Her t(...) çağrısına doğal, kısa ve tutarlı
İngilizce (`en`) karşılığını ekle; teknik kod yorumlarını ve backend alanlarını
değiştirme. Home, onboarding, auth, profile, payment, library, search, streak,
reader, offline/error ve push metinlerinin tamamını kapsa. Eksik çeviri kalıp
kalmadığını rg ile denetle. 'TMT' para birimini ve Turkmence özel adlarını
koru. flutter analyze ve çeviri fallback testlerini çalıştır.
```

### İngilizce UX kabul kriterleri

- [ ] Settings içinde `English` seçeneği görünür ve kalıcıdır.
- [ ] Uygulama yeniden başlatılınca English seçili kalır.
- [ ] Tarihler İngilizce formatlanır.
- [ ] Reader, payment ve hata diyaloglarında Türkmen/Rusça/Türkçe sızıntısı yoktur.
- [ ] Devpost videosunda cihaz dili değil uygulama dili English'tir.

## 4B. Tema ve referanstaki gradyan ikon dili

### Görsel yön

Referans görseldeki yön, Aýkitap Journey için çok uygundur:

- Açık modda çok hafif soğuk/lila arka plan, geniş beyaz kartlar ve bol boşluk.
- Profil, bakiye, abonelik, ayarlar ve notlar gibi anlam taşıyan satırlarda
  pastel gradyan daireler.
- Seçili ana navigation ikonunda yalnız **bir** güçlü turuncu → pembe → mor
  gradyan ve yumuşak glow.
- Diğer navigation ikonları ve günlük küçük ikonlar gri/tek renk kalır.
- Koyu modda aynı renkler koyu zeminde daha düşük parlaklıkla uygulanır;
  tüm ekranı neon yapmamak gerekir.

Bu yaklaşım mevcut `AppColors` ve `AppGradients.coralPurple` altyapısıyla
uyumludur. Gradyan icon teknik olarak Flutter'da `ShaderMask` ile vektör ikona
uygulanabilir; daha güvenli ve okunaklı kullanım ise ikonu tek renk bırakıp
arkasına gradyan/pastel bir daire koymaktır. Birincil action ve seçili nav
düğmesinde gradient ikon uygulanabilir.

### Önerilen renk tokenları

| Token | Renkler | Nerede |
|---|---|---|
| `journeyPrimary` | `#FF9A3D → #FF5C7D → #8D4DFF` | seçili nav, ana CTA, başarı |
| `journeySoft` | `#FFE6D5 → #FFD8E4 → #E8D9FF` | profil satırı ikon rozetleri |
| `journeyRoseViolet` | `#FF6A88 → #B34BEA` | abonelik/premium |
| `journeySunset` | `#FFB34D → #FF5F6D` | bakiye/hediye |
| `journeyInk` | `#22212A` | açık mod metni |
| `journeyMist` | `#F8F7FC` | açık mod arka plan |

### Sonnet görevi 01C — theme tokenlarının genişletilmesi

```text
Mevcut AppColors, AppGradients ve AppTheme yapısını incele. Mevcut dark/light
tercihini bozmadan Aýkitap Journey için merkezi gradyan renk tokenları ekle:
journeyPrimary, journeySoft, journeyRoseViolet, journeySunset, journeyMist ve
koyu mod karşılıkları. Hardcode renk ekleme; yalnız AppGradients/AppColors
üzerinden kullanılacak yapı kur. Ayrıca AppTheme'in light/dark sistemini
koruyarak seçili ana vurgu için gradient token erişimi tasarla. Uygulamanın
tamamını bu görevde yeniden boyama; sadece tasarım altyapısını ve küçük demo
önizlemesini ekle. flutter analyze çalıştır.
```

### Sonnet görevi 01D — reusable gradient icon badge

```text
Flutter'da tekrar kullanılabilir bir JourneyGradientIconBadge widget'ı oluştur.
Widget, HugeIcon/normal Icon child almalı; small/medium/large boyutları,
gradient türü, pastel veya güçlü varyantı, light/dark uyumu ve semanticsLabel
sağlamalı. Varsayılan tasarım referanstaki gibi: pastel gradyan daire, üzerinde
tek renk ve okunaklı ikon. Sadece primaryAction varyantında ShaderMask ile
turuncu-pembe-mor gradyan ikon destekle. Reduced-motion tercihinde glow/pulse
olmasın. Widget test ve flutter analyze ekle.
```

### Sonnet görevi 01E — profil ekranı görsel dönüşümü

```text
ProfileScreen, ProfileEntryCard ve profileIconCircle bileşenlerini incele.
Referans görseldeki ferah light profil düzeninden ilham alarak Aýkitap'ın kendi
markasına ait bir profil tasarımı uygula: yumuşak journeyMist arka plan, beyaz
yuvarlatılmış kartlar, pastel gradient icon badge'ler, seçili/önemli abonelik
satırında rose-violet vurgu ve daha temiz avatar aksiyonu. Mevcut bakiye,
abonelik, streak, ayarlar, notlar ve navigation işlevlerini koru. Koyu modda
kontrastı erişilebilir tut. Referans uygulamanın logosunu, kullanıcı adını veya
birebir görselini kopyalama. Görsel golden test veya screenshot doğrulaması ve
flutter analyze çalıştır.
```

### Sonnet görevi 01F — gradyan ana navigation ve mikro etkileşim

```text
Mevcut WheelNavBar ve MainNavScreen'i incele. Seçili ana/merkez navigation
aksiyonunda journeyPrimary turuncu-pembe-mor gradyan, kontrollü 10-14px glow ve
press scale 0.94→1.0 uygula. Seçili olmayan ikonlar nötr kalsın; her ikonu
gradyana boyama. Navigation state, gesture physics ve ağır sayfa cache
davranışını koru. Erişilebilirlik için semantics ve reduce motion fallback
ekle. Gerçek cihaz screenshot'ı ile doğrula.
```

### Tema kabul kriterleri

- [ ] Açık mod referanstaki kadar temiz, fakat Aýkitap'a özgü görünür.
- [ ] `journeyPrimary` yalnız odak/eylem/başarı noktalarında kullanılır.
- [ ] Küçük metinler, pasif ikonlar ve her kart gradyanla boyanmaz.
- [ ] Koyu modda WCAG kontrastı korunur; pastel ikon rozetleri soluklaşmaz.
- [ ] Gradient `ShaderMask` kullanılan ikonlar raster görsele dönüşmez ve
  semantics label taşır.
- [ ] Navigation glow, scroll veya reader performansını etkilemez.

## 5. Animasyon paketi — uygulanma sırası

### 0. Yazar keşfi: fotoğraf ağırlıklı editorial kartlar

**Görsel yön:** Referanstaki iki sütunlu kartlar doğru bir ilham kaynağı:
yazar fotoğrafı kartın büyük bölümünü kaplar, altındaki beyaz alanda yazar adı
ve kısa meta bilgi yer alır. Bu, mevcut küçük yuvarlak avatar satırından daha
güçlü bir keşif yüzeyi olur.

**Aýkitap'a özgü tasarım:** Referansı birebir kopyalamadan; köşeleri 16–20px
yuvarlatılmış, 2:3 oranlı büyük portre, altında iki satırlık isim, kitap sayısı
veya `Yazar` etiketi kullanılmalı. Görsel yoksa aynı ölçüde gradyan/monogram
placeholder gösterilmeli. Siyah-beyaz fotoğraf zorunlu değil; kaynak portre
nasılsa onu `BoxFit.cover` ile sunmak daha doğaldır. Yazar adı uzun olduğunda
iki satırdan sonra ellipsis kullanılmalı.

**Etkileşim:** İlk yüklemede kartlar hafif stagger ile gelir. Basınca 0.97
scale, çok küçük elevation ve haptic; detay sayfasına yazar ID'siyle `Hero`
geçişi. Fotoğrafın `Hero` tag'i `author-<id>` olmalı. Yüksek performans için
kapak/fotoğraf yeniden indirilmemeli.

**Kullanım alanları:**

- Home'daki `type: author` koleksiyonları: yatay avatar satırı yerine yatay
  editorial kart rafı.
- Arama sonuçlarında authors modu: iki sütunlu responsive grid.
- Geniş/foldable ekranda: üç veya dört sütunlu adaptive grid.
- Yazar detay ekranında: karttaki fotoğraf full-width header'a Hero olarak akar.

### Sonnet görevi 01G — reusable author discovery card

```text
Aýkitap Flutter projesinde CatalogAuthorAvatar, Home author collections,
Search author results ve CatalogAuthorDetailScreen akışını incele. Referanstaki
fotoğraf ağırlıklı editorial kart hissinden ilham alan, fakat başka uygulamanın
tasarımını kopyalamayan reusable CatalogAuthorCard oluştur. Kart 2:3 portre
fotoğrafı, altta beyaz/dark-theme uyumlu bilgi alanı, yazar adı, uygun olduğunda
kitap sayısı veya lokalize 'Author' etiketi ve image yokken gradient monogram
placeholder içersin. Home için yatay card rail, search için iki sütunlu
responsive grid API'sini desteklesin. Her kartta author ID tabanlı Hero,
hafif press-scale/haptic, semantics label ve reduce-motion fallback olsun.
Mevcut author detay yönlendirmesini, ağ görsel cache'ini ve dark mode'u bozma.
Widget/golden test ve flutter analyze çalıştır.
```

### Yazar kartı kabul kriterleri

- [ ] Telefon ekranında 2 sütunlu gridde oran bozulmaz veya yatay raf içinde
  kart genişliği dengelidir.
- [ ] Foldable/tablet genişliğinde sütun sayısı pencere genişliğine göre artar.
- [ ] Yazar fotoğrafı yoksa kırık görsel yerine markalı placeholder görünür.
- [ ] Uzun isim, farklı alfabe ve iki satır sınırı güvenli çalışır.
- [ ] Karttan detay ekranına geçişte fotoğrafın sıçraması/flicker olmaz.
- [ ] Kullanım hakkı olmayan portreler mağaza/Devpost görsellerinde kullanılmaz.

### A. Kitap detayı → okuyucu: imza geçişi (en yüksek öncelik)

**Etkileşim:** Kullanıcı kapak görseline veya `Oku` düğmesine basar. Kapak
yerinde hafifçe büyür, arka plan kapağın baskın rengine göre koyulaşır ve kapak
reader'ın ilk sayfasına dönüşür. Okuyucu hazır değilse aynı dönüşümün sonunda
minimal yükleme katmanı görünür.

**Neden:** Demo videosundaki en güçlü 4–6 saniyelik an olur. Kitap uygulaması
olduğunu tek bakışta anlatır.

**Teknik:** `Hero` tag'i kitap ID ile sabit; `PageRouteBuilder` + `FadeTransition`
veya mevcut route altyapısı; görsel paleti cache edilmeli; reader oluşturulurken
kahraman görseli tekrar indirilmemeli.

**Sonnet görevi 02**

```text
CatalogBookDetailScreen'den reader açılışını incele. Kitap kapağı için her
kitapta benzersiz Hero tag kullanarak detail-to-reader geçişi ekle. Açılışta
kapak scale/fade ile reader ilk sayfasına geçsin; geri dönüşte ters çalışsın.
PDF, EPUB ve CBZ akışlarını bozmadan ortak bir wrapper kullan. Düşük hareket
tercihinde normal kısa fade kullan. Mevcut deep link ve download/open akışlarını
koru. Değişen dosyaları analiz et ve test edilebilen bir akış ekle.
```

### B. Home: rafların canlı ama sakin girişi

**Etkileşim:** Veri ilk kez geldiğinde banner önce gelir; ardından bölüm
başlıkları ve raflar 40 ms gecikmeli yukarı/fade ile görünür. Kitap kartına
dokununca 0.97 scale + hafif elevation; bırakınca spring ile geri döner.

**Sınır:** Her scroll dönüşünde tekrar oynatılmamalı; sadece ilk yükleme ve
manuel yenileme sonrası oynatılmalı. Mevcut `StaggerFadeIn` yeniden kullanılmalı
veya genelleştirilmeli.

**Sonnet görevi 03**

```text
HomeScreen ve mevcut StaggerFadeIn kullanımını incele. Katalog bölümleri için
yalnız ilk başarılı veri yüklemesinde çalışan, erişilebilir ve performanslı bir
stagger giriş sistemi uygula. Her bölüm bir kez animate olsun; scroll ile tekrar
tetiklenmesin. CatalogBookCard, CatalogSeriesCard ve ranked kartlara yalnızca
hafif press-scale/haptic geri bildirimi ekle. Ağ görsellerini gereksiz rebuild
etme. flutter analyze çalıştır.
```

### C. Okuma ilerlemesi: "mürekkep yolu"

**Etkileşim:** Reader'da sayfa değiştiğinde ilerleme çubuğu bir anda atlamaz;
220 ms içinde akar. Continue Reading kartındaki ince yol/çizgi, kitabın baskın
rengine yakın bir vurgu ile doludur. Günlük hedefe yaklaştıkça çizgide küçük
ışıltı ilerler.

**Sınır:** Sürekli parlayan animasyon yapılmamalı. Sadece kullanıcı aktif olarak
okurken veya sayfa değişiminden sonraki 500 ms içinde çalışmalı.

**Sonnet görevi 04**

```text
Reader progress state ve ContinueReadingCard yapısını incele. Sayfa/konum
değiştiğinde 220ms AnimatedTween/AnimationController ile akan, erişilebilir bir
okuma ilerleme göstergesi oluştur. Çok sayfalı ve yeniden akıtılmış PDF/EPUB/CBZ
formatlarında doğru oranı kullan. Kullanıcı reduce motion seçmişse anında güncelle.
Sürekli animasyon veya gereksiz timer kullanma.
```

### D. Streak: küçük, zarif kazanım anı

**Etkileşim:** Günlük hedef ilk kez tamamlandığında gün hücresi doldurulur,
alev/ay yıldızı 1 kez 0.8→1.08→1.0 scale yapar ve üç küçük parçacık yükselir.
7 gün olduğunda mevcut confetti asset'i çok kontrollü kullanılır.

**Sınır:** Uygulama her açıldığında kutlama tekrar oynatılmaz. `SharedPreferences`
ile gün + kullanıcı + başarı kimliği saklanır.

**Sonnet görevi 05**

```text
StreakService, StreakSummaryCard ve StreakWeekCard'ı incele. Günlük okuma hedefi
ilk kez tamamlanınca bir defa çalışan hafif başarı animasyonu ekle. Aynı gün ve
aynı kullanıcı için tekrar oynatılmasını kalıcı olarak engelle. 7 günlük seri
milestone'unda mevcut Confetti Lottie asset'ini bir kez göster; normal günlük
başarıda Lottie kullanma. Offline durumda da çalışmalı. Test ve flutter analyze
ekle.
```

### E. Başarılar ve paylaşılabilir kart

**Etkileşim:** İlk kitap, 7 günlük seri, 1.000 sayfa gibi üç başlangıç
rozeti. Rozete basınca kapak/alıntı/istatistikten oluşan Instagram-story
oranlı statik paylaşım kartı üretilir.

**Neden:** #BuildInPublic ve organik paylaşım için dikkat çekici, ama ürünün
odağını bozmayan bir growth loop.

**Sonnet görevi 06**

```text
Okuma ilerlemesi ve streak verilerini kullanarak ilk kitap, 7 gün streak ve
1000 sayfa milestone'larını modelle. Milestone ekranı ve 9:16 paylaşım kartı
oluştur; kart kitap kapağı, güvenli bir kısa alıntı/başlık, sayfa sayısı ve
Aýkitap Journey markası içersin. share_plus ile görseli paylaş. Üçüncü taraf
kitap metninden uzun alıntı kullanma. Başarı animasyonu yalnız ilk açılışta
oynasın.
```

### F. Paywall: kitabın kilidinin açıldığı anlamlı hareket

**Etkileşim:** Premium ekranına geçerken seçilen kitabın kapağı üstte kalır;
premium avantajlar sırayla görünür. Kullanıcı planı seçince plan kartı yumuşak
olarak öne gelir. Başarılı satın almada kilit simgesi kaybolur, kitap rafına
doğru küçük bir yol çizilir.

**Sınır:** Sahte geri sayım, zorla kapatılmayan ekran veya dikkat dağıtıcı
confetti yok. İptal/restore akışları sakin ve açık olmalı.

**Sonnet görevi 07**

```text
RevenueCat entegrasyonundan sonra kullanılmak üzere SubscriptionScreen'i
yeniden tasarlama planına uygun premium paywall motion'ı ekle. Mevcut PlanCard
seçim animasyonlarını koru; seçili offering'in faydalarını 40ms stagger ile
göster. Başarılı satın alma/restore sonrası erişim durumunun değişimini net
gösteren küçük bir unlock animasyonu tasarla. Kullanıcı reduce motion tercihinde
anında durum değiştir. Sahte aciliyet ve otomatik tekrar eden animasyon ekleme.
```

### G. Offline durum: hata değil, güven hissi

**Etkileşim:** Bağlantı kesildiğinde raf donup kaybolmaz; "Offline kütüphanen
hazır" kartı nazikçe çıkar. Ağ geri geldiğinde bulut ikonu tek kez çizilir,
veri arka planda yenilenir.

**Sonnet görevi 08**

```text
Mevcut offline library ve no-internet Lottie durumlarını incele. Ana katalogda
bağlantı kesilince daha önce cache'lenen içeriği koruyan küçük bir offline durum
banner'ı ekle; ağ geri gelince bir kez başarılı sync mikro animasyonu göster.
Okuma ekranı kesintiden etkilenmemeli. Mevcut Lottie'yi yalnız boş/offline
kütüphane gibi anlamlı durumlarda kullan.
```

### H. Onboarding: amaç seçimi ve ilk değer anı

**Etkileşim:** Dil seçiminden sonra "Bugün neden okuyorsun?" üç kartı;
kart seçilince renk/ikon/kapak kompozisyonu değişir. Son ekranda 10 TMT hoş
geldin kredisi net şekilde açıklanır: "Bir kitap al veya 1 haftalık erişimi
başlat." Bu kredi kullanıcıyı zorlamadan ilk değer deneyimine taşır.

**Sonnet görevi 09**

```text
Onboarding akışını incele. Mevcut dil seçimini koruyarak amaç seçimi (rahatla,
öğren, alışkanlık kur) ve 10 TMT hoş geldin kredisi açıklama ekranı ekle.
Seçilen amaç lokal olarak saklansın ve home önerilerinde kullanılabilecek sade
bir preference olarak erişilebilir olsun. AnimatedSwitcher/AnimatedContainer
ile mevcut görsel dili koru; yeni ağır paket ekleme.
```

## 6. 10 TMT hoş geldin kredisi — ürün ve ödeme kuralı

### Mevcut davranış

Kullanıcı kayıt olduğunda 10 TMT alıyor; bununla kitap satın alabiliyor veya
bir haftalık abonelik başlatabiliyor. Bu, ilk değer anı için çok iyi.

### Önerilen deneyim

- Krediyi "hediye para" gibi değil, **İlk okuma hediyesi: 10 TMT** olarak
  sun.
- Kayıt sonrası iki eşit seçenek göster:
  - `Bir kitap seç` → kullanıcının ilgisine göre üç kitap.
  - `7 gün sınırsız oku` → tek haftalık erişim.
- Kredi harcanmadan paywall zorla açılmasın.
- Kullanıcı bakiye ile aldıysa, ekranda bunun StoreKit/Google Play satın alımı
  olmadığı açık olmalı.
- Kredi sunucu tarafından verilmeli, bir defa verilmeli, kullanıcı kimliğiyle
  bağlanmalı ve harcama işlemi atomik olmalı.
- Bakiye ve gerçek para ile alınan ürünler için geçmiş ayrı, anlaşılır satırlar
  halinde gösterilmeli.

### RevenueCat ile sınır

RevenueCat aboneliği, iOS/Android mağaza üzerinden satılan **dijital Premium
erişimi** yönetmeli. 10 TMT başlangıç bakiyesi uygulamanın kendi sunucu cüzdanı
olarak kalabilir. Ancak aynı dijital erişimi iki kaynak veriyorsa, erişim
kararı tek yerde birleştirilmeli:

```text
Premium aktif = RevenueCat `premium` entitlement aktif
              VEYA backend tarafından verilen geçerli 7 gün / bakiye erişimi
```

Sunucu, bu iki kaynağın bitiş tarihini ve nedenini denetlenebilir tutmalıdır.
Bir iOS kullanıcısına mağaza dışı ödeme ile dijital içeriğin kilidini açtırma
kuralları ayrıca mağaza politikası açısından hukuk/Apple incelemesi gerektirir;
yayından önce ürün modeli doğrulanmalıdır.

## 7. RevenueCat entegrasyon planı

### Hedef ürün kataloğu

| Tür | Store product ID önerisi | RevenueCat entitlement | Açtığı değer |
|---|---|---|---|
| Aylık | `aykitap_plus_monthly` | `premium` | Sınırsız katalog + Premium özellikler |
| Yıllık | `aykitap_plus_annual` | `premium` | Aynı erişim, daha iyi değer |
| Deneme | aylık ürünün intro offer'ı | `premium` | 7 gün ücretsiz deneme |
| İsteğe bağlı paket | `journey_themes_pack` | `journey_themes` | Premium temalar/okuma atmosferleri |

İlk sürümde tek `premium` entitlement yeterli. RevenueCat'te product →
entitlement → offering ilişkisi kurulmalı; offering, paywall/deney değişikliği
için uygulama güncellemesi olmadan yönetilebilir. Kaynak:
[RevenueCat ürün yapılandırması](https://www.revenuecat.com/docs/projects/configuring-products).

### Sonnet görevi 10 — bağımlılık ve yapı

```text
Flutter projesine güncel purchases_flutter bağımlılığını eklemek için güvenli
bir RevenueCatService tasarla. API anahtarları source code içine gömülmesin;
platform bazlı public SDK key için build-time config kullan. Servis configure,
login/logout, getCustomerInfo, getOfferings, purchase, restore ve entitlement
değişim dinleyicisini kapsasın. UI'dan bağımsız, test edilebilir bir facade
oluştur. Mevcut SubscriptionService'i hemen silme; iki erişim kaynağının
birleşeceği geçiş katmanını tasarla. iOS In-App Purchase capability ve Android
BILLING iznini kontrol listesine ekle. Analiz/test çalıştır.
```

### Sonnet görevi 11 — kimlik ve erişim

```text
AuthSession ve RevenueCatService'i bağla. Kullanıcı oturum açınca RevenueCat'e
stabil uygulama kullanıcı ID'si ile login yap; çıkışta logOut uygula. CustomerInfo
entitlements.active['premium'] üzerinden tek bir isPremium getter üret.
SubscriptionService/BookAccessService tarafında backend aboneliği ile
RevenueCat entitlement'ını OR mantığıyla birleştiren erişim katmanı ekle.
Anonim kullanıcıdan giriş yapan kullanıcıya satın alma aktarımı için RevenueCat
login akışını bozma. Unit test ekle.
```

### Sonnet görevi 12 — gerçek paywall

```text
SubscriptionScreen'i RevenueCat offerings ile çalışacak şekilde dönüştür.
Loading, satın alma, kullanıcı iptali, pending purchase, hata ve restore states
eksiksiz olsun. Aylık/yıllık ürün bilgilerini Store'dan/RevenueCat offering'den
al; fiyatı hardcode etme. Free trial uygunsa net olarak göster. Başarılı satın
alma sonrası entitlement yenilenene kadar güvenli loading göster ve erişimi
anında güncelle. Jüri için restore purchases görünür olmalı.
```

### Sonnet görevi 13 — sunucu doğrulaması

```text
Backend kodu erişilebiliyorsa RevenueCat webhook endpoint'i tasarla ve uygula.
Webhook imzasını doğrula, event'i idempotent işle, appUserID ile kullanıcıyı
eşle ve premium erişim gölgesini güncelle. Webhook başarısız olsa dahi mobilde
CustomerInfo ana kaynak olarak çalışsın. Asla RevenueCat secret API key'i mobil
uygulamaya koyma. Event audit kaydı ve test senaryoları ekle.
```

### RevenueCat kabul kontrol listesi

- [ ] RevenueCat projesi oluşturuldu.
- [ ] iOS App Store Connect ve Google Play ürünleri oluşturuldu.
- [ ] `premium` entitlement oluşturuldu ve ürünlere bağlandı.
- [ ] `default` offering içinde aylık/yıllık paketler var.
- [ ] Sandbox/Test Store ile satın alma, iptal, restore test edildi.
- [ ] iOS In-App Purchase capability aktif.
- [ ] Android `com.android.vending.BILLING` izni aktif.
- [ ] Giriş/çıkış kullanıcı eşleme test edildi.
- [ ] Jüri için ücretsiz deneme veya promo kod hazır.
- [ ] RevenueCat dashboard ekran görüntüsü ve demo videosu hazır.

Flutter SDK kurulumu ve platform gereksinimleri için:
[RevenueCat Flutter dokümantasyonu](https://www.revenuecat.com/docs/getting-started/installation/flutter).

## 8. OneSignal — Keep Them Coming Back planı

### Neden Firebase yerine/yanında OneSignal?

Mevcut Firebase Messaging temel push teslimi için yeterli. Shipaton sponsor
kategorisine uygun olmak için ise OneSignal SDK kurulmalı, en az bir kampanya
yayınlanmalı ve OneSignal App ID başvuruda verilmelidir. Bu nedenle iki ayrı
push sağlayıcısının aynı bildirimi göndermesine izin verilmez.

**Öneri:** Shipaton sürümünde kullanıcı kampanyaları için OneSignal'ı birincil
push platformu yap; Firebase Messaging'i yalnız başka Firebase bağımlılıkları
gerektiriyorsa tut. Aynı APNs/FCM token üzerinde iki SDK ile çift bildirim
oluşmasını gerçek cihazda özellikle test et.

### Kullanıcı segmentleri

| Segment | Tetik | Mesaj | Frekans sınırı |
|---|---|---|---|
| İlk gün okuyan | ilk okuma tamamlandı | "Yolunun ilk adımı tamamlandı." | bir kez |
| 2 gün yok | son okuma > 48 saat | "Kitabın kaldığın yerde seni bekliyor." | haftada en çok 1 |
| İndirilmiş kitap | offline kitap var, okunmuyor | "İnternetsiz de 10 dakika okumaya ne dersin?" | haftada en çok 1 |
| Trial bitişi | denemenin bitmesine 24 saat | "Premium yolculuğun yarın bitiyor; devam etmek istersen..." | bir kez |
| Yeni yerel koleksiyon | ilgilendiği türde yeni içerik | "Senin için yeni bir raf geldi." | 2 haftada en çok 1 |

**Kural:** Bildirimler kullanıcı davranışına değer katmalı; günde birden fazla
engagement push yok. Sessiz saatlere saygı, açık opt-out ve deep link zorunlu.

### Sonnet görevi 14 — OneSignal temel entegrasyon

```text
Mevcut FirebaseMessagingService'i incele ve Shipaton sürümü için OneSignal
entegrasyon planını uygula. onesignal_flutter'ın güncel sürümünü ekle;
uygulama başlangıcında initialize et fakat izin diyaloğunu ilk açılışta zorla
gösterme. Kullanıcı okuma hedefini seçtikten sonra açıklayıcı bir in-app prompt
ile izin iste. Login sonrası OneSignal.login(AuthSession user ID) çağır,
logout'ta doğru kullanıcı ayrımını uygula. Bildirim tıklamasındaki bookId,
route ve campaign data ile mevcut DeepLinkService/route sistemine yönlendir.
Firebase ve OneSignal'ın aynı bildirimi iki kez göstermediğini garanti et.
```

### Sonnet görevi 15 — OneSignal Journey ve ölçüm

```text
Okuma, son okuma zamanı, hedef tamamlama, trial durumu ve ilgi türü için
OneSignal tags/event sözleşmesi oluştur. Kişisel veri ve kitap metni gönderme.
OneSignal dashboard'da 48 saatlik 'continue reading' Journey tasarla; derin
link ile kullanıcının son kitabını açsın. En az bir gerçek kampanyayı test
kullanıcısına yayınla. Click listener ile deep link testlerini ve Firebase
Analytics eventlerini ekle. Frekans sınırı ve opt-out davranışını doğrula.
```

### iOS ek gereksinimleri

- Push Notifications capability ve Background Modes → Remote notifications.
- OneSignal p8 APNs anahtarı yapılandırması.
- Zengin görsel bildirim/confirmed delivery kullanılacaksa Notification Service
  Extension ve App Group.
- İzin istemeden önce uygulama içi değer açıklaması.

Kaynak: [OneSignal Flutter SDK kurulumu](https://documentation.onesignal.com/docs/en/flutter-sdk-setup).

## 9. Samsung Foldable / büyük ekran planı

Mevcut uygulama `main.dart` içinde uygulamayı yalnız portrait'e kilitliyor.
Bu, katlanmış telefon için kabul edilebilir olsa da açık Fold/Flip/tablet
ekranında deneyimi sınırlıyor ve Galaxy kategorisi hedefiyle çelişiyor.

### Hedef davranış

| Pencere | Deneyim |
|---|---|
| Compact (< 600dp) | Mevcut tek sütun, bottom navigation, normal reader. |
| Medium (600–839dp) | Genişletilmiş grid, daha geniş rail/nav; detaylar sheet yerine yan panel olabilir. |
| Expanded (>= 840dp) | Home/library list-detail görünümü; reader iki sayfa ve bölüm listesi yan panelde. |
| Book posture | Menteşe iki sayfa arasındaki doğal ayırıcıdır; metin/kapak menteşenin üstüne gelmez. |
| Tabletop posture | Üstte okuma sayfası, altta progress/ayarlar; medya/video yoksa kontroller altta. |

Android rehberleri açık foldable için iki-panelli/navigasyon rail düzenini,
book posture için iki sayfalı okuyucuyu ve orientation kilidinden kaçınmayı
öneriyor. Kaynaklar: [Foldables](https://developer.android.com/develop/adaptive-apps/guides/foldables/learn-about-foldables),
[fold-aware tasarım](https://developer.android.com/develop/adaptive-apps/guides/foldables/make-your-app-fold-aware).

### Sonnet görevi 16 — adaptive temel

```text
Flutter projesinin portrait orientation kilidini, AndroidManifest'i ve ana
navigation'ı incele. Telefonlarda mevcut portrait deneyimini korurken, genişliği
600dp ve üstü olan pencerelerde orientation/resizable/multi-window ile uyumlu
adaptive layout altyapısı kur. LayoutBuilder/MediaQuery tabanlı merkezi bir
WindowSizeClass helper oluştur. Küçük ekran davranışını değiştirme. Katlanma,
rotasyon ve split-screen sırasında reader progress, seçili tab ve scroll
durumunun korunduğunu test et.
```

### Sonnet görevi 17 — geniş ekran kütüphane ve katalog

```text
LibraryScreen, HomeScreen, SearchScreen ve CatalogBookDetailScreen'i geniş
ekran için adaptive hale getir. Expanded ekranda NavigationRail + iki panelli
list-detail düzeni kullan: solda katalog/arama/kitap listesi, sağda seçili
kitabın detay önizlemesi. Compact ekranda mevcut bottom navigation ve push
route davranışı korunmalı. Grid kolon sayısı sabit değil, mevcut pencere
genişliğine göre hesaplanmalı. Klavye/mouse/trackpad ile temel kullanım
sağlanmalı.
```

### Sonnet görevi 18 — foldable reader, en ayırt edici özellik

```text
EPUB, PDF ve CBZ reader ekranlarını incele. Expanded veya book-posture geniş
ekranda gerçek bir iki sayfa spread görünümü tasarla: sol ve sağ sayfa, ortada
güvenli gutter/hinge boşluğu, chapter/progress paneli isteğe bağlı. Compact
ekranda mevcut tek sayfa davranışı hiç değişmesin. Fold açılıp kapanırken aynı
okuma konumu korunmalı; sayfa sayısı/indeks dönüşümü güvenli olmalı. Başlangıçta
yalnız EPUB için tamamla, sonra PDF/CBZ için ayrı görevler planla. Jank ve
overflow testleri ekle.
```

### Samsung test kontrol listesi

- [ ] Galaxy Z Fold kapalı/açık, portrait/landscape.
- [ ] Galaxy Z Flip tabletop posture.
- [ ] En az Android Studio resizable emulator + gerçek Samsung cihaz.
- [ ] Split screen, pencere yeniden boyutlandırma, klavye açık durum.
- [ ] Reader'da aç/kapat sırasında aynı bölüm/sayfa.
- [ ] Menteşe üzerinde buton, metin veya sayfa içeriği yok.
- [ ] Galaxy Store listing ve store policy kontrolü.

## 10. Analitik ve büyüme ölçümü

Her geliştirmeden önce ölçülecek event sözleşmesi yazılmalı:

| Event | Örnek parametreler | Karar için |
|---|---|---|
| `onboarding_goal_selected` | goal | öneri ve onboarding kalitesi |
| `welcome_credit_presented` | amount=10 | ilk değer anı |
| `welcome_credit_used` | book/subscription, amount | kredi kullanım oranı |
| `reader_opened` | format, source | asıl değer aktivasyonu |
| `reading_goal_completed` | pages, minutes, streak | retention |
| `paywall_viewed` | source, offering | paywall bağlamı |
| `purchase_started/completed/cancelled` | package, source | conversion |
| `restore_completed` | entitlement_active | güven/teslim |
| `notification_opened` | campaign, deep_link | OneSignal Journey etkisi |
| `foldable_layout_used` | size_class, posture | Galaxy hikâyesi |

Kişisel veri, kitap metni, telefon numarası veya hassas kullanıcı girdileri
analytics parametresi olarak gönderilmemeli.

## 11. Yayın ve Devpost teslim kontrol listesi

### Yayından önce

- [x] Google Play ilk public release: 11 Ağustos 2026 (Shipaton penceresinde).
- [ ] Aynı tarihten önce başka uygun mağazada public release olmadığını doğrula.
- [ ] ABD mağazasında erişilebilirlik.
- [ ] Release signing: Android'de debug signing değil gerçek release key.
- [ ] RevenueCat live ürünleri, deneme/promo kodu, restore testleri.
- [ ] OneSignal kampanyası canlı ve App ID kaydedildi.
- [ ] Foldable cihaz/simülatör test videosu.
- [ ] Crash-free gerçek cihaz testi: iOS + Android + Foldable.

### Devpost paketi

- [ ] 2 dakikadan kısa İngilizce demo videosu (gerçek cihaz kaydı).
- [ ] 1024×1024 ikon.
- [ ] En az bir adet 1179×2556, cihaz çerçevesiz ekran görüntüsü.
- [ ] Store URL.
- [ ] Jüri hesabı/promo kod/free trial talimatı.
- [ ] İngilizce açıklama: problem, çözüm, RevenueCat stratejisi, ölçümler.
- [ ] Design Award: imza animasyonlarını zaman damgasıyla anlat.
- [ ] Peace Prize: hedef topluluk ve etkiyi somutlaştır.
- [ ] HAMM: fiyatlama, offering, deneme ve dönüşüm stratejisini yaz.
- [ ] OneSignal: App ID + Journey/kampanya açıklaması.
- [ ] Galaxy: foldable optimizasyonlarının ekran kaydı.
- [ ] #BuildInPublic: herkese açık post/video bağlantıları.

## 12. En gerçekçi teslim sırası

1. **Gün 1:** Yeni uygulama/bundle kararını, mağaza hesaplarını, RevenueCat
   projesini ve ürün ID'lerini hazırla.
2. **Gün 2–3:** RevenueCat temel servis + entitlement + gerçek paywall +
   purchase/restore testleri.
3. **Gün 4:** Motion sistemi + kitap detayı → reader imza geçişi.
4. **Gün 5:** Home girişleri, progress, streak kutlaması.
5. **Gün 6:** Onboarding amaç/kredi açıklaması + offline güven ekranı.
6. **Gün 7–8:** Adaptive temel ve expanded katalog/kütüphane.
7. **Gün 9:** EPUB iki sayfa foldable reader MVP.
8. **Gün 10:** OneSignal + 48 saatlik continue-reading Journey.
9. **Gün 11:** Test, mağaza metadata, promo/free trial, ekran görüntüleri.
10. **Gün 12:** 2 dakika demo, Devpost İngilizce metni, #BuildInPublic postları.

## 13. Demo video senaryosu (maksimum 2 dakika)

1. **0:00–0:10:** "Turkmence reading should feel personal, not transactional."
2. **0:10–0:25:** Amaç seçimi + 10 TMT ilk okuma hediyesi.
3. **0:25–0:45:** Home rafları ve kitap detayı → reader imza Hero geçişi.
4. **0:45–1:00:** Offline okuma + progress ink yolu.
5. **1:00–1:15:** Günlük hedef/streak kutlaması + paylaşım kartı.
6. **1:15–1:32:** RevenueCat Premium paywall, trial/purchase/restore.
7. **1:32–1:45:** Samsung Fold açıkken iki sayfalı reader.
8. **1:45–1:55:** OneSignal continue-reading bildirimi → deep link ile kitaba dönüş.
9. **1:55–2:00:** Etki, gelir modeli ve çağrı: "Read more. Keep culture close."

## 14. Uygulama sırasında korunacak kurallar

- Bir Sonnet görevi yalnız belirtilen kapsamı değiştirsin; ilgisiz dosyaları
  refactor etmesin.
- Her görev sonunda `flutter analyze` ve ilgili testler çalıştırılsın.
- Önce gerçek cihazda, sonra görsel inceleme ile kabul edilsin.
- Animasyonlar kullanıcı tercihine saygılı olsun.
- RevenueCat secret key, OneSignal REST API key veya Apple private key repoya
  hiç yazılmasın.
- Store yayınından önce sahte screenshot, sahte metrik veya erişilemeyen
  premium ekran kullanılmasın.
