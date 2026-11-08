# EPUB kapağı yanlış resim gösteriyordu (epub.js asset kayması)

**Tarih**: 2026-08-15
**Dosya**: `packages/sakura_epub/lib/assets/webpage/dist/epub.js`

## Belirti

`Camdaki kız.epub` içinde gerçek kapak (`OEBPS/Images/KAPAK.jpg`, 637x986) olmasına
rağmen reader'ın 1. sayfası kapak yerine kitabın içindeki aykitap tanıtım
görselini (`OEBPS/images/img_1785695053284.jpg`, 848x1199) gösteriyordu.

## Kök neden

epub.js `Resources.prototype.replacements()` içinde:

```js
this.replacementUrls = replacementUrls.filter(url => typeof url === "string");
```

`replacementUrls`, `this.urls` ile **indeks eşleşmeli** olmak zorunda —
`get()`, `substitute()` ve `replaceCss()` üçü de `this.urls.indexOf(...)` ile
adresliyor. Bu EPUB'ın manifest'inde arşivde bulunmayan bir kayıt var
(`<item id="id1" href="Images/main-1.jpg">` — zip'te yok). O asset için
`createUrl` reddediyor, `catch` `null` döndürüyor, `filter` de onu diziden
atıyor. Sonuç: o noktadan sonraki her asset bir sonrakinin blob url'ini alıyor.

```
urls[5] Images/KAPAK.jpg            -> repl[5] = img_1785695053284.jpg'nin blob'u
urls[6] images/img_1785695053284.jpg -> repl[6] = toc.ncx'in blob'u
```

Yani sorun kapak koduyla ilgili değildi; eksik bir manifest kaydı tüm asset
eşlemesini bir kaydırıyordu.

## Çözüm

`filter` yerine `map` — başarısızlar `null` olarak dizide kalıyor, hizalama
bozulmuyor. `substitute()` zaten `if (url && replacements[i])` ile falsy
değerleri atlıyor, dolayısıyla eksik asset artık sadece "yerine konmamış"
oluyor (kırık resim), gerisini bozmuyor.

## Doğrulama

Fiziksel cihazda (SM-A346E, RFCW504Z11B) webview devtools üzerinden
(`adb forward` + CDP `Runtime.evaluate`) `replacementUrls` hizalı şekilde
yeniden kurulup section'lar yeniden render edildi:

- 1. sayfa → gerçek kapak (KAPAK.jpg) göründü.
- `main.xhtml` içindeki görseller doğru blob'lara bağlandı; gerçekten eksik
  olan `main-1.jpg` yerine konmamış kaldı (beklenen).

## Not

Değişiklik bir Flutter asset'i olduğu için cihaza yansıması hot restart
(veya yeni build) gerektirir; hot reload webview asset'ini yenilemez.
`dist/epub.js.map` güncellenmedi (kaynak harita satır ofsetleri bu bölge
için artık birkaç satır kayık).
