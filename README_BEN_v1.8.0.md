# BENApp 1.8.1 / V38

Bu paket BEN mobil uygulamasının toplu görsel güncellemesidir.

## Bu sürüm

- BEN pin / wordmark marka dili
- Koyu BEN görünümü varsayılan
- Açık / Koyu / Sistem tema seçimi
- Tek Flutter açılış ekranı: logo + sarı yükleme çubuğu
- Android native splash ile aynı koyu görsel dil
- BEN launcher icon
- Ana akışta sosyal anı kartları
- Beğen / Yorum / Sabitle etkileşimleri
- Anı detayında Beğen / Yorum / Sabitle
- Profilde seviye, puan, rozet ve anı ağacı görünümü
- Keşfet arama/filtre akışının koyu temaya uyarlanması
- Haritada koyu tema için CARTO dark tile görünümü
- Mevcut fotoğraf, video, yazı, konum ve yerel anı depolama özellikleri korunmuştur.
- Sürüm: 3.8.0+38

## Android

Klasörü kendi Flutter projenizin üzerine açtıktan sonra:

    flutter clean
    flutter pub get
    flutter analyze
    flutter build apk --debug

APK:

    build\app\outputs\flutter-apk\app-debug.apk

## Önemli

`android/local.properties`, `.dart_tool`, `build`, Gradle cache, CocoaPods ve iOS Generated.xcconfig pakete dahil edilmemiştir. Bunlar bilgisayara özel/yeniden üretilebilir dosyalardır.

Native splash kaynakları zaten Android/iOS projesine işlenmiştir. Bu sürümde `flutter_native_splash:create` çalıştırmak gerekmez.

## Tasarım hedefi

Bu sürüm, verilen BEN marka/logo ve mobil ekran tasarım görsellerindeki koyu lacivert + sarı görsel dili temel alır.


## V38
- Açılışta Üye Ol / Kayıt Aç ve Giriş Yap ekranı.
- Hesapsız demo ile uygulamaya geçiş.
- Ana akıştan BEN Merkezi erişimi.
- CANLI akış, yorum, beğeni, profil ve ayarlar demo akışları görünür hale getirildi.
