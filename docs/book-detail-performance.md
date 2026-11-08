# Kitap detay geçişi performans incelemesi

Tarih: 2026-08-27

## Belirti

Home ekranında bir kitap kapağına basıldığında kapak ilk karelerde solda takılmış gibi görünüyor, ardından detay ekranının merkezine sıçrıyor. Uzun listelerde uygulamanın genel akıcılığı da düşebiliyor.

## Bulunan nedenler

### 1. Tüm görsellerin en az 650 px decode edilmesi

`NetworkCoverImage`, ekrandaki gerçek boyuttan bağımsız olarak bütün kapakları, yazar fotoğraflarını ve küçük görselleri en az 650 px genişlikte decode ediyordu. Bu değer Hero kapakları arasında aynı cache anahtarını paylaşmak için eklenmişti ancak tüm uygulamaya uygulanıyordu.

100 × 155 logical pixel bir kapak, yaklaşık 2.6 DPR cihazda doğal olarak yaklaşık 403 px uzun kenarla decode edilebilir. 650 × 975 civarı decode ise yaklaşık 2.4 MB RGBA bellek kullanabilir. Çok sayıda kartta bu fark image cache dolmasına, garbage collection ve yeniden decode işlemlerine neden olabilir.

Çözüm: 650 px sabitlemesi genel görsel bileşeninden kaldırıldı. Yalnızca gerçekten Hero uçuşuna katılan kaynak ve hedef kapaklarda `decodeCacheWidth: 650` kullanılıyor.

### 2. Büyük blur katmanının Hero uçuşuyla aynı anda çizilmesi

Detay ekranı açılır açılmaz 400 px yüksekliğindeki arka plan kapağı blur filtresinden geçiriliyordu. İlk shader/filter işi ve Hero hareketi aynı 300 ms pencereye denk geliyordu.

Çözüm: blur arka planı rota animasyonu tamamlanana kadar oluşturulmuyor. Uçuş bittikten sonra 180 ms crossfade ile ekleniyor. Blur, `BackdropFilter` yerine yalnızca kendi çocuğunu işleyen `ImageFiltered` ve `RepaintBoundary` kullanıyor.

### 3. Detay widget ağacının uçuş ortasında değiştirilmesi

Kitap detay isteği hızlı dönerse loading görünümü, Hero henüz uçarken tam detay `ListView`, içerik kartı ve kontrol düğmeleriyle değiştiriliyordu. Bu işlem aynı karelerde layout ve paint yükü oluşturuyordu.

Çözüm: ağdan gelen detay sonucu hazır olsa bile ekrana ancak rota animasyonu tamamlandıktan sonra uygulanıyor. Hata görünümü de aynı kurala uyuyor.

### 4. Favori listesinin ana içeriği bekletmesi

Detay sayfası, kitabı göstermeden önce `wants_to=true` ile 100 kitaba kadar favori listesini indirip parse ediyordu.

Çözüm: kitap detayı artık favori sorgusunu beklemiyor. Favori ve satın alma erişim durumları, kullanılabilir içerik ekrana geldikten sonra bağımsız olarak güncelleniyor.

## Değiştirilen ana dosyalar

- `lib/core/widgets/network_cover_image.dart`
- `lib/modules/book_detail/catalog_book_detail_screen.dart`
- `lib/modules/book_detail/widgets/catalog_detail_header_art.dart`
- Hero kapağı kullanan Home, Library ve Profile kartları

## Doğrulama

- İlgili dosyalarda Flutter analyze: derleme hatası yok.
- Hero, press feedback, Home card ve Library Hero testleri: 14 test geçti.
- `git diff --check`: whitespace hatası yok.

## Kalan gerçek cihaz kontrolü

Bu oturumda Android cihaz bağlı olmadığı için Samsung cihazdaki GPU/UI frame süreleri ölçülemedi. Profile modda DevTools Performance ile aşağıdakiler kontrol edilmeli:

- Geçişte UI ve Raster frame süreleri 16.7 ms altında kalıyor mu?
- İlk blur gösterildiğinde tek seferlik shader jank oluşuyor mu?
- Home ekranında image cache ve Dart heap sürekli yükseliyor mu?
- Aynı kitaba ikinci giriş ilk girişten belirgin şekilde daha hızlı mı?

İlk blur karesi hâlâ pahalıysa sonraki adım blur görselini sunucu tarafında küçük bir türev olarak sağlamak veya statik gradient arka plana geçmektir.
