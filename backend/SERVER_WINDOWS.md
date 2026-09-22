# BEN API — Windows yerel sunucu

Evet, gelistirme asamasinda kendi bilgisayarimizi BEN sunucusu olarak kullanabiliriz. Bu PHP + SQLite yapisi icin uygundur. Telefon ile bilgisayarin ayni Wi-Fi aginda olmasi gerekir.

## 1. Sunucuyu baslat

`backend/start_ben_server.bat` dosyasini calistir. Bu, PHP'yi `0.0.0.0:8080` adresine baglar.

## 2. Gerekirse firewall

`allow_ben_api_8080_admin.bat` dosyasini Yonetici olarak bir kez calistir.

## 3. Bilgisayarin yerel IP adresini bul

Windows CMD:

```bat
ipconfig
```

Wi-Fi adaptoru altindaki `IPv4 Address` degerini kullan. Ornek: `192.168.1.42`.

## 4. Flutter'i telefona LAN sunucusuna bagla

```bat
flutter run -d 0025772a0307 --dart-define=BEN_API_URL=http://192.168.1.42:8080/api
```

Buradaki IP kendi bilgisayarinin IPv4 adresi olmalidir.

## 5. Saglik kontrolu

PC'de:

```bat
curl http://127.0.0.1:8080/api/health
```

Telefondan da ayni Wi-Fi uzerinden `http://192.168.1.42:8080/api/health` adresine ulasilabilmeli.

## Not

Bu yapi gelistirme/test sunucusudur. Gercek kullanicilara acilacak production ortaminda PHP built-in server yerine Nginx/Apache + HTTPS, ayri veritabani, medya depolama/CDN, yedekleme ve guvenlik katmanlari kullanilmalidir.
