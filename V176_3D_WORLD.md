# BENApp V176 — 3D Dünya

Bu sürüm mevcut 2D `MapScreen`i değiştirmez. Harita başlığına yeni bir 3D butonu ekler ve ayrı `Ben3DMapScreen` açar.

## Teknoloji
- MapLibre GL Flutter `^0.27.1`
- OpenFreeMap / OpenStreetMap tabanlı vektör harita
- Gerçek kamera eğimi/döndürme
- 3D bina extrusion katmanı
- BEN anıları gerçek koordinatlarıyla 3D haritada daire pin olarak gösterilir
- Pin seçildiğinde kamera anıya yaklaşır
- Alttaki karttan `MemoryFullscreenViewer` açılır; mevcut beğeni/yorum/kaydet/paylaş akışı korunur.

## Android test
```cmd
cd /d D:\BENApp\mobile
flutter pub get
flutter analyze
flutter build apk --debug --dart-define=BEN_API_URL=http://192.168.1.24:8080/api
```

## Not
MapLibre açık kaynak bir harita motorudur ve bu prototipte Mapbox access token gerektirmez. MapLibre Flutter 0.27.1 Android/iOS/Web destekler; minimum Flutter 3.29 ve Dart 3.7 ister.

3D bina verisi OpenFreeMap'in `planet` vector source içindeki `building` katmanından alınır. Üretim aşamasında tile sağlayıcısının kullanım/atıf koşulları ayrıca kontrol edilmelidir.
