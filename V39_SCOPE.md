# BENApp V39 — kapsam

V39, V38 üzerine bütün uygulamayı baştan sona gözden geçirme sürümüdür.

## Korunan temel
- V35 BEN World / harita davranışı referans alınır; mevcut harita ekranı bu pakette silinmedi.
- Mevcut anı, koleksiyon, profil, ayarlar, mesaj ve yorum ekranları korunur.

## V39 geliştirme alanları
- CANLI: yayın akışı, izleyici, sohbet, beğeni, hediye, ortak yayın, moderasyon UI
- Coin & hediye: bakiye ve hediye akışı
- Sosyal: profil, takip, arkadaş, sessize alma, engelleme, rapor
- AN / Story: fotoğraf, video, yazı, izleyenler, gizlilik UI
- Etkinlikler: oluşturma/katılım/konum/duyuru UI
- Bildirimler
- XP / rozet / seviye
- Gelişmiş Keşfet: isim/yer/zaman/yakın/canlı/etkinlik
- Güvenlik & moderasyon
- BEN API + SQLite veri modeli ve endpoint başlangıcı
- Mesaj/yorum gibi mevcut özelliklerin gerçek API'ye taşınmasına uygun altyapı

## Durum
Bu ZIP, V39 geliştirmesinin gerçek kod tabanına işlenmiş ilk kapsamlı paketidir. Gerçek üretim CANLI video transport'u, push notification sağlayıcısı, ödeme sağlayıcısı ve çoklu cihaz dağıtımı için ayrıca servis/anahtar yapılandırması gerekir; bunlar sahte şekilde “çalışıyor” gösterilmemiştir.
