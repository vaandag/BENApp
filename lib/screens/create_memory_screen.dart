import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_tokens.dart';
import '../models/memory.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';

class CreateMemoryScreen extends StatefulWidget {
  final MemoryActionType initialType;
  const CreateMemoryScreen({super.key, this.initialType = MemoryActionType.text});

  @override
  State<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

enum MemoryActionType { text, photo, video, location }

class _CreateMemoryScreenState extends State<CreateMemoryScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _media = MediaService();
  final _location = LocationService();
  late MemoryActionType _type;
  File? _file;
  LatLng? _latLng;
  String _privacy = 'Herkese açık';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool video}) async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 18),
            Text(video ? 'Video ekle' : 'Fotoğraf ekle', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Kamera'), onTap: () => Navigator.pop(sheet, false)),
            ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Galeriden seç'), onTap: () => Navigator.pop(sheet, true)),
          ]),
        ),
      ),
    );
    if (source == null) return;
    final file = video
        ? (source ? await _media.pickVideoFromGallery() : await _media.recordVideo())
        : (source ? await _media.pickPhotoFromGallery() : await _media.takePhoto());
    if (!mounted || file == null) return;
    setState(() => _file = file);
  }

  Future<void> _addLocation() async {
    final value = await _location.getCurrentLatLng(context);
    if (!mounted || value == null) return;
    setState(() => _latLng = value);
  }

  Future<void> _publish() async {
    if (_type == MemoryActionType.text && _body.text.trim().isEmpty) {
      _snack('Anını yazmadan yayınlayamazsın.');
      return;
    }
    if ((_type == MemoryActionType.photo || _type == MemoryActionType.video) && _file == null) {
      _snack('Önce bir medya seç.');
      return;
    }
    final choice = await _showPublishTypeChooser();
    if (!mounted || choice == null) return;
    setState(() => _busy = true);
    final title = _title.text.trim().isEmpty ? null : _title.text.trim();
    final description = _body.text.trim().isEmpty ? null : _body.text.trim();
    final isStory = choice == 'story';
    final expiresAt = isStory ? DateTime.now().add(const Duration(hours: 24)) : null;
    final privacy = _privacy == 'Takipçiler' ? 'followers' : _privacy == 'Sadece BEN' ? 'private' : 'public';
    final memory = switch (_type) {
      MemoryActionType.text => Memory.text(text: _body.text.trim(), location: _latLng, title: title, description: description, privacy: privacy, postType: choice, expiresAt: expiresAt),
      MemoryActionType.photo => Memory.photo(photo: _file!, location: _latLng, title: title, description: description, privacy: privacy, postType: choice, expiresAt: expiresAt),
      MemoryActionType.video => Memory.video(video: _file!, location: _latLng, title: title, description: description, privacy: privacy, postType: choice, expiresAt: expiresAt),
      MemoryActionType.location => Memory.location(latitude: _latLng?.latitude ?? 0, longitude: _latLng?.longitude ?? 0, title: title, description: description, privacy: privacy, postType: choice, expiresAt: expiresAt),
    };
    if (!mounted) return;
    Navigator.pop(context, memory);
  }

  Future<String?> _showPublishTypeChooser() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) {
        final dark = Theme.of(sheet).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF101A27) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: BenTokens.cyan.withValues(alpha: .16)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 18),
              const Text('Bunu nasıl paylaşmak istersin?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Paylaşmadan önce seçebilirsin.', style: TextStyle(color: Theme.of(sheet).colorScheme.onSurface.withValues(alpha: .62))),
              const SizedBox(height: 18),
              _publishChoice(
                sheet,
                icon: Icons.auto_stories_rounded,
                title: 'Story',
                subtitle: '24 saat görünür, sonra otomatik kaybolur.',
                chip: '24 SAAT',
                value: 'story',
              ),
              const SizedBox(height: 10),
              _publishChoice(
                sheet,
                icon: Icons.bookmark_rounded,
                title: 'Kalıcı Anı',
                subtitle: 'Profilinde ve konumunda kalır.',
                chip: 'KALICI',
                value: 'memory',
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _publishChoice(BuildContext sheet, {required IconData icon, required String title, required String subtitle, required String chip, required String value}) {
    final scheme = Theme.of(sheet).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pop(sheet, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BenTokens.cyan.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: BenTokens.cyan.withValues(alpha: .16)),
        ),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .12)), child: Icon(icon, color: BenTokens.cyan)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: BenTokens.gold.withValues(alpha: .16), borderRadius: BorderRadius.circular(99)), child: Text(chip, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: BenTokens.gold))) ]),
            const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: .66))),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ]),
      ),
    );
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? BenTokens.night : BenTokens.paper,
      appBar: AppBar(
        title: const Text('Yeni Paylaşım', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 10), child: FilledButton(onPressed: _busy ? null : _publish, child: const Text('Yayınla'))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          _typeSelector(),
          const SizedBox(height: 16),
          if (_type == MemoryActionType.photo || _type == MemoryActionType.video) _mediaPreview(),
          if (_type == MemoryActionType.photo || _type == MemoryActionType.video) const SizedBox(height: 14),
          TextField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Başlık', hintText: 'Bu ana bir isim ver')),
          const SizedBox(height: 12),
          TextField(controller: _body, minLines: 5, maxLines: 10, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: _type == MemoryActionType.location ? 'Not' : 'Anlat', hintText: 'Bu an hakkında ne söylemek istersin?')),
          const SizedBox(height: 16),
          _optionTile(Icons.location_on_rounded, 'Konum', _latLng == null ? 'Konum ekle' : '${_latLng!.latitude.toStringAsFixed(4)}, ${_latLng!.longitude.toStringAsFixed(4)}', _addLocation),
          const SizedBox(height: 10),
          _optionTile(Icons.lock_outline_rounded, 'Gizlilik', _privacy, _privacyPicker),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BenTokens.cyan.withValues(alpha: .08), borderRadius: BorderRadius.circular(20), border: Border.all(color: BenTokens.cyan.withValues(alpha: .22))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_rounded, color: BenTokens.cyan), SizedBox(width: 12), Expanded(child: Text('Yayınlamadan önce Story veya Kalıcı Anı seçersin. Story 24 saat yaşar; Kalıcı Anı profilinde ve konumunda kalır.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.35)))]),
          ),
        ],
      ),
    );
  }

  Widget _typeSelector() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
    _typeChip(MemoryActionType.text, Icons.edit_rounded, 'Yazı'),
    _typeChip(MemoryActionType.photo, Icons.photo_camera_rounded, 'Fotoğraf'),
    _typeChip(MemoryActionType.video, Icons.videocam_rounded, 'Video'),
    _typeChip(MemoryActionType.location, Icons.place_rounded, 'Konum'),
  ]));

  Widget _typeChip(MemoryActionType type, IconData icon, String label) {
    final active = _type == type;
    return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), avatar: Icon(icon, size: 18), selected: active, onSelected: (_) async {
      setState(() => _type = type);
      if (type == MemoryActionType.photo || type == MemoryActionType.video) await _pickMedia(video: type == MemoryActionType.video);
      if (type == MemoryActionType.location && _latLng == null) await _addLocation();
    }));
  }

  Widget _mediaPreview() {
    if (_file == null) return OutlinedButton.icon(onPressed: () => _pickMedia(video: _type == MemoryActionType.video), icon: Icon(_type == MemoryActionType.video ? Icons.video_library_rounded : Icons.photo_library_rounded), label: Text(_type == MemoryActionType.video ? 'Video seç' : 'Fotoğraf seç'));
    return ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
      if (_type == MemoryActionType.photo) Image.file(_file!, height: 250, width: double.infinity, fit: BoxFit.cover) else Container(height: 250, width: double.infinity, color: BenTokens.ink, child: const Center(child: Icon(Icons.play_circle_fill_rounded, size: 72, color: BenTokens.cyan))),
      Positioned(right: 12, top: 12, child: IconButton.filled(onPressed: () => _pickMedia(video: _type == MemoryActionType.video), icon: const Icon(Icons.refresh_rounded))),
    ]));
  }

  Widget _optionTile(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), tileColor: Theme.of(context).colorScheme.surface.withValues(alpha: .8), leading: CircleAvatar(backgroundColor: BenTokens.cyan.withValues(alpha: .12), child: Icon(icon, color: BenTokens.cyan)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap);

  Future<void> _privacyPicker() async {
    final value = await showModalBottomSheet<String>(context: context, builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, children: ['Herkese açık', 'Takipçiler', 'Sadece BEN'].map((x) => ListTile(title: Text(x), trailing: x == _privacy ? const Icon(Icons.check_rounded, color: BenTokens.cyan) : null, onTap: () => Navigator.pop(sheet, x))).toList()));
    if (value != null && mounted) setState(() => _privacy = value);
  }
}
