import 'package:flutter/material.dart';

import '../core/network/api_client.dart';

class AdminAnnouncementHistoryScreen extends StatefulWidget {
  const AdminAnnouncementHistoryScreen({super.key});

  @override
  State<AdminAnnouncementHistoryScreen> createState() =>
      _AdminAnnouncementHistoryScreenState();
}

class _AdminAnnouncementHistoryScreenState
    extends State<AdminAnnouncementHistoryScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
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
      final result = await _api.get(
        'admin/notifications',
        query: const {'limit': '50'},
      );
      final rows = result is List ? result : const [];
      if (!mounted) return;
      setState(() {
        _items = rows.whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
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

  String _audience(Map<String, dynamic> item) {
    if (item['audience'] == 'all') {
      return 'Tüm kullanıcılar · ${item['recipient_count'] ?? 0} alıcı';
    }
    final username = '${item['target_username'] ?? ''}'.trim();
    final targetId = '${item['target_user_id'] ?? ''}';
    if (username.isNotEmpty) return '@$username';
    return 'Kullanıcı #$targetId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Duyuru geçmişi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 38),
                        const SizedBox(height: 10),
                        const Text('Duyuru geçmişi yüklenemedi.'),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 170),
                            Center(child: Text('Henüz gönderilmiş duyuru yok.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final count = int.tryParse(
                                  '${item['recipient_count'] ?? 0}',
                                ) ??
                                0;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.campaign_rounded,
                                          color: Color(0xFF35D5C2),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            '${item['title'] ?? 'BEN duyurusu'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text('#${item['id'] ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('${item['body'] ?? ''}'),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          avatar: const Icon(
                                            Icons.people_alt_outlined,
                                            size: 16,
                                          ),
                                          label: Text(_audience(item)),
                                        ),
                                        Chip(
                                          avatar: const Icon(
                                            Icons.send_rounded,
                                            size: 15,
                                          ),
                                          label: Text('$count gönderim'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Gönderen: @${item['admin_username'] ?? 'yönetici'}'
                                      '  ·  ${item['created_at'] ?? ''}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
