# Common Mistakes

1. **BuildContext async gap** — async işlemden sonra context kullanmadan önce `if (!mounted) return;` kontrolü yap
2. **Provider notifyListeners** — state değişince `notifyListeners()` çağırmayı unutma, UI güncellenmez
3. **CBZ cache bellek** — `cbz_page_cache` büyük dosyalarda bellek şişer, dispose'da cache temizle
4. **sakura_epub WebView** — EPUB WebView'dan Flutter'a callback alırken `addJavaScriptHandler` null safety kontrolü yap
5. **PDF reflow** — `pdfrx` ile text layer tespitinde sayfa henüz render olmadan extraction yapma, await bekle
6. **flutter_secure_storage** — iOS'ta ilk kurulumda keychain erişim hatası, `IOSOptions` ile `accessibility` ayarla
7. **Subscription check** — `subscription_service` her widget'ta ayrı ayrı değil, Provider üzerinden tek noktadan kontrol et
