import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';
import '../core/network/api_client.dart';
import '../services/auth_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ApiClient _api = ApiClient();
  bool _starting = false;
  List<dynamic> _lives = const [];

  @override
  void initState() {
    super.initState();
    _loadLives();
  }

  Future<void> _loadLives() async {
    try {
      final result = await _api.get('live');
      if (!mounted) return;
      setState(() => _lives = result is Map && result['lives'] is List ? result['lives'] as List : const []);
    } catch (_) {}
  }

  Future<void> _startLive() async {
    setState(() => _starting = true);
    try {
      await _api.post('live', body: {'title': 'BEN CANLI', 'status': 'live', 'user_id': AuthService.currentUser?.id ?? 1});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CANLI yayın başlatma altyapısı hazır.')));
      await _loadLives();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CANLI şu an sunucuya bağlanamadı.')));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? BenTokens.night : BenTokens.paper,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CANLI', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Şu anda yaşanan BEN anları', style: TextStyle(fontSize: 13)),
                  ])),
                  FilledButton.icon(
                    onPressed: _starting ? null : _startLive,
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text(_starting ? 'Açılıyor' : 'CANLI AÇ'),
                    style: FilledButton.styleFrom(backgroundColor: BenTokens.cyan, foregroundColor: BenTokens.ink),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              sliver: _lives.isEmpty
                  ? SliverToBoxAdapter(child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: dark ? BenTokens.panel : Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: BenTokens.cyan.withValues(alpha: .14))),
                      child: const Column(children: [Icon(Icons.radio_rounded, size: 42), SizedBox(height: 12), Text('Şu an canlı yayın yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('İlk CANLI yayınını sen başlatabilirsin.', textAlign: TextAlign.center)]),
                    ))
                  : SliverList.builder(
                      itemCount: _lives.length,
                      itemBuilder: (context, index) {
                        final live = _lives[index] is Map ? _lives[index] as Map : const {};
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.videocam_rounded)),
                            title: Text(live['title']?.toString() ?? 'CANLI'),
                            subtitle: Text('${live['viewers'] ?? 0} izleyici'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
