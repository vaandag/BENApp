# BENApp GREEN FIX2

Bu patch iki üretim riskini hedefler:

1. Harita sağlayıcısı tek bir dosyada yapılandırılır. `BEN_MAPTILER_KEY` verildiğinde MapTiler Streets v4 256px raster tiles kullanılır; anahtar yoksa geliştirme/test için OpenStreetMap fallback çalışır. MapTiler anahtarını mobil uygulama için User-Agent kısıtlamasıyla koruyun.
2. Yeni anılar önce cihazda kalıcı olarak saklanır ve yükleme başarısızsa kalıcı bir eşitleme kuyruğuna alınır. Uygulama yeniden öne geldiğinde/yenilendiğinde tekrar denenir.

## GitHub Actions secrets

Store/TestFlight build'inde MapTiler kullanmak için repository secrets içine `BEN_MAPTILER_KEY` ekleyin. Production backend için public HTTPS API adresini `BEN_API_URL` secret'ına koyun. Secret yoksa workflow mevcut LAN geliştirme adresine geri döner.

## Dosyalar

- `lib/core/config/map_config.dart`
- `lib/services/pending_memory_sync.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/map_screen.dart`
- `lib/screens/ben_3d_map_screen.dart`
- `lib/features/memories/data/php_memory_repository.dart`
- `.github/workflows/ios.yml`

> Not: Bu patch kod tarafındaki fallback/senkronizasyon sorunlarını çözer. App Store için backend'in ayrıca internet üzerinden erişilebilen gerçek HTTPS adresine taşınması gerekir; `BEN_API_URL` secret'ı bunun için kullanılır. Harita için `BEN_MAPTILER_KEY` secret'ı verildiğinde MapTiler kullanılır, verilmezse test fallback'i OSM olarak kalır.
