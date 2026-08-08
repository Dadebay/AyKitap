# Bitirdiklerim kitaplık sekmesi

- Kitaplık ekranına `Bitirdiklerim` sekmesi eklendi.
- Sekme, `GET /books/all?my_books=true&finished=true` isteğiyle tamamlanan kitapları getirir.
- Bir kitap %100 tamamlandığında sekme otomatik yenilenir.
- Tamamlanan kitaplar yanıtındaki metin biçimli `progress` değeri de güvenli
  biçimde sayıya dönüştürülür.
- Kitap detayında `progress >= 100` olduğunda tamamlandı flag'i aktif görünür.
- Uygulamadaki para tutarları `TMT` olarak standartlaştırıldı ve promokod
  girişleri yazılırken büyük harfe dönüştürülür.
- Bakiye sayfasında bakiye geçmişi ve kartla ödemeler, iOS tarzı kaydırmalı
  sekmelerle ayrıldı.
- Alt menüdeki Play sekmesi son açılan kitabı ve yerel sayfasını saklayarak
  kaldığı yerden açar; erişimi biten abonelik kitaplarını göstermez.
- `flutter analyze` çalıştırıldı; eklenen kodla ilgili hata bulunmadı.
