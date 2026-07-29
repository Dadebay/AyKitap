# Architecture Map

## App: Aykitap — E-kitap okuma uygulaması

## State Management: Provider ^6.1.2

## Klasör Yapısı
lib/
├── core/
│   ├── constants/     # app_spacing, app_radius
│   ├── navigation/    # app_navigator — merkezi navigasyon
│   ├── models/        # book, own_book, bookmark, reading_note
│   ├── theme/         # app_colors, app_text_styles, app_gradients, theme_controller
│   ├── data/          # book_repository (interface), mock_book_repository
│   ├── services/      # İş mantığı servisleri (aşağıya bak)
│   ├── widgets/       # Paylaşılan widget'lar
│   └── localization/  # app_locale + feature bazlı string dosyaları
└── [features]/        # Feature klasörleri

## Servisler (core/services/)
- auth_session           — Kullanıcı oturumu
- subscription_service   — Abonelik kontrolü
- purchased_books_store  — Satın alınan kitaplar
- own_books_store        — Kullanıcının kendi yüklediği kitaplar
- bookmarks_store        — Yer imleri
- notes_store            — Okuma notları
- streak_service         — Okuma serisi (streak)
- app_prefs              — SharedPreferences wrapper
- cbz_page_cache         — CBZ formatı sayfa önbelleği
- pdf_reflow_service     — PDF text extraction (pdfrx)
- analytics_service      — Firebase Analytics
- firebase_messaging_service — Push bildirimler
- local_notifications_service — Yerel bildirimler
- device_fingerprint     — Cihaz kimliği

## Kitap Formatları
- EPUB → sakura_epub (vendored: packages/sakura_epub) — flutter_inappwebview tabanlı
- PDF  → flutter_pdfview + pdfrx (text layer detection)
- CBZ  → archive paketi + cbz_page_cache

## Key Dependencies
- dio + http: Network istekleri
- cached_network_image: Kitap kapak görselleri
- shared_preferences + flutter_secure_storage: Lokal veri
- firebase_core + analytics + messaging: Firebase
- lottie: Animasyonlar
- intl: Lokalizasyon (flutter_localizations)

## Fontlar
- Gilroy (ana font), SF Pro, Arial, NotoSerif, OpenSans (reader font seçenekleri)
