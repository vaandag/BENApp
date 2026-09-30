import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_tokens.dart';

class LiveViewerScreen extends StatefulWidget {
  final int liveId;
  const LiveViewerScreen({super.key, required this.liveId});
  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  final ApiClient _api = ApiClient();
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final String _peerId = 'viewer-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
  final List<RTCIceCandidate> _pendingCandidates = <RTCIceCandidate>[];
  RTCPeerConnection? _pc;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  String? _hostPeerId;
  bool _joined = false;
  bool _remoteDescriptionReady = false;
  bool _busy = true;
  String _title = 'CANLI';
  String _status = 'Canlıya bağlanıyor…';

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      await _renderer.initialize();
      final result = await _api.post('live/${widget.liveId}/join', body: {'peer_id': _peerId});
      if (result is! Map) throw const ApiException('Canlı bilgisi alınamadı.');
      _hostPeerId = result['host_peer_id']?.toString();
      _title = result['title']?.toString() ?? 'CANLI';
      _pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}, {'urls': 'stun:stun.cloudflare.com:3478'}], 'sdpSemantics': 'unified-plan'});
      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty || _hostPeerId == null) return;
        _sendSignal('candidate', candidate.toMap());
      };
      _pc!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams.first;
          if (mounted) setState(() => _status = 'CANLI bağlantısı kuruldu');
        }
      };
      _joined = true;
      _busy = false;
      _pollTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) => _pollSignals());
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) => _heartbeat());
      if (mounted) setState(() {});
      await _pollSignals();
    } catch (e) {
      if (mounted) { setState(() { _busy = false; _status = 'Canlıya bağlanılamadı.'; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    }
  }

  Future<void> _pollSignals() async {
    if (!_joined || !mounted) return;
    try {
      final result = await _api.get('live/${widget.liveId}/signals', query: {'peer_id': _peerId});
      final signals = result is Map && result['signals'] is List ? result['signals'] as List : const [];
      for (final item in signals) {
        if (item is! Map || item['payload'] is! Map) continue;
        final kind = item['kind']?.toString();
        final fromPeer = item['from_peer']?.toString();
        final payload = item['payload'] as Map;
        if (_hostPeerId == null && fromPeer != null) _hostPeerId = fromPeer;
        if (kind == 'offer') await _handleOffer(payload);
        if (kind == 'candidate') await _handleCandidate(payload);
      }
    } catch (_) {}
  }

  Future<void> _handleOffer(Map payload) async {
    final pc = _pc;
    if (pc == null) return;
    await pc.setRemoteDescription(RTCSessionDescription(payload['sdp']?.toString(), payload['type']?.toString()));
    _remoteDescriptionReady = true;
    for (final candidate in _pendingCandidates) { try { await pc.addCandidate(candidate); } catch (_) {} }
    _pendingCandidates.clear();
    final answer = await pc.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': true});
    await pc.setLocalDescription(answer);
    if (_hostPeerId != null) await _sendSignal('answer', (await pc.getLocalDescription())?.toMap() ?? answer.toMap());
  }

  Future<void> _handleCandidate(Map payload) async {
    final candidate = RTCIceCandidate(payload['candidate']?.toString(), payload['sdpMid']?.toString(), int.tryParse('${payload['sdpMLineIndex'] ?? ''}'));
    final pc = _pc;
    if (pc == null) return;
    if (!_remoteDescriptionReady) {
      _pendingCandidates.add(candidate);
      return;
    }
    try { await pc.addCandidate(candidate); } catch (_) { _pendingCandidates.add(candidate); }
  }

  Future<void> _sendSignal(String kind, Map<String, dynamic> payload) async {
    final to = _hostPeerId;
    if (to == null) return;
    try { await _api.post('live/${widget.liveId}/signal', body: {'from_peer': _peerId, 'to_peer': to, 'kind': kind, 'payload': payload}); } catch (_) {}
  }

  Future<void> _heartbeat() async {
    if (!_joined) return;
    try { await _api.post('live/${widget.liveId}/heartbeat', body: {'peer_id': _peerId}); } catch (_) {}
  }

  Future<void> _leave() async {
    if (_joined) { try { await _api.post('live/${widget.liveId}/leave', body: {'peer_id': _peerId}); } catch (_) {} }
    _joined = false;
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    try { await _pc?.close(); } catch (_) {}
    try { await _pc?.dispose(); } catch (_) {}
    _pc = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _renderer.srcObject = null;
    _renderer.dispose();
    _pc?.close();
    _pc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_joined,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _leave();
          if (context.mounted) Navigator.pop(context);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            Positioned.fill(child: _renderer.srcObject == null ? Center(child: _busy ? const CircularProgressIndicator(color: BenTokens.cyan) : const Text('CANLI video akışı alınamadı.', style: TextStyle(color: Colors.white))) : RTCVideoView(_renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
            Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .55), Colors.transparent, Colors.black.withValues(alpha: .72)], stops: const [0, .48, 1]))))),
            SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 0), child: Row(children: [IconButton(onPressed: () async { await _leave(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)), Expanded(child: Text(_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: BenTokens.cyan.withValues(alpha: .16), borderRadius: BorderRadius.circular(99), border: Border.all(color: BenTokens.cyan.withValues(alpha: .26))), child: Text(_status, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))]))),
          ]),
        ),
      );
}
