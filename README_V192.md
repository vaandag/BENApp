# BENApp V192

V191 BEN World Premium üzerine production foundation güncellemesidir. UI/UX akışları korunur; altyapı tarafı servis paylaşımı, auth, API transport, SQLite migration ve backend authorization bakımından güçlendirilmiştir.

## Local Android run

```bat
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

LAN backend için:

```bat
flutter run -d <DEVICE_ID> --dart-define=BEN_API_URL=http://<PC-IP>:8080/api
```

## Architecture rule

Yeni feature kodu doğrudan `ApiClient()` oluşturmamalı. `AppDependencies` içindeki paylaşılan API/repository servisleri kullanılmalı. Ekranlar UI odaklı kalmalı; endpoint ve veri dönüştürme işleri repository/service katmanında tutulmalı.
