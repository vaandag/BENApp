# BEN V45 — CANLI AKIŞ backend foundation

4.3.1+44 üzerine geliştirildi.

- CANLI AKIŞ gerçek PHP API anı listesini kullanır; API erişilemezse mevcut yerel/demonstrasyon akışı korunur.
- `memory_likes` ve `memory_saves` tabloları eklendi.
- `POST /api/memories/{id}/like` ve `/save` toggle endpointleri eklendi.
- Feed response'unda like/save/comment sayaçları bulunur.
- `GET /api/memories/{id}/comments` eklendi.
- Yorum gönderme ekranı gerçek memory ID ile API'ye yorum gönderebilir.
- API sağlık sürümü 45'e yükseltildi.

Not: Fiziksel Android cihazdan yerel PC backend'ine erişim için LAN IP veya ADB reverse kullanılmalıdır; uygulama varsayılanı emulator adresidir (`10.0.2.2`).
