import 'dart:async';

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
  bool _refreshing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_refreshing) _load();
    });
  }

  Future<void> _load() async {
    if (_refreshing) return;

    final id = AuthService.currentUser?.id;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _refreshing = true;
    try {
      final result = await _api.get(
        'notifications',
        query: {'user_id': '$id'},
      );
      final rows = result is List ? result : <dynamic>[];
      final items = rows
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });

      await _api.post('notifications/read', body: {'user_id': id});
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((item) => {...item, 'is_read': 1})
            .toList();
      });
    } catch (_) {
      // Keep the last successful notification list during temporary outages.
      if (mounted) setState(() => _loading = false);
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  IconData _icon(String type) {
    return switch (type) {
      'like' => Icons.favorite_rounded,
      'comment' => Icons.chat_bubble_rounded,
      'follow' => Icons.person_add_alt_1_rounded,
      'announcement' => Icons.campaign_rounded,
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
                        final readValue = notification['is_read'];
                        final unread = readValue == 0 || readValue == '0' || readValue == false;
                        final textValue = '${notification['text'] ?? ''}';
                        final isAnnouncement =
                            notification['type'] == 'announcement';
                        final parts = textValue.split('\\n');
                        final title = isAnnouncement ? parts.first : textValue;
                        final body = isAnnouncement && parts.length > 1
                            ? parts.skip(1).join('\\n')
                            : null;
                        return ListTile(
                          tileColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          leading: CircleAvatar(
                            child: Icon(_icon('${notification['type']}')),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (body != null) ...[
                                const SizedBox(height: 4),
                                Text(body),
                              ],
                              const SizedBox(height: 4),
                              Text('${notification['created_at'] ?? ''}'),
                            ],
                          ),
                        );
                    ),
            ),
    );
  }
}
