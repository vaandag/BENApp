# BENApp V194 — WORLD EXPLORER + LIVE FOUNDATION

V194, V193 harita onarımının doğrudan devamıdır. Ana Harita sekmesi artık iOS'ta çökmeye neden olan native MapLibre platform-view yolunu kullanmaz; mevcut FlutterMap tabanlı harita ana deneyim olarak kullanılır.

## Harita / BEN World
- Ana BEN > Harita sekmesi `flutter_map` ile çalışır; MapLibre 3D ekranı ana navigasyondan çıkarıldı.
- Aynı konumdaki veya aynı bölgedeki çok sayıdaki anı artık fan şeklinde dağılmaz. Zoom seviyesine göre deterministik grid-cluster kullanılır.
- Dünya/şehir seviyesinde sayılı cluster baloncukları, yaklaşıldığında daha küçük gruplar ve sonunda bireysel BEN anıları gösterilir.
- Kullanıcının konumu başlangıç noktası olarak tercih edilir; izin verilmezse mevcut anılardan güvenli bir başlangıç seçilir.
- `MemoryScore`: mesafe + görülmemişlik + tazelik + sosyal sinyaller ile yerel öneri sıralaması oluşturur.
- `BEN dünyasında dolaş` / `SONRAKİ ANI` ile seçili anıdan başka anılara otomatik keşif geçişi eklenmiştir.
- Sonraki/önceki anı geçmişi harita oturumu boyunca tutulur; görülmüş/beğenilmiş/kaydedilmiş durumlar ise lokal olarak saklanır.
- Mevcut kalıcı anı/story ayrımı korunur; story anıları haritada ayrı ikonla gösterilir.
- Mevcut demo harita verisi korunur; gerçek API/yerel anılar da aynı keşif algoritmasından geçer.
- iOS'ta 3D butonu gizlenir; deneysel `Ben3DMapScreen` dosyası silinmez.

## CANLI
- Eski CANLI ekranının yalnızca `lives` tablosuna kayıt atan akışı yerine WebRTC tabanlı yayın stüdyosu eklenmiştir.
- Yayıncı kamera + mikrofon akışını açar, BEN backend'de canlı oturumu oluşturur ve izleyiciler için peer bağlantıları kurar.
- PHP backend'de peer, SDP offer/answer ve ICE candidate sinyalleşmesi için realtime signaling tabloları ve endpoint'ler eklendi.
- İzleyici canlı listesinde bir yayına dokunup WebRTC video akışını almayı dener.
- Heartbeat ve stale-peer temizliği eklenmiştir.
- Bu sürümde WebRTC bağlantısı STUN ile kurulmaya çalışılır. Gerçek internet ölçeğinde, NAT/firewall sorunlarını kapsayan üretim sistemi için TURN ve tercihen SFU/media server katmanı ayrıca gerekecektir.

## Ağ / backend
- `live` GET artık hem doğrudan listeyi hem eski ekranların beklediği map biçimini istemci tarafında tolere eder.
- Canlı yayın için `live/{id}/join`, `peers`, `signals`, `signal`, `heartbeat`, `leave`, `stop` endpoint'leri eklendi.
- Host peer kimliği sunucu tarafında doğrulanır; istemciden gelen `user_id` canlı sahibini belirlemek için kullanılmaz.
- V194 API sağlık çıktısı `version=194` verir.

## Test sırası
1. Windows'ta `flutter pub get`
2. `flutter analyze`
3. iPhone IPA üretimi (GitHub Actions `ios.yml`)
4. iPhone'da BEN > Harita: uygulama çökmemeli, harita açılmalı, cluster'lar görünmeli, `GEZ` ve `SONRAKİ ANI` çalışmalı.
5. İkinci bir cihazla aynı API sunucusunda CANLI açıp izleme akışı test edilmeli.

## Dürüst kapsam
V194 gerçek WebRTC yayın akışını ve signaling'i ekler; fakat production-grade global yayın altyapısı için TURN/SFU, ölçekleme, moderasyon, kayıt/tekrar oynatma, içerik güvenliği ve dağıtık state katmanları henüz ayrı işlerdir.


## V194 Analyze Fix 1
- Removed the redundant nullable assignment in the map zoom handler.
- Made the bottom explorer suggestion null-safe.
- Added braces to the live peer cleanup loop.
- This fix is limited to analyzer cleanliness; the World Explorer and Live foundations remain unchanged.
