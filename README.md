# AyKitap

AyKitap, Flutter ile geliştirilen bir e-kitap okuma uygulamasıdır. EPUB ve PDF formatlarını destekler; kitap keşfi, satın alma/abonelik, çevrimdışı kütüphane ve okuma istatistikleri gibi özellikler sunar.

## Özellikler

- **Okuyucu**: EPUB (`flutter_epub_viewer`) ve PDF (`flutter_pdfview`) desteği, bölüm listesi, metin seçim araç çubuğu, okuma ayarları (yazı tipi, tema vb.)
- **Kütüphane**: Satın alınan/indirilen kitaplar için çevrimdışı kütüphane
- **Keşfet**: Ana sayfa, popüler koleksiyonlar, yazar sayfaları, seriler, arama ve filtreleme
- **Kimlik doğrulama**: Telefon numarası ile giriş ve OTP doğrulama
- **Profil**: Profil düzenleme, notlar, bildirimler, ayarlar, okuma serisi (streak) takibi
- **Ödeme**: Kitap satın alma ve abonelik ekranları
- **Çoklu dil desteği**: Modül bazlı yerelleştirme yapısı (`core/localization`)
- **Koyu/açık tema** desteği

## Teknoloji Yığını

- **Flutter** / Dart (SDK `>=3.6.0 <4.0.0`)
- **State management**: Provider
- **Yerel depolama**: `shared_preferences`, `flutter_secure_storage`
- **Ağ**: `dio`, `http`
- **Diğer**: `flutter_svg`, `lottie`, `cached_network_image`, `file_picker`, `share_plus`, `url_launcher`, `connectivity_plus`

## Proje Yapısı

```
lib/
├── core/                # Modeller, servisler, tema, lokalizasyon, ortak widget'lar
├── modules/             # Özellik bazlı ekranlar (auth, home, library, reader, profile, payment, ...)
└── main.dart            # Uygulama giriş noktası
packages/
└── flutter_epub_viewer/ # Yerel (path) paket - EPUB görüntüleyici
```

## Başlarken

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio / Xcode (mobil derleme için)

### Kurulum

```bash
flutter pub get
flutter run
```

### Testler

```bash
flutter test
```

## Lisans

Bu proje için henüz bir lisans belirlenmemiştir.
