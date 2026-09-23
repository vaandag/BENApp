import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../core/navigation/ben_routes.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';
import '../models/memory.dart';
import '../services/auth_service.dart';
import '../services/memory_repository.dart';
import '../features/messages/presentation/messages_screen.dart';

/// A single, immersive viewer for every memory type.
/// Media is presented edge-to-edge with contain semantics so the original
/// image/video is never cropped by the UI chrome.
class MemoryFullscreenViewer extends StatefulWidget {
  final Memory memory;
  final List<Memory> memories;

  const MemoryFullscreenViewer({super.key, required this.memory, required this.memories});

  @override
  State<MemoryFullscreenViewer> createState() => _MemoryFullscreenViewerState();
}

class _MemoryFullscreenViewerState extends State<MemoryFullscreenViewer> {
  final MemoryRepository _repository = MemoryRepository();
  final ApiClient _api = ApiClient();
  late bool _liked;
  late bool _pinned;
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.memory.isFavorite;
    _pinned = widget.memory.isPinned;
    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    final source = widget.memory.video;
    if (source == null || source.isEmpty) return;
    try {
      final file = File(source);
      final controller = file.existsSync()
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(source));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoReady = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final next = !_liked;
    try { await _repository.toggleFavorite(widget.memory.id); } catch (_) {}
    final id = int.tryParse(widget.memory.id);
    if (id != null) {
      try { await _api.post('memories/$id/like', body: {'user_id': AuthService.currentUser?.id ?? 1}); } catch (_) {}
    }
    if (mounted) setState(() => _liked = next);
  }

  Future<void> _togglePin() async {
    final next = !_pinned;
    try { await _repository.togglePinned(widget.memory.id); } catch (_) {}
    final id = int.tryParse(widget.memory.id);
    if (id != null) {
      try { await _api.post('memories/$id/save', body: {'user_id': AuthService.currentUser?.id ?? 1}); } catch (_) {}
    }
    if (mounted) setState(() => _pinned = next);
  }

  Future<void> _openComments() async {
    await BenRoutes.openComments(
      context,
      memoryId: int.tryParse(widget.memory.id),
      memoryKey: widget.memory.id,
    );
  }

  Future<void> _share() async {
    final memory = widget.memory;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0A131B),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Anıyı paylaş', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: BenTokens.cyan),
              title: const Text('BEN’de gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: const Text('Bağlarından birini seç', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MessagesScreen(memoryToShare: memory)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded, color: BenTokens.gold),
              title: const Text('Diğer uygulamalar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: const Text('WhatsApp ve cihazındaki diğer uygulamalar', style: TextStyle(color: Colors.white54)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await SharePlus.instance.share(
                  ShareParams(text: 'BEN’de bir anı paylaşıldı: ${memory.title ?? memory.text ?? 'Bir anı'}'),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _media() {
    final memory = widget.memory;
    if (memory.photo != null && memory.photo!.existsSync()) {
      return InteractiveViewer(minScale: .75, maxScale: 4, child: Image.file(memory.photo!, fit: BoxFit.contain, filterQuality: FilterQuality.high));
    }
    if (memory.mediaUrl?.startsWith('http') == true && memory.type == MemoryType.photo) {
      return InteractiveViewer(minScale: .75, maxScale: 4, child: Image.network(memory.mediaUrl!, fit: BoxFit.contain, filterQuality: FilterQuality.high, errorBuilder: (_, __, ___) => _textMemory()));
    }
    if (_videoReady && _video != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _video!.value.aspectRatio,
          child: VideoPlayer(_video!),
        ),
      );
    }
    if (memory.hasVideo) {
      return const Center(child: CircularProgressIndicator(color: BenTokens.cyan));
    }
    return _textMemory();
  }

  Widget _textMemory() {
    final text = widget.memory.text ?? widget.memory.description ?? 'Bu anıda medya yok.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 100, 28, 180),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.18, fontWeight: FontWeight.w900)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _media(),
          IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .55), Colors.transparent, Colors.black.withValues(alpha: .82)])))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(children: [
                Row(children: [
                  _GlassAction(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AuthService.currentUser?.username ?? 'BEN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    if (memory.title?.isNotEmpty == true) Text(memory.title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                  ])),
                  _GlassAction(icon: Icons.ios_share_rounded, onTap: _share),
                ]),
                const Spacer(),
                if (memory.hasLocation)
                  Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on_rounded, color: BenTokens.gold, size: 16), SizedBox(width: 5), Text('Konumlu anı', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]))),
                const SizedBox(height: 12),
                if (memory.hasText && (memory.type != MemoryType.text || memory.photo != null || memory.hasVideo))
                  Align(alignment: Alignment.centerLeft, child: Text(memory.text!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2))),
                const SizedBox(height: 14),
                Row(children: [
                  _BottomAction(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: 'Beğen', active: _liked, onTap: _toggleLike),
                  const SizedBox(width: 8),
                  _BottomAction(icon: Icons.chat_bubble_outline_rounded, label: 'Yorum', onTap: _openComments),
                  const SizedBox(width: 8),
                  _BottomAction(icon: _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, label: 'Sabitle', active: _pinned, onTap: _togglePin),
                  const SizedBox(width: 8),
                  _BottomAction(icon: Icons.ios_share_rounded, label: 'Paylaş', onTap: _share),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassAction({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.black54, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white))));
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomAction({required this.icon, required this.label, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: active ? BenTokens.cyan : Colors.black54,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: active ? BenTokens.ink : Colors.white, size: 19),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? BenTokens.ink : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
