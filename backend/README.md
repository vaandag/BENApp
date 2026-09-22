# BEN API — V39

PHP + SQLite backend başlangıç katmanı. Flutter uygulamasının `BEN_API_URL` değerine bağlanır.

## Çalıştırma

Windows örneği:

```bat
D:\php\php.exe -S 0.0.0.0:8080 -t D:\BENApp\mobile\backend\public
```

Sonra:

```bat
curl http://127.0.0.1:8080/api/health
```

Beklenen cevap:
`{"ok":true,"service":"BEN API","version":"39"}`

## V39 veri alanları
- users
- memories
- comments
- messages (okundu/düzenleme/silme için altyapı)
- follows
- notifications
- lives
- coin_transactions

Bu paket canlı yayın görüntü/ses taşıma sunucusu değildir; CANLI veri/API katmanının temelidir. Gerçek yayın transport'u sonraki backend altyapısında WebRTC/RTMP katmanına bağlanacaktır.
