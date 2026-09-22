# BENApp Flutter temel

BENApp; BEN, Harita, Keşfet, Mesajlar ve Profil sekmelerini içeren Flutter temelidir.

## Çalışan çekirdek

- OpenStreetMap tabanlı harita, cihaz konum izni ve konumlu anı pinleri
- Fotoğraf, video, metin ve konum anısı oluşturma
- Çevrimdışı yerel taslak saklama
- Mevcut PHP REST sözleşmesine bağlı anı okuma/yazma: `memories`, `memories/{id}/like`, `memories/{id}/save`, yorumlar, profil, bildirimler ve harita uç noktaları için merkezi istemci
- Sunucu erişilemezse uygulama yerel anılarla çalışmayı sürdürür

## PHP API adresi

Android emülatöründe varsayılan adres `http://10.0.2.2:8080/api`dir. Fiziksel telefonda kendi bilgisayarınızın yerel ağ IP'sini kullanın:

```powershell
flutter run --dart-define=BEN_API_URL=http://192.168.1.10:8080/api
```

PHP uygulaması JWT döndürüyorsa, oturum açma akışında dönen token `ApiClient.token` alanına atanmalıdır. Bu API katmanı `Authorization: Bearer <token>` başlığını otomatik ekler.

## Mimari

`lib/core` yapılandırma/ağ; `lib/features` iş alanları; `lib/models` ortak domain modelleri; `lib/services` ise cihaz/yerel depolama uyarlayıcıları içindir. Takip, yorum, beğeni, bildirim, DM, hikâye ve reels için yeni kodlar kendi feature klasörlerinde eklenmelidir.
