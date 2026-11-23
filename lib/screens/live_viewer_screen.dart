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
  String _peerId = _newPeerId();
  final List<RTCIceCandidate> _pendingCandidates = <RTCIceCandidate>[];
  bool _rendererInitialized = false;
  bool _joining = false;
  String? _failureMessage;
  Timer? _connectionTimeoutTimer;
  RTCPeerConnection? _pc;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  String? _hostPeerId;
  bool _joined = false;
  bool _remoteDescriptionReady = false;
  bool _busy = false;
  String _title = 'CANLI';
  String _status = 'Canlıya bağlanıyor…';
  bool _polling = false;
  bool _turnAvailable = false;
  List<Map<String, dynamic>> _iceServers = <Map<String, dynamic>>[
    <String, dynamic>{'urls': <String>['stun:stun.l.google.com:19302', 'stun:stun.cloudflare.com:3478']},
  ];

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _loadIceServers() async {
    try {
      final result = await _api.get('live/ice-servers');
      if (result is! Map || result['ice_servers'] is! List) return;
      final servers = (result['ice_servers'] as List)
          .whereType<Map>()
          .map((server) => Map<String, dynamic>.from(server))
          .toList();
      if (servers.isEmpty) return;
      _iceServers = servers;
      _turnAvailable = result['turn_available'] == true;
    } catch (_) {
      _turnAvailable = false;
    }
  }

  Future<void> _join() async {
    if (_joining || _joined) return;
    _joining = true;
    if (mounted) {
      setState(() {
        _busy = true;
        _failureMessage = null;
        _status = 'Canlıya bağlanıyor…';
      });
    }
    var peerRegistered = false;
    try {
      await _loadIceServers();
      if (!_rendererInitialized) {
        await _renderer.initialize();
        _rendererInitialized = true;
      }
      final result = await _api.post(
        'live/${widget.liveId}/join',
        body: {'peer_id': _peerId},
      );
      peerRegistered = true;
      if (result is! Map) throw const ApiException('Canlı bilgisi alınamadı.');
      _hostPeerId = result['host_peer_id']?.toString();
      if (_hostPeerId == null || _hostPeerId!.isEmpty) {
        throw const ApiException('Yayıncı bağlantı kimliği alınamadı.');
      }
      _title = result['title']?.toString() ?? 'CANLI';
      final pc = await createPeerConnection({
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
      });
      _pc = pc;
      pc.onConnectionState = _updateConnectionStatus;
      pc.onIceConnectionState = _updateConnectionStatus;
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate == null ||
            candidate.candidate!.isEmpty ||
            _hostPeerId == null) {
          return;
        }
        unawaited(_sendSignal('candidate', candidate.toMap()).then((_) {}));
      };
      pc.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams.first;
          _connectionTimeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _status = 'CANLI bağlantısı kuruldu';
              _failureMessage = null;
            });
          }
        }
      };
      _joined = true;
      if (!_turnAvailable && mounted) {
        setState(() {
          _status = 'STUN ile bağlantı deneniyor • TURN ayarı yok';
        });
      }
      _pollTimer?.cancel();
      _heartbeatTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (_) => _pollSignals(),
      );
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 12),
        (_) => _heartbeat(),
      );
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = Timer(const Duration(seconds: 25), () {
        if (!mounted || !_joined || _renderer.srcObject != null) return;
        setState(() {
          _status = 'Video akışı henüz gelmedi.';
          _failureMessage =
              'Yayıncıyla medya bağlantısı kurulamadı. Tekrar deneyebilir veya yayıncının bağlantı ayarlarını kontrol edebilirsin.';
        });
      });
      if (mounted) {
        setState(() {
          _busy = false;
          if (_turnAvailable) _status = 'Yayıncıya bağlanıyor…';
        });
      }
      await _pollSignals();
    } catch (error) {
      if (peerRegistered) {
        try {
          await _api.post(
            'live/${widget.liveId}/leave',
            body: {'peer_id': _peerId},
          );
        } catch (_) {}
      }
      _joined = false;
      _connectionTimeoutTimer?.cancel();
      _pollTimer?.cancel();
      _heartbeatTimer?.cancel();
      final pc = _pc;
      _pc = null;
      try {
        await pc?.close();
      } catch (_) {}
      try {
        await pc?.dispose();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'Canlıya bağlanılamadı.';
          _failureMessage = error.toString();
        });
      }
    } finally {
      _joining = false;
    }
  }

  void _updateConnectionStatus(Object state) {
    if (!mounted) return;
    final connection = state.toString().toLowerCase();
    setState(() {
      if (connection.contains('failed')) {
        _status = 'Medya bağlantısı kurulamadı.';
        _failureMessage =
            'ICE bağlantısı başarısız. TURN sunucusu olmayan bazı mobil ağlarda bu durum yaşanabilir.';
      } else if (connection.contains('disconnected')) {
        _status = 'Yayıncı bağlantısı kesildi.';
        _failureMessage = 'Bağlantı kesildi. Yeniden bağlanmayı deneyebilirsin.';
      } else if (connection.contains('connected') ||
          connection.contains('completed')) {
        _status = 'CANLI bağlantısı kuruldu';
        _failureMessage = null;
        _connectionTimeoutTimer?.cancel();
      } else if (connection.contains('checking') ||
          connection.contains('connecting')) {
        _status = 'Medya bağlantısı kuruluyor…';
      }
    });
  }

  Future<void> _retryJoin() async {
    await _leave();
    _peerId = _newPeerId();
    _hostPeerId = null;
    _remoteDescriptionReady = false;
    _pendingCandidates.clear();
    _renderer.srcObject = null;
    if (!mounted) return;
    await _join();
  }

  static String _newPeerId() =>
      'viewer-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> _pollSignals() async {
    if (!_joined || !mounted || _polling) return;
    _polling = true;
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
    } catch (error) {
      if (error is ApiException && error.statusCode == 404 && mounted) {
        setState(() => _status = 'Yayın sona erdi.');
        await _leave();
        if (mounted) Navigator.pop(context);
      } else if (mounted && _joined) {
        setState(() => _status = 'Bağlantı yenileniyor…');
      }
    } finally {
      _polling = false;
    }
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
    _connectionTimeoutTimer?.cancel();
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    final pc = _pc;
    _pc = null;
    try { await pc?.close(); } catch (_) {}
    try { await pc?.dispose(); } catch (_) {}
    _renderer.srcObject = null;
  }

  @override
  void dispose() {
    _connectionTimeoutTimer?.cancel();
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    final shouldLeave = _joined;
    _joined = false;
    if (shouldLeave) {
      unawaited(_api.post(
        'live/${widget.liveId}/leave',
        body: {'peer_id': _peerId},
      ));
    }
    _renderer.srcObject = null;
    _renderer.dispose();
    final pc = _pc;
    _pc = null;
    unawaited(pc?.close() ?? Future<void>.value());
    unawaited(pc?.dispose() ?? Future<void>.value());
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
          body: SizedBox.expand(
            child: Stack(fit: StackFit.expand, children: [
            Positioned.fill(
              child: _renderer.srcObject == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_busy)
                              const CircularProgressIndicator(color: BenTokens.cyan)
                            else
                              const Icon(
                                Icons.videocam_off_rounded,
                                color: BenTokens.cyan,
                                size: 42,
                              ),
                            const SizedBox(height: 14),
                            Text(
                              _busy ? 'Canlıya bağlanıyor…' : _status,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_failureMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _failureMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _busy ? null : _retryJoin,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Tekrar bağlan'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : RTCVideoView(
                      _renderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
            Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .55), Colors.transparent, Colors.black.withValues(alpha: .72)], stops: const [0, .48, 1]))))),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _leave();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                        decoration: BoxDecoration(
                          color: BenTokens.cyan.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: BenTokens.cyan.withValues(alpha: .26)),
                        ),
                        child: Text(
                          _status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ]),
          ),
        ),
      );
}
