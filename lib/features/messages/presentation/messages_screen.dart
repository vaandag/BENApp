import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../models/memory.dart';
import '../../../services/auth_service.dart';

class MessagesScreen extends StatefulWidget {
  final Memory? memoryToShare;

  const MessagesScreen({
    super.key,
    this.memoryToShare,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _Chat {
  final int id;
  final String name, avatarUrl, preview, time;
  final int unread;

  const _Chat(
    this.id,
    this.name,
    this.avatarUrl,
    this.preview,
    this.time,
    this.unread,
  );

  String get initials => name.trim().isEmpty
      ? 'B'
      : name
          .trim()
          .split(RegExp(r'\s+'))
          .map((e) => e[0])
          .take(2)
          .join()
          .toUpperCase();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _api = ApiClient();

  List<_Chat> _chats = [];
  List<_Chat> _people = [];

  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.id;

    if (uid == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final raw = await _api.get(
        'messages/conversations',
        query: {
          'user_id': '$uid',
        },
      );

      final list = raw is List ? raw : const <dynamic>[];

      final chats = list
          .whereType<Map>()
          .map(
            (m) => _Chat(
              int.tryParse('${m['id']}') ?? 0,
              '${m['username'] ?? 'BEN kullanıcısı'}',
              '${m['avatar_url'] ?? ''}',
              '${m['preview'] ?? ''}',
              _time('${m['created_at'] ?? ''}'),
              m['is_read'] == 0 &&
                      int.tryParse('${m['sender_id'] ?? 0}') != uid
                  ? 1
                  : 0,
            ),
          )
          .where((c) => c.id > 0)
          .toList();

      if (mounted) {
        setState(() => _chats = chats);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchPeople(String v) async {
    setState(() => _query = v);

    if (v.trim().isEmpty) {
      setState(() => _people = []);
      return;
    }

    try {
      final raw = await _api.get(
        'users',
        query: {
          'q': v.trim(),
        },
      );

      final uid = AuthService.currentUser?.id;
      final list = raw is List ? raw : const <dynamic>[];

      final people = list
          .whereType<Map>()
          .map(
            (m) => _Chat(
              int.tryParse('${m['id']}') ?? 0,
              '${m['username'] ?? ''}',
              '${m['avatar_url'] ?? ''}',
              '',
              '',
              0,
            ),
          )
          .where((c) => c.id > 0 && c.id != uid)
          .toList();

      if (mounted) {
        setState(() => _people = people);
      }
    } catch (_) {}
  }

  String _time(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();

    if (d == null) {
      return '';
    }

    final n = DateTime.now();

    return d.year == n.year &&
            d.month == n.month &&
            d.day == n.day
        ? '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'
        : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _query.isEmpty ? _chats : _people;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yeni konuşma',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _RoundAction(
                    onTap: () => _searchFocus.requestFocus(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: _searchPeople,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Kişi ara...',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {
                              _query = '';
                              _people = [];
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'Henüz bir konuşman yok.'
                      : 'Kişi bulunamadı.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
              sliver: SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _ChatTile(
                  chat: list[i],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ChatScreen(
                          chat: list[i],
                          sharedText: widget.memoryToShare == null
                              ? null
                              : _shareText(widget.memoryToShare!),
                        ),
                      ),
                    );

                    _load();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shareText(Memory m) {
    return 'BEN anısı: ${m.title ?? m.text ?? 'Bir anı'}';
  }
}

class _RoundAction extends StatelessWidget {
  final VoidCallback onTap;

  const _RoundAction({
    required this.onTap,
  });

  @override
  Widget build(BuildContext c) {
    return Material(
      color: Theme.of(c).colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.edit_rounded,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext c) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      leading: _Avatar(chat: chat),
      title: Text(
        chat.name,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        chat.preview.isEmpty ? 'Yeni konuşma' : chat.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.time.isNotEmpty)
            Text(
              chat.time,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(c)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .45),
              ),
            ),
          if (chat.unread > 0)
            const Text(
              '●',
              style: TextStyle(
                color: Color(0xFFFFD200),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _Chat chat;
  final double size;

  const _Avatar({
    required this.chat,
    this.size = 52,
  });

  @override
  Widget build(BuildContext c) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD200),
            Color(0xFFFF8A00),
          ],
        ),
      ),
      child: chat.avatarUrl.startsWith('http')
          ? Image.network(
              chat.avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _i(),
            )
          : _i(),
    );
  }

  Widget _i() {
    return Container(
      color: const Color(0xFF1A2435),
      alignment: Alignment.center,
      child: Text(
        chat.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Message {
  final int id;
  String text;
  final bool mine;
  bool read;

  _Message(
    this.id,
    this.text, {
    required this.mine,
    this.read = false,
  });
}

class _ChatScreen extends StatefulWidget {
  final _Chat chat;
  final String? sharedText;

  const _ChatScreen({
    required this.chat,
    this.sharedText,
  });

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _controller = TextEditingController();
  final _api = ApiClient();

  List<_Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.id;

    if (uid == null) {
      return;
    }

    try {
      final raw = await _api.get(
        'messages',
        query: {
          'user_id': '$uid',
          'with_user_id': '${widget.chat.id}',
        },
      );

      final list = raw is List ? raw : const <dynamic>[];

      final loaded = list
          .whereType<Map>()
          .map((m) {
            final sender =
                int.tryParse('${m['sender_id']}') ?? 0;

            return _Message(
              int.tryParse('${m['id']}') ?? 0,
              '${m['body'] ?? ''}',
              mine: sender == uid,
              read: m['is_read'] == 1,
            );
          })
          .where((m) => m.text.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() => _messages = loaded);
      }

      await _api.post(
        'messages/read',
        body: {
          'user_id': uid,
          'with_user_id': widget.chat.id,
        },
      );
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }

    if (widget.sharedText != null &&
        widget.sharedText!.isNotEmpty &&
        mounted) {
      _controller.text = widget.sharedText!;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = AuthService.currentUser?.id;

    if (text.isEmpty || uid == null || _sending) {
      return;
    }

    setState(() => _sending = true);

    try {
      final r = await _api.post(
        'messages',
        body: {
          'sender_id': uid,
          'receiver_id': widget.chat.id,
          'body': text,
        },
      );

      final id = r is Map
          ? int.tryParse('${r['id']}') ?? 0
          : 0;

      if (mounted) {
        setState(() {
          _messages.add(
            _Message(
              id,
              text,
              mine: true,
            ),
          );
        });

        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                    'ApiException: ',
                    '',
                  ),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _sending = false);
    }
  }

  Future<void> _edit(int i) async {
    final m = _messages[i];
    final c = TextEditingController(text: m.text);

    await showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: const Text('Mesajı düzenle'),
        content: TextField(
          controller: c,
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(x),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              final t = c.text.trim();

              if (t.isEmpty) {
                return;
              }

              try {
                await _api.post(
                  'messages/${m.id}/edit',
                  body: {
                    'user_id':
                        AuthService.currentUser?.id ?? 0,
                    'body': t,
                  },
                );

                if (mounted) {
                  setState(() => m.text = t);
                }

                if (x.mounted) {
                  Navigator.pop(x);
                }
              } catch (_) {}
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    c.dispose();
  }

  Future<void> _delete(int i) async {
    final m = _messages[i];

    try {
      await _api.delete('messages/${m.id}');

      if (mounted) {
        setState(() => _messages.removeAt(i));
      }
    } catch (_) {}
  }

  void _menu(int i) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(c);
                _edit(i);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: const Text('Sil'),
              onTap: () {
                Navigator.pop(c);
                _delete(i);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _Avatar(
              chat: widget.chat,
              size: 38,
            ),
            const SizedBox(width: 10),
            Text(
              widget.chat.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];

                      return GestureDetector(
                        onLongPress:
                            m.mine ? () => _menu(i) : null,
                        child: Align(
                          alignment: m.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? const Color(0xFFFFD200)
                                  : Theme.of(c)
                                      .colorScheme
                                      .surface,
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: m.mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                    color: m.mine
                                        ? const Color(
                                            0xFF101217,
                                          )
                                        : null,
                                  ),
                                ),
                                if (m.mine)
                                  Text(
                                    m.read
                                        ? 'Okundu ✓✓'
                                        : 'Gönderildi ✓',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(
                                        0xFF101217,
                                      ).withValues(alpha: .65),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                6,
                12,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _sending ? null : _send,
                    child: const Icon(
                      Icons.send_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}