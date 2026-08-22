# Provider envanteri (refactor Phase A)

`docs/claude-provider-refactor-prompt.md`'daki A adımının çıktısı. 22
`ChangeNotifier` sınıfı bulundu (16'sı `lib/main.dart`'ta global sağlanıyor,
4'ü ekran-scoped, 2'si hiç Provider'a bağlanmamış saf singleton).

## Global (main.dart `MultiProvider`)

| Sınıf | Owner / yükleme | Mutasyon | Dinleyen ekranlar (context.watch/read/select/Consumer) | Not |
| --- | --- | --- | --- | --- |
| `AppTheme` | `main()` → `AppTheme.instance.load()` | `toggle()`/`setDark()` | 2 dosya (main.dart, settings_screen.dart) | **20 dosya** `.instance` ile doğrudan okuyor — en büyük dual-access ihlali. |
| `AppLocale` | `main()` → `AppLocale.instance.load()` | `setLocale()` | 3 dosya | 9 dosya `.instance` ile okuyor (dio_client, strings dosyaları dahil). |
| `StreakService` | `StreakScreen`/`ProfileScreen`/`HomeHeader` → `load()` | `recordActiveSeconds`, `recordPageRead`, `flushResidual`, `refresh` | 3 dosya | 7 dosya `.instance` ile doğrudan çağırıyor (reader ekranları dahil — bkz. `ReaderProvider`). Backend'e gerçek HTTP isteği atıyor. |
| `SubscriptionService` | `AccountService`'in facade'ı | — | 5 dosya | 6 dosya `.instance`. |
| `AccountService` | login sonrası / `main()` civarı | `refresh()` | 3 dosya | **12 dosya** `.instance` — StreakService, SubscriptionService, BookAccessService dahil servisler birbirini `.instance` ile çağırıyor. |
| `NotesStore` | ilk `load()` reader/profile'dan tetiklenir | `add/remove/toggleHighlight` | 0 (yalnızca `.instance`) | 4 dosya. |
| `BookmarksStore` | `ReaderProvider.initialize()` → `load()` | `toggle/remove` | 0 (yalnızca `.instance`) | 4 dosya. |
| `PurchasedBooksStore` | main.dart'ta sağlanıyor | — | 0 | main.dart dışında hiç `.instance` kullanımı da yok — sağlanmış ama kullanılmıyor gibi görünüyor, doğrulanmalı. |
| `ReadingBooksStore` | main.dart | — | 0 | 4 dosya `.instance`. |
| `OwnBooksStore` | main.dart | import akışı | 2 dosya | 4 dosya `.instance`. |
| `DownloadedBooksStore` | main.dart | — | 1 dosya | 3 dosya `.instance`. |
| `DownloadedFilesStore` | main.dart | indirme akışı | 2 dosya | 6 dosya `.instance`. |
| `BookAccessService` | main.dart | — | 3 dosya | 10 dosya `.instance`. |
| `BookDownloadService` | main.dart | `download()` | 1 dosya | 3 dosya `.instance`. |
| `HomeDataService` | `SplashScreen` prefetch | `refresh()` | 2 dosya | 3 dosya `.instance`. |
| `LastReadBookStore` | main.dart | `updatePage()` | 1 dosya | 8 dosya `.instance`. |

## Ekran-scoped (yerel `ChangeNotifierProvider`)

| Sınıf | Nerede sağlanıyor | Not |
| --- | --- | --- |
| `ReaderProvider` | `incoming_file_service.dart`, `pdf_book_opener.dart`, `offline_library_screen.dart`, `own_books_tab.dart`, `book_open_flow.dart` — her biri `create: (_) => ReaderProvider()` | Temiz: singleton değil, dual-access yok. Bkz. `docs/reader-refactor/reader-provider-split.md`. |
| `AuthProvider` | `phone_login_screen.dart`, `otp_verify_screen.dart` | Temiz. |
| `BalanceController` | `balance_screen.dart` | Temiz. |
| `FilterController` | `filter_screen.dart` | Temiz. |

## Provider'a hiç bağlanmamış singleton'lar

| Sınıf | Kullanım | Not |
| --- | --- | --- |
| `FavoritesSyncService` | 3 dosya, yalnızca `.notifyChanged()` | UI state taşımıyor, salt event-bus gibi kullanılıyor — Provider'a taşımaya gerek olmayabilir, rule 4 kapsamı dışında (widget içinde `watch` edilmiyor). |
| `FinishedBooksSyncService` | 4 dosya, yalnızca `.notifyChanged()` | Aynı durum. |

## Rule 4 ihlali — öncelik sırası

En çok dual-access (`context.watch` + `.instance` karışık) gösteren sınıflar,
refactor sırasında önce ele alınmalı:

1. `AppTheme` (20 direkt vs 2 Provider)
2. `AccountService` (12 vs 3)
3. `BookAccessService` (10 vs 3)
4. `AppLocale` (9 vs 3)
5. `StreakService` (7 vs 3) — reader katmanının bir parçası, Phase B ile birlikte ele alınacak.
6. `SubscriptionService` (6 vs 5), `DownloadedFilesStore` (6 vs 2), `LastReadBookStore` (8 vs 1)

`ReaderProvider`, `AuthProvider`, `BalanceController`, `FilterController` zaten
temiz — bu dört sınıf için rule 4 kapsamında ek iş yok.
