import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/network/api_client.dart';
import 'live_studio_screen.dart';
import 'live_viewer_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
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
      final lives = result is List
          ? result
          : result is Map && result['lives'] is List
              ? result['lives'] as List
              : const [];
      setState(() {
        _lives = lives;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openStudio() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveStudioScreen()));
    if (mounted) _loadLives();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? BenTokens.night : BenTokens.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLives,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CANLI', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('BEN dünyasında şu anda yaşananlar', style: TextStyle(fontSize: 13))])),
                    FilledButton.icon(onPressed: _openStudio, icon: const Icon(Icons.videocam_rounded), label: const Text('CANLI AÇ'), style: FilledButton.styleFrom(backgroundColor: BenTokens.cyan, foregroundColor: BenTokens.ink)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                sliver: _loading
                    ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
                    : _lives.isEmpty
                        ? SliverToBoxAdapter(child: Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: dark ? BenTokens.panel : Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: BenTokens.cyan.withValues(alpha: .14))), child: const Column(children: [Icon(Icons.radio_rounded, size: 42), SizedBox(height: 12), Text('Şu an canlı yayın yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('İlk canlı yayınını kameranla başlatabilirsin.', textAlign: TextAlign.center)])))
                        : SliverList.builder(
                            itemCount: _lives.length,
                            itemBuilder: (context, index) {
                              final live = _lives[index] is Map ? _lives[index] as Map : const {};
                              final id = int.tryParse('${live['id'] ?? ''}');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  onTap: id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewerScreen(liveId: id))),
                                  leading: Stack(alignment: Alignment.bottomRight, children: [const CircleAvatar(child: Icon(Icons.videocam_rounded)), Container(width: 10, height: 10, decoration: BoxDecoration(color: BenTokens.success, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2)))]),
                                  title: Text(live['title']?.toString() ?? 'CANLI'),
                                  subtitle: Text('${live['username'] ?? 'BEN'} • ${live['viewers'] ?? 0} izleyici'),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
