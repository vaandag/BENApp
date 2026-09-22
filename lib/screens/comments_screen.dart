import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';
import '../services/auth_service.dart';

class _Comment {
  String text;
  String username;
  final int? memoryId;
  DateTime createdAt;
  int likes;
  bool liked;
  _Comment(this.text, {this.memoryId, String? username, DateTime? createdAt, this.likes = 0, this.liked = false})
      : username = username ?? (AuthService.currentUser?.username ?? 'BEN'),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'body': text,
        'username': username,
        'created_at': createdAt.toIso8601String(),
        'likes': likes,
        'liked': liked,
        if (memoryId != null) 'memory_id': memoryId,
      };

  factory _Comment.fromJson(Map<String, dynamic> json) => _Comment(
        '${json['body'] ?? ''}',
        memoryId: int.tryParse('${json['memory_id'] ?? json['memoryId'] ?? ''}'),
        username: '${json['username'] ?? 'BEN'}',
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
        likes: int.tryParse('${json['likes'] ?? 0}') ?? 0,
        liked: json['liked'] == true,
      );
}

class CommentsScreen extends StatefulWidget {
  final String title;
  final int initialCount;
  final int? memoryId;
  final String? memoryKey;

  const CommentsScreen({
    super.key,
    this.title = 'Yorumlar',
    this.initialCount = 0,
    this.memoryId,
    this.memoryKey,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ApiClient _api = ApiClient();
  final List<_Comment> _comments = <_Comment>[];
  int? _editingIndex;
  bool _loading = true;
  bool _sending = false;

  // Comments are isolated by the immutable memory id whenever one exists.
  // Never fall back to a title for a persisted comment collection: titles are
  // not unique and can cause comments from another memory to appear here.
  String get _storeKey => widget.memoryId != null
      ? 'ben_comments_memory_${widget.memoryId}'
      : 'ben_comments_key_${widget.memoryKey ?? widget.title}';
  String get _currentName => AuthService.currentUser?.username.trim().isNotEmpty == true
      ? AuthService.currentUser!.username
      : 'BEN';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final rawComment in decoded.whereType<Map>()) {
            final comment = _Comment.fromJson(Map<String, dynamic>.from(rawComment));
            // Legacy records from older builds did not carry memory_id. Do not
            // import them into a real memory's collection: they are exactly
            // the stale comments that can leak between memories.
            if (widget.memoryId != null && comment.memoryId != widget.memoryId) continue;
            if (comment.text.trim().isEmpty) continue;
            _comments.add(comment);
          }
        }
      } catch (_) {}
    }

    final id = widget.memoryId;
    if (id != null) {
      try {
        final json = await _api.get('memories/$id/comments');
        final rows = json is List
            ? json
            : (json is Map && json['data'] is List ? json['data'] as List : const []);
        for (final rawRow in rows.whereType<Map>()) {
          final row = Map<String, dynamic>.from(rawRow);

          // Some API versions return the memory id on each comment. If it is
          // present, enforce it. This prevents a malformed/aggregated API
          // response from leaking comments belonging to another memory.
          final rawMemoryId = row['memory_id'] ?? row['memoryId'];
          // The comments endpoint must identify the memory. If the backend
          // omits memory_id, reject the row rather than trusting a potentially
          // aggregated response containing comments from other memories.
          if (rawMemoryId == null) continue;
          final rowMemoryId = int.tryParse('$rawMemoryId');
          if (rowMemoryId != widget.memoryId) continue;

          final incoming = _Comment.fromJson(row);
          final exists = _comments.any((c) =>
              c.text.trim() == incoming.text.trim() &&
              c.username.trim() == incoming.username.trim() &&
              c.createdAt == incoming.createdAt);
          if (!exists && incoming.text.trim().isNotEmpty) _comments.add(incoming);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _loading = false);
    await _persistLocal();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storeKey,
      jsonEncode(_comments.map((c) => c.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final editingIndex = _editingIndex;
    final comment = editingIndex == null
        ? _Comment(text, memoryId: widget.memoryId, username: _currentName)
        : _comments[editingIndex];

    setState(() {
      if (editingIndex == null) {
        _comments.add(comment);
      } else {
        comment.text = text;
        comment.username = _currentName;
        comment.createdAt = DateTime.now();
        _editingIndex = null;
      }
      _controller.clear();
      _sending = widget.memoryId != null && editingIndex == null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await _persistLocal();

    // Sunucu erişimi varsa kalıcı API kaydı da oluştur. Yerel kayıt, ağ
    // başarısız olsa bile yorumun uygulamada kaybolmasını engeller.
    if (widget.memoryId != null && editingIndex == null) {
      try {
        await _api.post('comments', body: {
          'memory_id': widget.memoryId,
          'user_id': AuthService.currentUser?.id ?? 1,
          'body': text,
        });
      } catch (_) {
        // Yerel kalıcı kayıt zaten mevcut.
      }
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleCommentLike(int index) async {
    setState(() {
      final c = _comments[index];
      c.liked = !c.liked;
      c.likes = (c.likes + (c.liked ? 1 : -1)).clamp(0, 1 << 30).toInt();
    });
    await _persistLocal();
  }

  void _replyTo(int index) {
    final name = _comments[index].username.trim().isEmpty ? 'BEN' : _comments[index].username.trim();
    setState(() {
      _editingIndex = null;
      _controller.text = '@$name ';
    });
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _edit(int index) {
    setState(() => _editingIndex = index);
    _controller.text = _comments[index].text;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yorumu sil?'),
        content: const Text('Bu yorum bu cihazdaki BEN kayıtlarından silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _comments.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _controller.clear();
      }
    });
    await _persistLocal();
  }

  void _menu(int index) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sil'),
              onTap: () {
                Navigator.pop(sheetContext);
                _delete(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) Navigator.of(context).pop(_comments.length);
  }

  String _time(DateTime value) {
    final d = DateTime.now().difference(value);
    if (d.inMinutes < 1) return 'şimdi';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF061018) : const Color(0xFFF4F8F8),
      appBar: AppBar(
        leading: IconButton(onPressed: _close, icon: const Icon(Icons.arrow_back_rounded)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.title}${_comments.isEmpty ? '' : '  ${_comments.length}'}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text(
              'BEN dünyasından izler',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: scheme.onSurface.withValues(alpha: .48)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _EmptyComments(dark: dark)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        itemCount: _comments.length,
                        itemBuilder: (_, index) => _CommentCard(
                          comment: _comments[index],
                          time: _time(_comments[index].createdAt),
                          dark: dark,
                          currentUser: _currentName,
                          onMenu: () => _menu(index),
                          onLike: () => _toggleCommentLike(index),
                          onReply: () => _replyTo(index),
                        ),
                      ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _commentFocusNode,
            editing: _editingIndex != null,
            sending: _sending,
            onSubmit: _submit,
            onCancelEdit: () => setState(() {
              _editingIndex = null;
              _controller.clear();
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  final bool dark;
  const _EmptyComments({required this.dark});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [BenTokens.cyanBright, BenTokens.cyanDeep]),
                boxShadow: [BoxShadow(color: BenTokens.cyan.withValues(alpha: .18), blurRadius: 30)],
              ),
              child: const Icon(Icons.forum_rounded, color: BenTokens.ink, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Henüz yorum yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('İlk izi sen bırak.', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          ],
        ),
      );
}

class _CommentCard extends StatelessWidget {
  final _Comment comment;
  final String time;
  final bool dark;
  final String currentUser;
  final VoidCallback onMenu;
  final VoidCallback onLike;
  final VoidCallback onReply;
  const _CommentCard({required this.comment, required this.time, required this.dark, required this.currentUser, required this.onMenu, required this.onLike, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final name = comment.username.trim().isEmpty ? 'BEN' : comment.username;
    final initial = name.isEmpty ? 'B' : name.substring(0, 1).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 13, 10, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? const [Color(0xFF142631), Color(0xFF0A151D)] : const [Colors.white, Color(0xFFF1F8F8)],
        ),
        border: Border.all(color: BenTokens.cyan.withValues(alpha: dark ? .24 : .13)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .24 : .07), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [BenTokens.cyanBright, BenTokens.cyanDeep]),
              boxShadow: [BoxShadow(color: BenTokens.cyan.withValues(alpha: .20), blurRadius: 14)],
            ),
            child: Text(initial, style: const TextStyle(color: BenTokens.ink, fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                    const SizedBox(width: 6),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyanBright)),
                    const SizedBox(width: 6),
                    Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .42))),
                  ],
                ),
                const SizedBox(height: 7),
                Text(comment.text, style: const TextStyle(fontSize: 14.5, height: 1.38, fontWeight: FontWeight.w600)),
                const SizedBox(height: 9),
                Row(children: [
                  _TinyAction(icon: comment.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: comment.likes > 0 ? 'Beğen ${comment.likes}' : 'Beğen', active: comment.liked, onTap: onLike),
                  const SizedBox(width: 8),
                  _TinyAction(icon: Icons.reply_rounded, label: 'Yanıtla', onTap: onReply),
                ]),
              ],
            ),
          ),
          IconButton(onPressed: onMenu, icon: const Icon(Icons.more_horiz_rounded)),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _TinyAction({required this.icon, required this.label, this.active = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? BenTokens.cyan.withValues(alpha: .13) : Theme.of(context).colorScheme.onSurface.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: active ? BenTokens.cyanBright : null), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800))]),
    );
    return onTap == null ? child : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(99), child: child);
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final bool sending;
  final VoidCallback onSubmit;
  final VoidCallback onCancelEdit;
  const _Composer({required this.controller, required this.focusNode, required this.editing, required this.sending, required this.onSubmit, required this.onCancelEdit});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xEE09151D) : const Color(0xF4FFFFFF),
          border: Border(top: BorderSide(color: BenTokens.cyan.withValues(alpha: .12))),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 24, offset: const Offset(0, -8))],
        ),
        child: Column(children: [
          if (editing) Row(children: [const Icon(Icons.edit_rounded, size: 14, color: BenTokens.cyanBright), const SizedBox(width: 6), const Expanded(child: Text('Yorum düzenleniyor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), TextButton(onPressed: onCancelEdit, child: const Text('İptal'))]),
          Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Yorumunu bırak...',
                  filled: true,
                  fillColor: dark ? const Color(0xFF101F28) : const Color(0xFFF1F5F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [BenTokens.cyanBright, BenTokens.cyanDeep]), boxShadow: [BoxShadow(color: BenTokens.cyan.withValues(alpha: .22), blurRadius: 16)]),
                child: IconButton(onPressed: sending ? null : onSubmit, icon: sending ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: BenTokens.ink)) : const Icon(Icons.arrow_upward_rounded, color: BenTokens.ink)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
