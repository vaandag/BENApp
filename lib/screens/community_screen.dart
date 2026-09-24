import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  final _location = LocationService();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _message = TextEditingController();
  String? _roomId;
  String _regionName = 'Bölgen hazırlanıyor…';
  List<dynamic> _messages = const [];
  Map<String, dynamic> _rank = const {};
  bool _busy = true;

  @override void initState() { super.initState(); _prepare(); }
  @override void dispose() { _tabs.dispose(); _message.dispose(); super.dispose(); }

  Future<void> _prepare() async {
    try {
      final r = await _location.getCurrent(context, showFeedback: false);
      if (r.snapshot != null) {
        final rooms = await _api.get('regional/rooms', query: {'lat': '${r.snapshot!.latLng.latitude}', 'lng': '${r.snapshot!.latLng.longitude}'});
        if (rooms is Map) { _roomId = rooms['room_id']?.toString(); _regionName = rooms['region']?.toString() ?? 'Bölgesel sohbet'; }
        if (_roomId != null) await _loadMessages();
      } else { _regionName = 'Konum olmadan bölgesel oda belirlenemiyor'; }
      final rank = await _api.get('rank', query: {'user_id': '${AuthService.currentUser?.id ?? 1}'});
      if (rank is Map) _rank = Map<String,dynamic>.from(rank);
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;
    try { final r = await _api.get('regional/messages', query: {'room_id': _roomId!}); if (mounted && r is List) setState(() => _messages = r); } catch (_) {}
  }

  Future<void> _send() async {
    final body = _message.text.trim(); if (body.isEmpty || _roomId == null) return;
    _message.clear();
    try { await _api.post('regional/messages', body: {'room_id': _roomId, 'user_id': AuthService.currentUser?.id ?? 1, 'body': body}); await _loadMessages(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', '')))); }
  }

  @override Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? BenTokens.night : BenTokens.paper,
      appBar: AppBar(title: const Text('BEN Topluluk', style: TextStyle(fontWeight: FontWeight.w900)), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Bölgesel Sohbet'), Tab(text: 'Rank & Rozetler')])),
      body: TabBarView(controller: _tabs, children: [_chat(), _rankPage()]),
    );
  }

  Widget _chat() {
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: BenTokens.cyan.withValues(alpha: .07),
          border: Border.all(color: BenTokens.cyan.withValues(alpha: .15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_city_rounded, color: BenTokens.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Otomatik bölgesel oda', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text(_regionName, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.public_rounded, color: BenTokens.cyan),
          ],
        ),
      ),
      Expanded(child: _busy ? const Center(child: CircularProgressIndicator()) : _roomId == null ? const Center(child: Text('Bölgesel oda için konum gerekli.')) : ListView.builder(reverse: true, padding: const EdgeInsets.fromLTRB(14, 4, 14, 12), itemCount: _messages.length, itemBuilder: (_, i) { final m = _messages[_messages.length - 1 - i] is Map ? _messages[_messages.length - 1 - i] as Map : const {}; return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).colorScheme.surface), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('@${m['username'] ?? 'BEN'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: BenTokens.cyan)), const SizedBox(height: 3), Text(m['body']?.toString() ?? '')])); })),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 12), child: Row(children: [Expanded(child: TextField(controller: _message, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Bölgenle paylaş…'))), const SizedBox(width: 8), IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded))]))),
    ]);
  }

  Widget _rankPage() {
    final level = (_rank['level'] ?? 1).toString(); final xp = (_rank['xp'] ?? 0).toString(); final next = (_rank['next_xp'] ?? 500).toString();
    final badges = (_rank['badges'] is List) ? _rank['badges'] as List : const [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFF0E2732), Color(0xFF101822)]), border: Border.all(color: BenTokens.cyan.withValues(alpha: .18))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SEVİYE $level', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: BenTokens.cyan)), const SizedBox(height: 6), Text('$xp XP / sonraki seviye $next XP', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 14), LinearProgressIndicator(value: (_rank['progress'] as num?)?.toDouble() ?? 0, minHeight: 8)]),
      ), const SizedBox(height: 18), const Text('Rozetler', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
      ...badges.map((b) { final m = b is Map ? b : const {}; return Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.workspace_premium_rounded)), title: Text(m['name']?.toString() ?? 'Rozet', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(m['description']?.toString() ?? 'Gerçek kullanım kriteri'))); }),
    ]);
  }
}
