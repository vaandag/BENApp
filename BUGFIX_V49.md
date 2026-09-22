# BEN V49 Bugfix

- Gerçek hesap oturumu cihazda kalıcı hale getirildi.
- Giriş/kayıt sonrası kullanıcı kimliği akış ve profil boyunca kullanılıyor.
- Demo kullanıcıları gerçek hesap oturumunda akış ve Story listesinden çıkarıldı.
- Yeni yerel fotoğraf anıları akışta gerçek fotoğraf olarak gösteriliyor.
- Yeni anı yayınlandıktan sonra yerel medya kaybolmuyor.
- Beğeni/kaydetme istekleri aktif kullanıcı kimliğiyle gönderiliyor.
- Ana Profil istatistikleri backend'den yenileniyor.
- Story kartları tıklanabilir tam ekran görüntüleyiciye bağlandı; sağ/sol dokunma ile ileri/geri.

Not: PHP API şu aşamada medya dosyasını sunucuya yüklemiyor; bu nedenle yeni fotoğraf/video aynı cihazdaki yerel medya olarak korunur. Gerçek çok cihazlı medya için sonraki aşamada dosya upload/storage endpoint'i gerekir.
