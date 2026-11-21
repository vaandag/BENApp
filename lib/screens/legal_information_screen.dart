import 'package:flutter/material.dart';

enum LegalDocument { privacy, terms }

class LegalInformationScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalInformationScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocument.privacy;
    final sections = isPrivacy ? _privacySections : _termsSections;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? 'Gizlilik politikası' : 'Kullanım koşulları'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6A23E)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFF805400)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'YAYIN ÖNCESİ TASLAK — İşletmeci ve destek iletişim bilgileri, sunucu/alt hizmet sağlayıcıları, saklama süreleri ve hukuki değerlendirme tamamlanmadan bu metinler resmî politika olarak kullanılmamalıdır.',
                    style: TextStyle(
                      color: Color(0xFF684600),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isPrivacy ? 'BEN Gizlilik Politikası' : 'BEN Kullanım Koşulları',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Yayın tarihi: [YAYIN TARİHİ] • İşletmeci: [TİCARİ ÜNVAN / İŞLETMECİ]',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.body,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Text(
            'Yayın öncesi zorunlu tamamlama alanları',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '• [Ticari ünvan ve veri sorumlusu]
'
            '• [Yasal adres ve destek e-posta adresi]
'
            '• [Sunucu ülkesi, barındırma ve diğer alt hizmet sağlayıcıları]
'
            '• [Yedekleme ve veri saklama süreleri]
'
            '• [KVKK başvuru/iletişim yöntemi ve yürürlük tarihi]',
            style: TextStyle(height: 1.55),
          ),
        ],
      ),
    );
  }

  static const _privacySections = <_LegalSection>[
    _LegalSection(
      '1. Veri sorumlusu',
      'BEN hizmetinin işletmecisi [TİCARİ ÜNVAN / İŞLETMECİ]’dir. Yasal adres [YASAL ADRES], gizlilik ve veri talepleri için iletişim adresi [DESTEK E-POSTASI] olarak tamamlanmalıdır.',
    ),
    _LegalSection(
      '2. İşlenen veri kategorileri',
      'Mevcut uygulama kodunda hesap oluşturma ve giriş için kullanıcı adı, e-posta adresi ve parola özeti; profil için biyografi, avatar ve profil tercihleri; anılar için başlık, metin, fotoğraf/video medya adresleri, paylaşım gizliliği ve Story sona erme zamanı işlenir. Kullanıcı anıya konum eklediğinde enlem, boylam ve konum doğruluğu da kaydedilebilir.',
    ),
    _LegalSection(
      '3. Sosyal ve iletişim verileri',
      'Takip ilişkileri, beğeniler, kaydedilen anılar, yorumlar, doğrudan mesajlar, bölgesel sohbet mesajları, bildirimler, canlı yayın oturumları ve canlı yayın bağlantı/sinyal kayıtları hizmetin ilgili özellikleri çalışırken işlenir.',
    ),
    _LegalSection(
      '4. Güvenlik ve moderasyon verileri',
      'Engelleme kayıtları ve kullanıcı/içerik şikâyetleri; şikâyet nedeni, açıklama, durum ve inceleme bilgileri kötüye kullanımı önlemek ve topluluk kurallarını uygulamak için işlenebilir.',
    ),
    _LegalSection(
      '5. Konum izni',
      'Uygulama cihaz konumunu yalnızca ilgili özelliği kullanırken ve cihaz izni verildiğinde almaya çalışır. Konum eklemeden anı paylaşabilirsin. Kaydedilen konum, ilgili anının gizlilik ayarına göre gösterilebilir. Konum iznini cihaz ayarlarından kapatabilirsin.',
    ),
    _LegalSection(
      '6. Harita ve iletişim altyapısı',
      'Harita döşemeleri yapılandırmaya bağlı olarak MapTiler veya OpenStreetMap üzerinden yüklenir. Canlı yayın bağlantılarında yapılandırılmış STUN/TURN altyapısı kullanılabilir. Yayına alınmadan önce bu sağlayıcıların güncel listesi, veri işleme rolleri, aktarım ülkeleri ve sözleşmeleri burada belirtilmelidir: [ALT HİZMET SAĞLAYICILARI VE ÜLKELER].',
    ),
    _LegalSection(
      '7. İşleme amaçları',
      'Veriler; hesabı ve profili çalıştırmak, anı ve Story paylaşımını sunmak, harita/konum özelliklerini işletmek, mesajlaşma ve canlı yayın sağlamak, kullanıcı tercihlerini uygulamak, güvenliği korumak, şikâyetleri incelemek ve hizmet hatalarını gidermek amacıyla kullanılabilir. Kesin hukuki sebepler ve KVKK kapsamındaki açıklamalar hukuk danışmanı tarafından tamamlanmalıdır.',
    ),
    _LegalSection(
      '8. Saklama ve silme',
      'Hesabını Profil ayarlarından veya [DIŞ HESAP SİLME URL’Sİ] adresinden silebilirsin. Hesap silme işlemi hesabınla ilişkili profil, anı, Story, yorum, mesaj, takip, bildirim, moderasyon ve medya kayıtlarının silinmesini başlatır. Yedeklerde, güvenlik kayıtlarında veya mevzuat gereği tutulabilecek veriler için kesin saklama süresi ve silme takvimi [SAKLAMA / YEDEK SÜRELERİ] alanında açıklanmalıdır.',
    ),
    _LegalSection(
      '9. Hakların ve başvuru',
      'Kişisel verilerine ilişkin taleplerini [VERİ SORUMLUSU BAŞVURU ADRESİ] üzerinden iletebilirsin. Başvuru kanalı, kimlik doğrulama yöntemi ve yanıt süresi gerçek işletmeci ve yürürlükteki mevzuata göre doldurulmalıdır.',
    ),
    _LegalSection(
      '10. Politika değişiklikleri',
      'Bu metnin son sürümü [POLİTİKA URL’Sİ] adresinde yayımlanır. Önemli değişikliklerin kullanıcılara nasıl bildirileceği ve yürürlük tarihi yayın öncesinde belirlenmelidir.',
    ),
  ];

  static const _termsSections = <_LegalSection>[
    _LegalSection(
      '1. Hizmet',
      'BEN; kullanıcıların insanları, yerleri, zamanları ve anıları harita ve sosyal özellikler üzerinden paylaşmasına imkân veren bir hizmettir. Hizmetin özellikleri zaman içinde değişebilir.',
    ),
    _LegalSection(
      '2. Hesap ve güvenlik',
      'Hesap bilgilerini doğru tutmalı, oturum bilgilerini korumalı ve hesabındaki işlemlerden sorumlu olmalısın. Hesabına yetkisiz erişim olduğunu düşünüyorsan [DESTEK E-POSTASI] üzerinden bildirim yap.',
    ),
    _LegalSection(
      '3. İçerik ve paylaşım hakları',
      'Yalnızca paylaşma hakkına sahip olduğun metin, fotoğraf, video, konum ve diğer içerikleri yükle. İçeriğinin görünürlüğünü seçerken herkese açık, takipçiler veya özel gibi paylaşım seçeneklerini kontrol et. Başkalarının telif, gizlilik ve kişilik haklarını ihlal etme.',
    ),
    _LegalSection(
      '4. Story ve kalıcı anılar',
      'Story içerikleri uygulamadaki tanımlı süre sonunda sona erer; kalıcı anılar kullanıcı tarafından silinene veya hizmetin kuralları kapsamında kaldırılana kadar saklanabilir. Story süresi dolması, yasal yedekleme/saklama açıklamalarının yerini almaz.',
    ),
    _LegalSection(
      '5. Yasaklı davranışlar',
      'Taciz, tehdit, zorbalık, nefret söylemi, şiddeti veya kendine zarar vermeyi teşvik, cinsel istismar, izinsiz özel bilgi/konum paylaşımı, spam, dolandırıcılık ve başkasının haklarını ihlal eden içerikler yasaktır.',
    ),
    _LegalSection(
      '6. Şikâyet, engelleme ve moderasyon',
      'Kullanıcıları veya içerikleri uygulama içinden şikâyet edebilir ve kullanıcıları engelleyebilirsin. BEN, şikâyetleri inceleyebilir; kuralları ihlal eden içerikleri kaldırabilir veya hesapları kısıtlayabilir. İnceleme ve itiraz süreci [MODERASYON/İTİRAZ İLETİŞİMİ] alanında açıklanmalıdır.',
    ),
    _LegalSection(
      '7. Sanal öğeler ve ücretler',
      'Coin, hediye, premium veya diğer sanal öğelerin satın alma, kullanım, iade ve sona erme şartları; bu özellikler ücretli olarak sunulmadan önce ayrı ve açık biçimde tamamlanmalıdır: [SANAL ÖĞE/ÖDEME ŞARTLARI].',
    ),
    _LegalSection(
      '8. Hizmetin kullanılabilirliği',
      'Hizmetin bakım, güvenlik, altyapı arızası veya başka teknik nedenlerle geçici olarak kesintiye uğrayabileceğini kabul edersin. Kesin garanti ve sorumluluk hükümleri işletmecinin ve uygulanacak hukukun gerekliliklerine göre hukuk danışmanı tarafından tamamlanmalıdır.',
    ),
    _LegalSection(
      '9. Hesabın kapatılması ve yürürlük',
      'Hesabını uygulama içinden veya [DIŞ HESAP SİLME URL’Sİ] üzerinden silebilirsin. Kullanım koşullarının yürürlük tarihi [YÜRÜRLÜK TARİHİ], işletmeci [TİCARİ ÜNVAN / İŞLETMECİ], destek iletişimi [DESTEK E-POSTASI] olarak tamamlanmalıdır.',
    ),
  ];
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection(this.title, this.body);
}
