import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../services/auth_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _busy = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _users = []);
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await _api.get('users', query: {'q': query});
      final list = data is List ? data : const [];
      if (!mounted) return;
      setState(() {
        _users = list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _users = []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcıları bul')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final username = '${user['username'] ?? ''}';
                        final initial = username.isEmpty
                            ? '?'
                            : username.substring(0, 1).toUpperCase();
                        final id = int.tryParse('${user['id']}') ?? 0;
                        return ListTile(
                          leading: CircleAvatar(child: Text(initial)),
                          title: Text(
                            '@$username',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('Sv. ${user['xp'] ?? 0} XP'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: id <= 0
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfileScreen(userId: id),
                                    ),
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

class PublicProfileScreen extends StatefulWidget {
  final int userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _user;
  bool _busy = true;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final viewer = AuthService.currentUser?.id ?? 0;
      final data = await _api.get(
        'users/${widget.userId}',
        query: {'viewer_id': '$viewer'},
      );
      if (!mounted) return;
      setState(() {
        _user = Map<String, dynamic>.from(data);
        _following = data['following_me'] == true;
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _follow() async {
    final viewer = AuthService.currentUser?.id ?? 0;
    if (viewer <= 0 || viewer == widget.userId) return;
    try {
      final data = await _api.post(
        'follow',
        body: {
          'follower_id': viewer,
          'following_id': widget.userId,
        },
      );
      if (!mounted) return;
      setState(() => _following = data['following'] == true);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = _user ?? <String, dynamic>{};
    final name = '${user['username'] ?? 'BEN'}';
    final initial = name.isEmpty ? 'B' : name.substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text('@$name')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              child: Text(initial, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '@$name',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat('${user['followers'] ?? 0}', 'Takipçi'),
              _Stat('${user['following'] ?? 0}', 'Takip'),
              _Stat('${user['xp'] ?? 0}', 'XP'),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: AuthService.currentUser?.id == widget.userId ? null : _follow,
            icon: Icon(
              _following ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
            ),
            label: Text(_following ? 'Takip ediliyor' : 'Takip et'),
          ),
          const SizedBox(height: 28),
          const Text(
            'BEN Ağacı',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kullanıcının anıları ve ağacı burada görüntülenecek.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
          ),
        ),
      ],
    );
  }
}
