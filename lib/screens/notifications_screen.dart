import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = AuthService.currentUser?.id;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final result = await _api.get('notifications', query: {'user_id': '$id'});
      final rows = result is List ? result : <dynamic>[];
      final items = rows
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
      await _api.post('notifications/read', body: {'user_id': id});
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _icon(String type) {
    return switch (type) {
      'like' => Icons.favorite_rounded,
      'comment' => Icons.chat_bubble_rounded,
      'follow' => Icons.person_add_alt_1_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('Henüz bildirimin yok.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = _items[index];
                        final unread = notification['is_read'] == 0 || notification['is_read'] == false;
                        return ListTile(
                          tileColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          leading: CircleAvatar(child: Icon(_icon('${notification['type']}'))),
                          title: Text(
                            '${notification['text'] ?? ''}',
                            style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w600),
                          ),
                          subtitle: Text('${notification['created_at'] ?? ''}'),
                        );
                      },
                    ),
            ),
    );
  }
}
