# Sonnet görevleri — English, theme ve statik UI

Bu belge yalnız Sonnet'e verilecek, birbirinden bağımsız ve düşük riskli
görevleri içerir. Her görevi **tek başına**, sırasıyla ver; Sonnet bir görevi
bitirip analiz etmeden diğerine geçmesin.

## Sonnet'in dokunmayacağı alanlar

Bu dosyadaki görevler sırasında aşağıdakileri değiştirme:

- `AnimationController`, `Hero`, `PageRouteBuilder`, custom painter veya
  navigation gesture physics.
- Reader açılış/kapanış geçişi, progress motion, streak kutlaması, Lottie
  akışı veya paywall success/unlock animasyonu.
- RevenueCat, OneSignal, satın alma, push, backend API veya foldable reader.
- İlgisiz refactor, paket yükseltme veya dosya taşıma.

Bu animasyon/effect işleri Codex tarafından yapılacak.

## Çalışma kuralları

Her görev sonunda:

1. Yalnız görev kapsamındaki dosyaları değiştir.
2. `dart format` uygula.
3. `flutter analyze` çalıştır.
4. Değişen dosyaları, doğrulama sonucunu ve kalan riski kısa raporla.
5. Var olan kullanıcı değişikliklerini geri alma, `git reset` veya `checkout`
   kullanma.

---

## S1 — İngilizce localization altyapısı

```text
Bu Flutter projesinde yalnız İngilizce dil altyapısını ekle. Önce
lib/core/localization/app_locale.dart, localization_delegates.dart,
strings_base.dart ve Settings dil seçici bileşenlerini incele.

İstenenler:
- AppLanguageCode enumuna `en` ekle.
- kAppSupportedLocales listesine Locale('en') ekle.
- Intl locale mapping'e İngilizceyi ekle.
- t(...) helper'ına opsiyonel String? en parametresi ekle; en çevirisi yoksa
  tk değerine fallback yapsın.
- Ayarlardaki dil listesinde English seçeneğini ekle ve seçimin SharedPreferences
  ile mevcut davranışta kalıcı olmasını koru.
- Uygulamanın varsayılan dili tk olarak kalsın.

Yalnız altyapı ve language selector değişsin. String dosyalarına toplu çeviri
ekleme, animasyon/purchase/push/foldable koduna dokunma. Formatla, ilgili test
ekle veya güncelle ve flutter analyze çalıştır.
```

Kabul:

- [ ] English seçilir, uygulama yeniden açıldığında seçili kalır.
- [ ] English çevirisi henüz olmayan metin güvenle tk fallback gösterir.
- [ ] Flutter Material/Cupertino yerelleştirmeleri çalışır.

---

## S2 — tüm kullanıcı metinlerinin İngilizce çevirisi

```text
S1 tamamlandıktan sonra lib/core/localization/strings altındaki tüm string
dosyalarını tarayıp her t(...) çağrısına doğal ve tutarlı İngilizce `en:`
çevirisi ekle.

Kapsam: onboarding, auth, home, search, book detail, author, library, reader,
profile, settings, notes, payment, streak, offline/error, notification ve
shared widget metinleri.

Kurallar:
- UI widget'larına yeni hardcoded metin yazma.
- Mevcut tk/ru/tr çevirilerini değiştirme.
- Marka adı Aýkitap'ı koru; TMT para birimi ifadesini değiştirme.
- Kısa, mağaza demosuna uygun doğal İngilizce kullan: örn. 'Continue reading',
  'Restore purchases', 'Reading streak'.
- Teknik kod yorumlarına, API alanlarına ve backend mesaj eşlemelerine dokunma.
- `rg` ile en parametresi eksik kalmış t(...) çağrısı olmadığını denetle.

Formatla, flutter analyze çalıştır ve en az bir English locale widget testi ekle.
```

Kabul:

- [ ] English seçiliyken gözle görünen Türkmen/Rusça/Türkçe UI metni kalmaz.
- [ ] Hata, ödeme, reader sheet ve Settings metinleri dahildir.
- [ ] Uzun İngilizce metinler küçük ekranlarda overflow yapmaz.

---

## S3 — Journey theme tokenları

```text
Yalnız tema altyapısını geliştir. lib/core/theme/app_colors.dart,
app_gradients.dart ve theme_controller.dart yapısını incele.

Mevcut dark/light tercihini ve tüm eski renk getter'larını kırmadan aşağıdaki
merkezi Journey tokenlarını ekle:
- journeyPrimary: #FF9A3D → #FF5C7D → #8D4DFF
- journeySoft: #FFE6D5 → #FFD8E4 → #E8D9FF
- journeyRoseViolet: #FF6A88 → #B34BEA
- journeySunset: #FFB34D → #FF5F6D
- journeyMist: light-mode arka plan #F8F7FC
- journeyInk: light-mode başlık #22212A

Her gradyanın dark-mode bağlamında güvenli karşılığını tasarla. Tokenları
AppGradients/AppColors içinde merkezi tut; ekran widget'larına hardcode renk
ekleme. Bu görevde ekranları kapsamlı yeniden boyama ve animasyon ekleme.
Formatla ve flutter analyze çalıştır.
```

Kabul:

- [ ] Mevcut dark/light switch korunur.
- [ ] Eski ekranlarda renk regresyonu oluşmaz.
- [ ] Yeni tokenlar isimlendirilmiş ve tekrar kullanılabilir durumdadır.

---

## S4 — tekrar kullanılabilir gradient icon badge

```text
S3 tokenlarını kullanarak lib/core/widgets altında reusable
JourneyGradientIconBadge oluştur. Widget normal Icon veya HugeIcon child kabul
etsin; small/medium/large boyutları, pastel/primaryAction varyantı ve
semanticsLabel parametresi olsun.

Tasarım:
- Varsayılan: pastel gradient circular badge, üstünde kontrastlı tek renk ikon.
- primaryAction: yalnız gerektiğinde ShaderMask ile turuncu-pembe-mor gradient
  ikon desteği.
- Light ve dark modda okunaklı olmalı.

Bu görevde AnimationController, pulse, glow, nav veya profile ekranını değiştirme.
Widget test ekle; semantic label ve iki varyantı test et. Formatla ve flutter
analyze çalıştır.
```

Kabul:

- [ ] Küçük ikonlar bulanık/raster görünmez.
- [ ] Kontrastlı ikon ve erişilebilir semantic label vardır.
- [ ] Gradient yalnız badge/primaryAction alanındadır, genel metinde değildir.

---

## S5 — profil ekranı light-theme görsel düzeni

```text
S3 ve S4 tamamlandıktan sonra yalnız ProfileScreen, ProfileEntryCard,
profileIconCircle ve gerekli küçük profil widget'larını incele.

Referanstaki ferah profil yaklaşımından ilham alarak fakat tasarımı kopyalamadan
Aýkitap'a özgü bir light-mode profil görünümü uygula:
- journeyMist arka plan;
- beyaz, 16-20px yuvarlatılmış kartlar;
- bakiye, abonelik, ayarlar, notlar için JourneyGradientIconBadge;
- abonelik satırında journeyRoseViolet ile ince vurgu;
- mevcut avatar/bakiye/streak/ayarlar/notlar/gift yönlendirmeleri korunmalı.

Dark mode'u ayrı tasarla; light moddaki beyaz kartları körlemesine dark moda
taşıma. Layout ve işlev korunmalı. AnimationController, Hero, nav animasyonu
ve ödeme davranışı ekleme/değiştirme. Uygun widget/golden test ekle, formatla
ve flutter analyze çalıştır.
```

Kabul:

- [ ] Profil açık modda daha ferah ve tutarlı görünür.
- [ ] Koyu mod kontrastı bozulmaz.
- [ ] Mevcut profil işlemleri ve navigation çalışır.

---

## S6 — fotoğraf ağırlıklı yazar kartları

```text
CatalogAuthorAvatar, Home author collections, Search author results ve
CatalogAuthorDetailScreen'i incele. Başka uygulamanın tasarımını kopyalamadan,
fotoğraf ağırlıklı reusable CatalogAuthorCard uygula.

Kart özellikleri:
- 2:3 portre fotoğraf alanı (BoxFit.cover);
- altta tema uyumlu bilgi alanı;
- iki satıra kadar yazar adı;
- uygun veri varsa lokalize 'Author' etiketi veya kitap sayısı;
- görsel yoksa journey gradient monogram placeholder;
- Home'da yatay card rail, Search'te iki sütunlu responsive grid API'si;
- dark/light desteği ve semantics label.

Bu görevde Hero, press-scale, stagger giriş veya haptic ekleme; bunlar Codex'in
animation görevleridir. Mevcut author detail yönlendirmesi ve image cache'i
koru. Widget/golden test, dart format ve flutter analyze çalıştır.
```

Kabul:

- [ ] Fotoğraf yoksa kırık image görünmez.
- [ ] Uzun isimler taşmaz.
- [ ] Telefon gridinde iki sütun düzgün görünür.
- [ ] Home ve search yazar sonuçları işlevini korur.

---

## Sonnet görev sırası

`S1 → S2 → S3 → S4 → S5 → S6`

S2 büyük bir çeviri işidir. Sonnet tek seferde çok geniş diff üretirse bunu
modül gruplarına böl: önce auth/onboarding/home, sonra catalog/reader/library,
sonra profile/payment/settings/error. Her grup bitiminde analiz çalıştır.
