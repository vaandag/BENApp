import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';

class LiveStudioScreen extends StatefulWidget {
  const LiveStudioScreen({super.key});
  @override
  State<LiveStudioScreen> createState() => _LiveStudioScreenState();
}

class _LiveStudioScreenState extends State<LiveStudioScreen> {
  final ApiClient _api = ApiClient();
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final String _peerId = _randomId();
  final Map<String, RTCPeerConnection> _peers = <String, RTCPeerConnection>{};
  final Map<String, List<RTCIceCandidate>> _pendingCandidates = <String, List<RTCIceCandidate>>{};
  final Set<String> _remoteDescriptionReady = <String>{};

  MediaStream? _localStream;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  int? _liveId;
  bool _starting = true;
  bool _live = false;
  bool _busy = false;
  String _status = 'Kamera hazırlanıyor…';
  String _title = 'BEN CANLI';
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _renderer.initialize();
      final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': {'facingMode': 'user'}});
      _localStream = stream;
      _renderer.srcObject = stream;
      if (mounted) setState(() => _status = 'Yayın için hazır');
    } catch (e) {
      if (mounted) setState(() => _status = 'Kamera/mikrofon açılamadı: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _startLive() async {
    if (_localStream == null || _live != false || _busy) return;
    setState(() { _busy = true; _status = 'CANLI başlatılıyor…'; });
    try {
      final result = await _api.post('live', body: {'title': _title.trim().isEmpty ? 'BEN CANLI' : _title.trim(), 'host_peer_id': _peerId});
      final id = result is Map ? int.tryParse('${result['id'] ?? ''}') : null;
      if (id == null) throw const ApiException('Canlı yayın kimliği alınamadı.');
      _liveId = id;
      _live = true;
      _status = 'CANLI • bağlantılar bekleniyor';
      _pollTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) => _pollSignalsAndPeers());
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) => _heartbeat());
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() { _status = 'CANLI açılamadı.'; _busy = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pollSignalsAndPeers() async {
    final liveId = _liveId;
    if (!_live || liveId == null || !mounted) return;
    try {
      final peerResult = await _api.get('live/$liveId/peers');
      final rawPeers = peerResult is Map && peerResult['peers'] is List ? peerResult['peers'] as List : const [];
      final ids = <String>{};
      for (final item in rawPeers) {
        if (item is! Map) continue;
        final id = item['peer_id']?.toString();
        if (id == null || id.isEmpty) continue;
        ids.add(id);
        if (!_peers.containsKey(id)) await _createHostPeer(id);
      }
      _viewerCount = ids.length;
      final stale = _peers.keys.where((id) => !ids.contains(id)).toList();
      for (final id in stale) {
        await _closePeer(id);
      }

      final signals = await _api.get('live/$liveId/signals', query: {'peer_id': _peerId});
      final list = signals is Map && signals['signals'] is List ? signals['signals'] as List : const [];
      for (final item in list) {
        if (item is! Map) continue;
        final fromPeer = item['from_peer']?.toString();
        final kind = item['kind']?.toString();
        final payload = item['payload'];
        if (fromPeer == null || kind == null || payload is! Map) continue;
        final pc = _peers[fromPeer];
        if (kind == 'answer' && pc != null) {
          await pc.setRemoteDescription(RTCSessionDescription(payload['sdp']?.toString(), payload['type']?.toString()));
          _remoteDescriptionReady.add(fromPeer);
          await _flushPending(fromPeer, pc);
        } else if (kind == 'candidate' && pc != null) {
          final candidate = RTCIceCandidate(payload['candidate']?.toString(), payload['sdpMid']?.toString(), int.tryParse('${payload['sdpMLineIndex'] ?? ''}'));
          if (!_remoteDescriptionReady.contains(fromPeer)) {
            _pendingCandidates.putIfAbsent(fromPeer, () => []).add(candidate);
          } else {
            try { await pc.addCandidate(candidate); } catch (_) { _pendingCandidates.putIfAbsent(fromPeer, () => []).add(candidate); }
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _createHostPeer(String viewerPeer) async {
    final liveId = _liveId;
    final local = _localStream;
    if (liveId == null || local == null || _peers.containsKey(viewerPeer)) return;
    final pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}, {'urls': 'stun:stun.cloudflare.com:3478'}], 'sdpSemantics': 'unified-plan'});
    _peers[viewerPeer] = pc;
    _pendingCandidates[viewerPeer] = <RTCIceCandidate>[];
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      _sendSignal(liveId, viewerPeer, 'candidate', candidate.toMap());
    };
    for (final track in local.getTracks()) {
      await pc.addTrack(track, local);
    }
    final offer = await pc.createOffer({'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
    await pc.setLocalDescription(offer);
    await _sendSignal(liveId, viewerPeer, 'offer', (await pc.getLocalDescription())?.toMap() ?? offer.toMap());
  }

  Future<void> _sendSignal(int liveId, String toPeer, String kind, Map<String, dynamic> payload) async {
    try { await _api.post('live/$liveId/signal', body: {'from_peer': _peerId, 'to_peer': toPeer, 'kind': kind, 'payload': payload}); } catch (_) {}
  }

  Future<void> _flushPending(String peerId, RTCPeerConnection pc) async {
    final queue = _pendingCandidates.remove(peerId) ?? const <RTCIceCandidate>[];
    for (final candidate in queue) { try { await pc.addCandidate(candidate); } catch (_) {} }
    _pendingCandidates[peerId] = <RTCIceCandidate>[];
  }

  Future<void> _heartbeat() async {
    final id = _liveId;
    if (!_live || id == null) return;
    try { await _api.post('live/$id/heartbeat', body: {'peer_id': _peerId}); } catch (_) {}
  }

  Future<void> _stopLive() async {
    final id = _liveId;
    if (id != null) { try { await _api.post('live/$id/stop'); } catch (_) {} }
    _live = false;
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    for (final id in _peers.keys.toList()) { await _closePeer(id); }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _closePeer(String id) async {
    final pc = _peers.remove(id);
    if (pc != null) { try { await pc.close(); } catch (_) {} try { await pc.dispose(); } catch (_) {} }
    _pendingCandidates.remove(id);
    _remoteDescriptionReady.remove(id);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    for (final pc in _peers.values) { pc.close(); pc.dispose(); }
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) { track.stop(); }
    _localStream?.dispose();
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: _starting || _localStream == null ? const Center(child: CircularProgressIndicator(color: BenTokens.cyan)) : RTCVideoView(_renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true)),
        Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .52), Colors.transparent, Colors.black.withValues(alpha: .86)], stops: const [0, .42, 1]))))),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), child: Row(children: [IconButton(onPressed: () { if (_live) return; Navigator.pop(context); }, icon: const Icon(Icons.close_rounded, color: Colors.white)), Expanded(child: Text(_live ? 'CANLI • $_viewerCount' : 'CANLI STÜDYO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), if (_live) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: .90), borderRadius: BorderRadius.circular(99)), child: const Text('YAYINDA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))]))),
        if (!_live && !_starting) Positioned(left: 18, right: 18, bottom: 28, child: SafeArea(top: false, child: _StartPanel(title: _title, status: _status, busy: _busy, onTitle: (v) => setState(() => _title = v), onStart: _startLive))),
        if (_live) Positioned(left: 16, right: 16, bottom: 22, child: SafeArea(top: false, child: FilledButton.icon(onPressed: _stopLive, style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.stop_circle_outlined), label: const Text('YAYINI BİTİR')))),
        Positioned(left: 18, top: 86, child: SafeArea(top: false, child: Text(_status, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontWeight: FontWeight.w700, fontSize: 11)))),
      ]),
    );
  }

  static String _randomId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${math.Random().nextInt(1 << 30).toRadixString(36)}';
}

class _StartPanel extends StatefulWidget {
  final String title;
  final String status;
  final bool busy;
  final ValueChanged<String> onTitle;
  final VoidCallback onStart;
  const _StartPanel({required this.title, required this.status, required this.busy, required this.onTitle, required this.onStart});

  @override
  State<_StartPanel> createState() => _StartPanelState();
}

class _StartPanelState extends State<_StartPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant _StartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != oldWidget.title && widget.title != _controller.text) {
      _controller.value = _controller.value.copyWith(text: widget.title, selection: TextSelection.collapsed(offset: widget.title.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: const Color(0xE9081117), borderRadius: BorderRadius.circular(26), border: Border.all(color: BenTokens.cyan.withValues(alpha: .24))),
        child: Column(children: [
          TextField(controller: _controller, onChanged: widget.onTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800), textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Yayın başlığı', labelStyle: TextStyle(color: Colors.white70), hintText: 'BEN CANLI', hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none)),
          Text(widget.status, style: TextStyle(color: Colors.white.withValues(alpha: .56), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: widget.busy ? null : widget.onStart, style: FilledButton.styleFrom(backgroundColor: BenTokens.cyan, foregroundColor: BenTokens.ink, padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.wifi_tethering_rounded), label: Text(widget.busy ? 'Açılıyor…' : 'CANLI YAYINI BAŞLAT'))),
        ]),
      );
}
