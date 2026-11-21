import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../services/auth_service.dart';
import '../models/memory.dart';
import '../features/memories/data/php_memory_repository.dart';
import 'memory_fullscreen_viewer.dart';
import '../services/trust_safety_actions.dart';

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
  List<Memory> _memories = [];
  bool _busy = true;
  bool _loadingMemories = true;
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
      List<Memory> memories = [];
      try {
        memories = await PhpMemoryRepository(_api).list(
          userId: widget.userId,
          scope: 'discover',
          limit: 100,
        );
      } catch (_) {
        // Keep the public profile usable even when the memory feed is offline.
      }
      if (!mounted) return;
      setState(() {
        _user = Map<String, dynamic>.from(data);
        _following = data['following_me'] == true;
        _memories = memories.where((memory) => !memory.isExpired).toList();
        _busy = false;
        _loadingMemories = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _loadingMemories = false;
        });
      }
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
      setState(() => _following = data is Map && data['active'] == true);
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
      appBar: AppBar(
        title: Text('@$name'),
        actions: [
          if (AuthService.currentUser?.id != widget.userId)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  TrustSafetyActions.report(
                    context,
                    targetType: 'user',
                    targetId: widget.userId,
                  );
                } else if (value == 'block') {
                  TrustSafetyActions.block(
                    context,
                    userId: widget.userId,
                    username: name,
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Şikâyet et')),
                PopupMenuItem(value: 'block', child: Text('Engelle')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: (user['avatar_url']?.toString().trim().isNotEmpty == true)
                  ? ClipOval(
                      child: Image.network(
                        '${user['avatar_url']}',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          initial,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    )
                  : Text(initial, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '@$name',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ),
          if ('${user['bio'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '${user['bio']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .68),
                ),
              ),
            ),
          ],
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AN • STORY',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${_memories.where((memory) => memory.isStory).length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingMemories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_memories.where((memory) => memory.isStory).isEmpty)
            const _ProfileEmptyTile(text: 'Şu anda aktif bir Story yok.')
          else
            ..._memories
                .where((memory) => memory.isStory)
                .take(12)
                .map((memory) => _PublicMemoryTile(
                      memory: memory,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemoryFullscreenViewer(
                            memory: memory,
                            memories: _memories,
                          ),
                        ),
                      ),
                    )),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BEN AĞACI • KALICI ANILAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${_memories.where((memory) => !memory.isStory).length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingMemories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_memories.where((memory) => !memory.isStory).isEmpty)
            const _ProfileEmptyTile(text: 'Bu kullanıcı henüz kalıcı anı paylaşmadı.')
          else
            ..._memories
                .where((memory) => !memory.isStory)
                .take(30)
                .map((memory) => _PublicMemoryTile(
                      memory: memory,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemoryFullscreenViewer(
                            memory: memory,
                            memories: _memories,
                          ),
                        ),
                      ),
                    )),
        ],
      ),
    );
  }
}

class _PublicMemoryTile extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const _PublicMemoryTile({
    required this.memory,
    required this.onTap,
  });

  IconData get _icon => switch (memory.type) {
        MemoryType.photo => Icons.photo_rounded,
        MemoryType.video => Icons.play_circle_fill_rounded,
        MemoryType.music => Icons.music_note_rounded,
        MemoryType.location => Icons.location_on_rounded,
        MemoryType.text => Icons.notes_rounded,
      };

  Widget _preview(BuildContext context) {
    final url = memory.mediaUrl;
    if (memory.type == MemoryType.photo &&
        url != null &&
        url.contains('/media/')) {
      return Image.network(
        ApiClient().resolveMediaUri(url).toString(),
        headers: ApiClient().authorizationHeaders,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(_icon, size: 26),
      );

  @override
  Widget build(BuildContext context) {
    final title = memory.title?.trim().isNotEmpty == true
        ? memory.title!.trim()
        : memory.type.name.toUpperCase();
    final body = memory.text?.trim().isNotEmpty == true
        ? memory.text!.trim()
        : memory.description?.trim() ?? '';
    final subtitle = body.isNotEmpty
        ? body
        : memory.hasLocation
            ? 'Konumlu anı'
            : 'BEN dünyasından bir iz';
    final date = '${memory.createdAt.day.toString().padLeft(2, '0')}.${memory.createdAt.month.toString().padLeft(2, '0')}.${memory.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _preview(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEmptyTile extends StatelessWidget {
  final String text;
  const _ProfileEmptyTile({required this.text});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.auto_stories_outlined),
        title: Text(text),
      );
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
