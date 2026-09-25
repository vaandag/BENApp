# BENApp V192 — Production Foundation

V191 BEN World Premium üzerine kurulmuştur. Mevcut kullanıcı deneyimi ve ana navigasyon korunurken uygulamanın transport, auth, persistence ve backend güvenliği güçlendirilmiştir.

## Included
- Tek composition root: shared ApiClient, AuthService ve repositories.
- Dayanıklı auth token store ve restore-session akışı.
- API katmanında request timeout, safe GET retry, request-id, ağ/401/5xx ayrımı ve upload timeout.
- Backend bootstrap/schema/auth yardımcı katmanları ayrıştırıldı.
- SQLite migration tablosu ve indeksler eklendi; eski veriler için idempotent migration yolu korundu.
- Oturum sahibi sunucuda Bearer token'dan çözülüyor; kritik yazma işlemlerinde istemciden gelen user_id/follower_id yok sayılıyor.
- Mesaj silme yalnızca gönderene izin verecek şekilde yetkilendirildi.
- Coin gift işleminde token sahibi, pozitif miktar ve bakiye doğrulaması + transaction kullanılıyor.
- Anı silme gerçek backend endpoint'ine bağlandı; ilişkili like/save/comment kayıtları transaction içinde temizleniyor.
- Production hata yanıtları artık ham PHP exception mesajı sızdırmıyor. BEN_DEBUG=1 ile geliştirme tanıları açılabilir.
- CORS için BEN_ALLOWED_ORIGIN environment ayarı eklendi; ayar yoksa mevcut geliştirme davranışı korunur.

## Intentional compatibility
Eski ekranlar halen AuthService.currentUser ve ApiClient.token statik erişimlerini kullanabiliyor. Bu alanlar geriye dönük uyumluluk katmanı olarak bırakıldı; yeni ekranlar AppDependencies üzerinden paylaşılan servisleri kullanmalıdır.

## Validation
Bu çalışma ortamında Flutter/Dart SDK bulunmadığı için `flutter analyze` ve APK derlemesi burada çalıştırılamadı. PHP tarafındaki tüm dosyalar `php -l` ile kontrol edilmelidir; Windows geliştirme makinesinde ayrıca `flutter analyze` + `flutter build apk --release` çalıştırılmalıdır.
