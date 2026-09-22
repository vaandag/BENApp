# BENApp v3.0 x2

Bu sürüm mevcut çalışan BENApp kaynak ağacının üzerine hazırlanmıştır.

## Bu sürümde
- BEN sarı/lacivert görsel dili tekilleştirildi.
- Ana akış yeniden düzenlendi: üst özet, filtre çipleri, bölüm başlıkları ve daha tutarlı kart hiyerarşisi.
- Beğeni / yorum / sabitle etkileşimleri korunarak daha temiz bir aksiyon satırı oluşturuldu.
- Telefon ve geniş ekranlar için ana akış genişliği sınırlandı.
- Alt navigasyonda aktif sekme için tutarlı BEN sarı vurgu eklendi.
- Üst bara bildirim + Ayarlar erişimi eklendi; mevcut tema seçimi korunuyor.
- Koyu/açık tema için ortak tasarım tokenları eklendi.
- Anı oluşturma bottom-sheet'i koyu temada da uygulama diliyle uyumlu hale getirildi.
- Mevcut harita, profil, keşfet, anı detay ve medya özellikleri kaynakta korunmuştur.
- Sürüm numarası 3.0.0+30 olarak güncellendi.

## APK
Bu paket kaynak koddur. Windows'ta `D:\BENApp\mobile` klasörüne çıkarıldıktan sonra:

    flutter clean
    flutter pub get
    flutter analyze
    flutter build apk --debug

komutlarıyla APK üretilebilir.
