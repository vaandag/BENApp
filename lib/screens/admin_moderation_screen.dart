import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final ApiClient _api = ApiClient();
  String _status = 'open';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = [];
  bool _sendingAnnouncement = false;

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
      final raw = await _api.get('admin/reports', query: {'status': _status});
      final rows = raw is List ? raw : const [];
      if (!mounted) return;
      setState(() {
        _reports = rows.whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _reports = [];
      });
    }
  }

  Future<void> _composeAnnouncement() async {
    final draft = await showDialog<_AnnouncementDraft>(
      context: context,
      builder: (_) => _AdminAnnouncementComposer(api: _api),
    );
    if (draft == null || !mounted) return;

    final audienceLabel = draft.audience == 'all'
        ? 'Tüm kullanıcılar'
        : '@${draft.recipient?['username'] ?? 'seçilen kullanıcı'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duyuruyu onayla'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alıcı: $audienceLabel',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(draft.title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(draft.body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Düzenle'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingAnnouncement = true);
    try {
      final result = await _api.post('admin/notifications', body: {
        'audience': draft.audience,
        if (draft.audience == 'user') 'user_id': draft.recipient?['id'],
        'title': draft.title,
        'body': draft.body,
      });
      final sent = int.tryParse('${result['recipient_count'] ?? 0}') ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duyuru $sent kullanıcıya gönderildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duyuru gönderilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _sendingAnnouncement = false);
    }
  }

  Future<void> _composeAnnouncement() async {
    final draft = await showDialog<_AnnouncementDraft>(
      context: context,
      builder: (_) => _AdminAnnouncementComposer(api: _api),
    );
    if (draft == null || !mounted) return;

    final audienceLabel = draft.audience == 'all'
        ? 'Tüm kullanıcılar'
        : '@${draft.recipient?['username'] ?? 'seçilen kullanıcı'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duyuruyu onayla'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alıcı: $audienceLabel',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(draft.title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(draft.body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Düzenle'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingAnnouncement = true);
    try {
      final result = await _api.post('admin/notifications', body: {
        'audience': draft.audience,
        if (draft.audience == 'user') 'user_id': draft.recipient?['id'],
        'title': draft.title,
        'body': draft.body,
      });
      final sent = int.tryParse('${result['recipient_count'] ?? 0}') ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duyuru $sent kullanıcıya gönderildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duyuru gönderilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _sendingAnnouncement = false);
    }
  }

  Future<void> _resolve(int id, String status) async {
    try {
      await _api.post('admin/reports/$id/resolve', body: {'status': status});
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şikâyet güncellenemedi: $error')),
      );
    }
  }

  String _targetLabel(Map<String, dynamic> report) {
    final type = '${report['target_type'] ?? ''}';
    final id = '${report['target_id'] ?? ''}';
    final label = switch (type) {
      'user' => 'Kullanıcı',
      'memory' => 'Anı',
      'comment' => 'Yorum',
      'live' => 'Canlı yayın',
      _ => 'İçerik',
    };
    return '$label #$id';
  }

  String _reasonLabel(String reason) => switch (reason) {
        'spam' => 'Spam',
        'harassment' => 'Taciz / zorbalık',
        'hate' => 'Nefret söylemi',
        'nudity' => 'Çıplaklık / cinsel içerik',
        'violence' => 'Şiddet',
        'self_harm' => 'Kendine zarar verme',
        'false_information' => 'Yanlış bilgi',
        'copyright' => 'Telif hakkı',
        _ => 'Diğer',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikâyet yönetimi',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Duyuru gönder',
            onPressed: _sendingAnnouncement ? null : _composeAnnouncement,
            icon: const Icon(Icons.campaign_outlined),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Açık')),
                ButtonSegment(value: 'resolved', label: Text('Çözüldü')),
                ButtonSegment(value: 'rejected', label: Text('Reddedildi')),
              ],
              selected: {_status},
              onSelectionChanged: (values) {
                setState(() => _status = values.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 36),
                              const SizedBox(height: 10),
                              const Text(
                                'Şikâyet kayıtları yüklenemedi.',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
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
                    : _reports.isEmpty
                        ? Center(
                            child: Text(
                              _status == 'open'
                                  ? 'Bekleyen şikâyet yok.'
                                  : 'Bu bölümde kayıt yok.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final report = _reports[index];
                                final id = int.tryParse('${report['id']}') ?? 0;
                                final reporter =
                                    '${report['reporter_username'] ?? 'Silinmiş kullanıcı'}';
                                final reason = _reasonLabel(
                                    '${report['reason'] ?? 'other'}');
                                final details =
                                    '${report['details'] ?? ''}'.trim();
                                final targetAuthor =
                                    '${report['target_author_username'] ?? ''}'.trim();
                                final targetPreview =
                                    '${report['target_preview'] ?? ''}'.trim();
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _targetLabel(report),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Text('#$id'),
                                          ],
                                        ),
                                        const SizedBox(height: 7),
                                        Text('Bildiren: @$reporter'),
                                        if (targetAuthor.isNotEmpty)
                                          Text('İçerik sahibi: @$targetAuthor'),
                                        Text('Neden: $reason'),
                                        if (targetPreview.isNotEmpty) ...[
                                          const SizedBox(height: 9),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(11),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: .45),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              targetPreview,
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                        if (details.isNotEmpty) ...[
                                          const SizedBox(height: 7),
                                          Text(details),
                                        ],
                                        if (report['created_at'] != null) ...[
                                          const SizedBox(height: 7),
                                          Text(
                                            '${report['created_at']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                        if (_status == 'open') ...[
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              FilledButton.icon(
                                                onPressed: id > 0
                                                    ? () => _resolve(id, 'resolved')
                                                    : null,
                                                icon: const Icon(Icons.check_rounded),
                                                label: const Text('Çözüldü'),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: id > 0
                                                    ? () => _resolve(id, 'rejected')
                                                    : null,
                                                icon: const Icon(Icons.close_rounded),
                                                label: const Text('Reddet'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}


class _AnnouncementDraft {
  final String audience;
  final String title;
  final String body;
  final Map<String, dynamic>? recipient;

  const _AnnouncementDraft({
    required this.audience,
    required this.title,
    required this.body,
    this.recipient,
  });
}

class _AdminAnnouncementComposer extends StatefulWidget {
  const _AdminAnnouncementComposer({required this.api});

  final ApiClient api;

  @override
  State<_AdminAnnouncementComposer> createState() =>
      _AdminAnnouncementComposerState();
}

class _AdminAnnouncementComposerState
    extends State<_AdminAnnouncementComposer> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all';
  Map<String, dynamic>? _recipient;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _chooseRecipient() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AdminUserPickerDialog(api: widget.api),
    );
    if (selected != null && mounted) {
      setState(() => _recipient = selected);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve mesaj alanlarını doldur.')),
      );
      return;
    }
    if (_audience == 'user' && _recipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir kullanıcı seç.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _AnnouncementDraft(
        audience: _audience,
        title: title,
        body: body,
        recipient: _recipient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni BEN duyurusu'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alıcılar',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'all',
                    icon: Icon(Icons.campaign_outlined),
                    label: Text('Herkes'),
                  ),
                  ButtonSegment(
                    value: 'user',
                    icon: Icon(Icons.person_outline_rounded),
                    label: Text('Tek kişi'),
                  ),
                ],
                selected: {_audience},
                onSelectionChanged: (values) => setState(() {
                  _audience = values.first;
                  if (_audience == 'all') _recipient = null;
                }),
              ),
              if (_audience == 'user') ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _chooseRecipient,
                  icon: const Icon(Icons.person_search_rounded),
                  label: Text(_recipient == null
                      ? 'Kullanıcı seç'
                      : '@${_recipient!['username']}  ·  #${_recipient!['id']}'),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Duyuru başlığı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bodyController,
                minLines: 3,
                maxLines: 6,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Duyuru mesajı',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const Text(
                'Göndermeden önce alıcı ve mesaj önizlemesi gösterilir.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Önizle'),
        ),
      ],
    );
  }
}

class _AdminUserPickerDialog extends StatefulWidget {
  const _AdminUserPickerDialog({required this.api});

  final ApiClient api;

  @override
  State<_AdminUserPickerDialog> createState() => _AdminUserPickerDialogState();
}

class _AdminUserPickerDialogState extends State<_AdminUserPickerDialog> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String? _error;
  int _requestVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _users = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final version = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.api.get('admin/users', query: {'q': query});
      final rows = raw is List ? raw : const [];
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _users = rows.whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _error = error.toString();
        _users = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kullanıcı seç'),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Kullanıcı adında ara (en az 2 harf)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, textAlign: TextAlign.center))
                      : _users.isEmpty
                          ? const Center(
                              child: Text('Eşleşen kullanıcı yok.'),
                            )
                          : ListView.separated(
                              itemCount: _users.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return ListTile(
                                  dense: true,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline_rounded),
                                  ),
                                  title: Text('@${user['username']}'),
                                  subtitle: Text('Kullanıcı #${user['id']}'),
                                  onTap: () => Navigator.pop(context, user),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
