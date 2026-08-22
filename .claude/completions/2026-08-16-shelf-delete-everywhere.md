# Kitap tekjäm — her bölümde "poz" (long-press delete)

**Talap (dizaýner):** tekjedäki kitaplary diňe "Ýüklenenler" bölüminde pozup
bolýardy. Ähli bölümlerde-de pozup bolar ýaly edilmeli; kitabyň üstüne
basyp saklanyňda (long-press) delete dialogy çykmaly. Berlen API-lar:

- `DELETE /books/bought/:id` — satyn alnan kitaby aýyrmak
- `DELETE /books/:id/progress` — okaýyş progresini pozmak (soňky progress
  **we** finished — ikisi üçin ýeke API)

## Näme edildi

| Tab | Long-press "poz" nämä täsir edýär |
|---|---|
| Okaýanlarym | `DELETE /books/:id/progress` + `ReadingBooksStore` shadow |
| Okap gutaranlarym | şol bir progress API (iki tekje bir ýazgynyň iki görnüşi) |
| Ýüklenenler | öňden bardy (lokal faýl + Save to Files sheet) — üýtgemedi |
| Satyn Alynanlar | `DELETE /books/bought/:id` + `BookAccessService` keşi |
| Halaýanlarym | `DELETE /books/unlike/:id` |
| Öz Kitaplarym | lokal faýl `OwnBooksStore.remove` (CBZ/reflow keşleri bilen) |

## Üýtgän faýllar

- `lib/core/network/api_endpoints.dart` — `bookProgress` DELETE dokumenti
- `lib/core/services/book_api_service.dart` — `deleteProgress(bookId)`
- `lib/core/services/reading_books_store.dart` — `remove(bookId)` (offline
  shadow-dan hem aýyrmasa, kitap indiki açylyşda tekjä gaýdyp gelýär)
- `lib/core/services/book_access_service.dart` — `removePurchased(bookId)`
  (ýogsa öňden ýüklenen faýl oflaýn açylmagyny dowam edýär)
- `lib/core/localization/strings/library_strings.dart` — dialog/snackbar
  setirleri (tk/ru/tr), her tekje üçin aýratyn düşündiriş
- `lib/modules/library/widgets/shelf_delete.dart` — **täze**: `ShelfRemoval`
  enum + `confirmShelfDelete` dialogy (bir dialog, ähli tekjeler üçin)
- `lib/modules/library/widgets/library_tabs.dart` — `ApiBooksTab.removal`,
  `_confirmDelete` (optimistik aýyrmak + ýalňyşda serweriň sebäbi)
- `lib/modules/library/library_screen.dart` — her taba `removal` berildi
- `lib/modules/library/widgets/own_books_tab.dart` +
  `lib/core/widgets/own_book_spine_cover.dart` — long-press goşuldy

## Ikinji tapgyr (dizaýneriň soragy boýunça)

**1. Halaýanlarym — cover-iň sag ýokarsynda heart butony.** Bir gezek basmak
bilen halaýanlardan aýyrýar (dialog ýok — Book Detail-daky ýürek hem şeýle
işleýär, toggle). `LibraryBookCover.onUnfavorite`; diňe halaýanlar tabynda
görünýär (`removal == ShelfRemoval.favorite`-dan gelip çykýar). Badge 26px,
daşyndan 5px görünmeýän padding — barmak degire ýaly. `HitTestBehavior.opaque`
— ýogsa ýüregiň gyrasyna deglende kitap açylýardy.

**2. Delete dialog dizaýny täzelendi.** Öňki tekiz `AlertDialog` aýryldy;
indi `StreakRewardDialog`-yň dilinde: 24 radiusly karta, ýokarsynda pozuljak
kitabyň öz jildi (72×100) we onuň burçunda gyzyl trash badge, aşagynda doly
inli gyzyl "Poz" butony, onuň aşagynda ýönekeý "Ýatyr". Jildi ýok kitaplar
(Öz Kitaplarym) üçin gyzyl tegelek ikon fallback. Ýeke-täk doldurylan buton
— pozmak, şoň üçin dialogy okaman basmak ýalňyşlyga eltmeýär.

**3. Ýüklenenler taby hem indi şol dialogy açýar.** Öňki bottom sheet
(Faýllara ýaz / Poz → yzyndan ýene bir confirm dialog) aýryldy — iki ädimdi
we beýleki tekjelerden tapawutlydy. Indi basyp saklamak göni dialogy açýar;
"Faýllara ýaz" ýitmedi, dialogyň içinde outline buton bolup galdy (Poz —
gyzyl doldurylan, Faýllara ýaz — outline, Ýatyr — ýönekeý).
`showShelfDeleteDialog` indi `bool` däl-de
`ShelfDeleteChoice { cancel, delete, extra }` gaýtarýar; sözbaşyny hem
üýtgedip bolýar (`title:` — ýüklemeler üçin "Ýüklemäni poz").

## Bellikler

- Hiç bir ýerde katalogdaky kitabyň özi pozulmaýar — diňe ulanyjy bilen
  kitabyň arasyndaky baglanyşyk (progress / satyn alyş / halamak).
- Dialog ýeke ýerde — `confirmShelfDelete`; ähli tekjeler şony ulanýar,
  ýene bir zat üýtgemeli bolsa diňe şol faýl.
- `flutter analyze` — täze ýalňyş ýok. `test/reader_landscape_test.dart`
  öňden döwük (`PdfBottomBar.onAddNote` talap edilýär) — bu işe degişli däl.
