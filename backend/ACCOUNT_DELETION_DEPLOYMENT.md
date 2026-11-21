# BEN dış hesap silme sayfası

Bu sayfa Google Play'in hesap oluşturabilen uygulamalar için istediği uygulama dışı hesap silme talebi giriş noktası olarak kullanılmak üzere hazırlanmıştır.

## Yayına alma

1. `backend/public/account-deletion.html` dosyasını BEN API'sinin HTTPS web köküne dağıt.
2. API yönlendirmesinin `/api/auth/login` ve `/api/account/delete` yollarını aynı origin altında erişilebilir tuttuğunu doğrula. Farklı bir API yolu kullanılıyorsa HTML içindeki `API_BASE` sabitini değiştir.
3. Sayfayı HTTPS üzerinden açıp test hesabıyla doğrula. Yanlış parola reddedilmeli; doğru parolayla giriş sonrası aynı hesap silme API'si çağrılmalı.
4. Gerçek, herkese açık URL'yi Google Play Console'daki hesap silme URL alanına ekle.

## Güvenlik davranışı

- E-posta ve mevcut parola ile mevcut `auth/login` API'sinde kimlik doğrulaması yapılır.
- Dönen kısa ömürlü oturum anahtarı yalnızca bu sayfanın belleğinde tutulur ve `account/delete` uç noktasına verilir.
- Parola veya oturum anahtarı localStorage/cookie içine kaydedilmez.
- Sayfa HTTPS haricinde localhost dışında formu göndermez.
- Bu dosya tek başına mağaza URL'si oluşturmaz; dağıtıma alınması ve gerçek HTTPS adresinin Play Console'a kaydedilmesi gerekir.
