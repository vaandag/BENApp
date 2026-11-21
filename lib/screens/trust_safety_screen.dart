import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import 'admin_moderation_screen.dart';
import 'legal_information_screen.dart';
import 'legal_information_screen.dart';

class TrustSafetyScreen extends StatefulWidget {
  const TrustSafetyScreen({super.key});

  @override
  State<TrustSafetyScreen> createState() => _TrustSafetyScreenState();
}

class _TrustSafetyScreenState extends State<TrustSafetyScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _blocked = [];
  bool _isAdmin = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.get('blocks');
      final rows = raw is List ? raw : const [];
      var isAdmin = false;
      try {
        final adminStatus = await _api.get('admin/status');
        isAdmin = adminStatus is Map && adminStatus['is_admin'] == true;
      } catch (_) {
        // A failed admin check must never grant moderator access.
      }
      if (!mounted) return;
      setState(() {
        _blocked = rows.whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _isAdmin = isAdmin;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unblock(Map<String, dynamic> user) async {
    final id = int.tryParse('${user['id']}') ?? 0;
    if (id <= 0) return;
    try {
      await _api.delete('users/$id/block');
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Engel kaldırılamadı: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güvenlik ve gizlilik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Engellediğin kişiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            ListTile(
              title: const Text('Engellenen kişiler yüklenemedi'),
              subtitle: Text(_error!),
              trailing: IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            )
          else if (_blocked.isEmpty)
            const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Henüz engellediğin biri yok.'),
            )
          else
            ..._blocked.map((user) {
              final username = '${user['username'] ?? 'BEN kullanıcısı'}';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(username.isEmpty ? '?' : username[0].toUpperCase()),
                  ),
                  title: Text('@$username'),
                  trailing: TextButton(
                    onPressed: () => _unblock(user),
                    child: const Text('Engeli kaldır'),
                  ),
                ),
              );
            }),
          if (_isAdmin) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Şikâyet yönetimi',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Kullanıcı bildirimlerini incele ve sonuçlandır'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminModerationScreen()),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text('BEN topluluk kuralları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const _PolicyCard(
            title: 'Saygılı iletişim',
            body: 'Taciz, tehdit, zorbalık, nefret söylemi ve hedef gösterme yasaktır.',
          ),
          const _PolicyCard(
            title: 'Güvenli içerik',
            body: 'Şiddeti teşvik eden, cinsel istismar içeren, kendine veya başkasına zarar vermeyi özendiren içerikler paylaşılmaz.',
          ),
          const _PolicyCard(
            title: 'Haklar ve mahremiyet',
            body: 'Yalnızca paylaşma hakkına sahip olduğun içerikleri yükle. Başkalarının özel bilgilerini ve konumunu izinsiz paylaşma.',
          ),
          const _PolicyCard(
            title: 'Şikâyet ve yaptırım',
            body: 'Uygunsuz kullanıcı veya anıları şikâyet edebilirsin. Şikâyetler incelenir; kuralları ihlal eden içerikler kaldırılabilir ve hesaplar kısıtlanabilir.',
          ),
          const SizedBox(height: 26),
          const Text(
            'YASAL BİLGİLER',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text(
                'Gizlilik politikası',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Hangi verilerin işlendiğini ve hesap silmeyi öğren'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    document: LegalDocument.privacy,
                  ),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text(
                'Kullanım koşulları',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('BEN topluluk ve kullanım şartları'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    document: LegalDocument.terms,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'YASAL BİLGİLER',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Gizlilik politikası'),
              subtitle: const Text('İşlenen veriler, konum izni ve hesap silme'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    document: LegalDocument.privacy,
                  ),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Kullanım koşulları'),
              subtitle: const Text('BEN hizmetini kullanırken geçerli kurallar'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LegalInformationScreen(
                    document: LegalDocument.terms,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bu ekrandaki yasal belgeler taslaktır. Resmî politika olarak yayımlanmadan önce işletmeci bilgileri, gerçek hizmet sağlayıcıları ve veri saklama süreleri tamamlanmalıdır.',
            style: TextStyle(fontSize: 12, height: 1.45),
          ),
 Resmî gizlilik politikası, kullanım koşulları, veri saklama süreleri ve destek iletişim bilgileri yayın öncesinde BEN’in gerçek işletmeci bilgileriyle tamamlanmalıdır.',
            style: TextStyle(fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final String body;
  const _PolicyCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(body, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      );
}
