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
