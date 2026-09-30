import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_tokens.dart';
import '../core/navigation/ben_routes.dart';
import 'memory_fullscreen_viewer.dart';
import 'ben_3d_map_screen.dart';
import '../models/memory.dart';
import '../services/location_service.dart';

/// BEN WORLD / Harita — stable spatial memory explorer.
///
/// The main navigation uses this pure-Flutter map. Native MapLibre remains a
/// separate experimental 3D surface, but it is no longer part of the primary
/// iOS navigation path. Memory points are shown as scale-aware clusters rather
/// than a wall of identical pins, and selection is driven by a deterministic
/// location-aware discovery score.
class MapScreen extends StatefulWidget {
  final List<Memory> memories;
  final Memory? focusMemory;

  const MapScreen({super.key, required this.memories, this.focusMemory});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _controller = MapController();
  final LocationService _locationService = LocationService();
  late final AnimationController _pulse;

  String? _expandedClusterKey;
  bool _mapReady = false;
  bool _locating = false;
  bool _preparedLocation = false;
  double _currentZoom = 11.4;
  LatLng _center = const LatLng(41.0082, 28.9784);
  LatLng? _userLocation;
  int _filter = 0;
  _MapPin? _selectedPin;
  final List<String> _history = <String>[];
  final Set<String> _seen = <String>{};
  final Set<String> _liked = <String>{};
  final Set<String> _saved = <String>{};

  final Map<String, List<String>> _comments = <String, List<String>>{
    'mert': ['Burası akşamları gerçekten başka.', 'Dün ben de buradaydım.'],
    'lina': ['Kahve + deniz = BEN.', 'Moda yine güzel.'],
    'arda': ['Şehir akıyor gerçekten.'],
    'nehir': ['Bu sokağın hikâyesi bitmez.'],
    'ece': ['Boğaz bugün çok sakin.'],
    'bican': ['Buradan bir BEN geçti 😄'],
    'defne': ['Bu manzara favorim.'],
    'kaan': ['Akşam rotası kaydedildi.'],
    'selin': ['Buraya tekrar gelmeliyim.'],
    'umut': ['Şehrin en güzel saatleri.'],
  };

  static const _demoPins = [
    _MapPin('mert', 'Mert Kaya', 'Kadıköy Sahil', 'Akşamın rengi bugün başka.', 40.9919, 29.0277, Icons.waves_rounded, 128, 14, _MapPinKind.memory),
    _MapPin('lina', 'Lina Demir', 'Moda', 'Bir kahve, biraz deniz, biraz BEN.', 40.9870, 29.0250, Icons.local_cafe_rounded, 86, 9, _MapPinKind.place),
    _MapPin('arda', 'Arda Yılmaz', 'Beşiktaş', 'Kulaklık takılı. Şehir akıyor.', 41.0432, 29.0057, Icons.graphic_eq_rounded, 211, 22, _MapPinKind.person),
    _MapPin('nehir', 'Nehir Acar', 'Beyoğlu', 'Bir sokak, üç hikâye.', 41.0340, 28.9772, Icons.location_on_rounded, 64, 6, _MapPinKind.memory),
    _MapPin('ece', 'Ece Su', 'Bebek', 'Boğaz bugün sakin.', 41.0750, 29.0437, Icons.wb_sunny_rounded, 43, 4, _MapPinKind.place),
    _MapPin('bican', 'Bican', 'Beylikdüzü', 'Buradan bir BEN geçti.', 41.0027, 28.6415, Icons.person_pin_circle_rounded, 17, 3, _MapPinKind.person),
    _MapPin('defne', 'Defne Aras', 'Ortaköy', 'Şehrin ışıkları yeni yanıyor.', 41.0477, 29.0274, Icons.nightlight_round, 74, 8, _MapPinKind.memory),
    _MapPin('kaan', 'Kaan Efe', 'Galata', 'Bugünkü rota burada bitti.', 41.0256, 28.9741, Icons.route_rounded, 52, 5, _MapPinKind.person),
    _MapPin('selin', 'Selin Ada', 'Emirgan', 'Biraz yeşil, biraz Boğaz.', 41.1061, 29.0548, Icons.park_rounded, 91, 11, _MapPinKind.place),
    _MapPin('umut', 'Umut Can', 'Sarıyer', 'Günün son BEN izi.', 41.1696, 29.0577, Icons.nightlight_round, 39, 3, _MapPinKind.memory),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _loadLocalState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareStart());
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focusMemory;
    if (focus != null && focus.id != oldWidget.focusMemory?.id && focus.hasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_mapReady) return;
        _selectPin(_MapPin.fromMemory(focus));
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<_MapPin> get _pins {
    final real = widget.memories
        .where((m) => m.hasLocation && !m.isExpired && (_filter == 0 || _filter == 1))
        .map(_MapPin.fromMemory);
    final demo = _demoPins.where((p) {
      if (_filter == 1) return p.kind == _MapPinKind.memory;
      if (_filter == 2) return p.kind == _MapPinKind.person;
      if (_filter == 3) return p.kind == _MapPinKind.place;
      return true;
    });
    return [...real, ...demo];
  }

  List<_MapNode> get _nodes => _cluster(_pins, _currentZoom);

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _liked.addAll(prefs.getStringList('ben_map_liked_memories') ?? const []);
      _saved.addAll(prefs.getStringList('ben_map_saved_memories') ?? const []);
      _seen.addAll(prefs.getStringList('ben_memory_seen') ?? const []);
    });
  }

  Future<void> _persistLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setStringList('ben_map_liked_memories', _liked.toList()),
      prefs.setStringList('ben_map_saved_memories', _saved.toList()),
      prefs.setStringList('ben_memory_seen', _seen.toList()),
    ]);
  }

  Future<void> _prepareStart() async {
    final focus = widget.focusMemory;
    if (focus?.hasLocation == true) {
      _center = LatLng(focus!.latitude!, focus.longitude!);
      _preparedLocation = true;
      if (mounted) setState(() {});
      return;
    }

    try {
      final result = await _locationService.getCurrent(context, showFeedback: false);
      final snapshot = result.snapshot;
      if (snapshot != null) {
        _userLocation = snapshot.latLng;
        _center = snapshot.latLng;
      }
    } catch (_) {}

    if (_userLocation == null) {
      final first = _pins.where((p) => p.kind == _MapPinKind.memory).firstOrNull ?? _pins.firstOrNull;
      if (first != null) _center = LatLng(first.latitude, first.longitude);
    }
    if (mounted) {
      setState(() => _preparedLocation = true);
    }
  }

  double _cellSizeForZoom(double zoom) {
    if (zoom < 6) return .40;
    if (zoom < 8) return .20;
    if (zoom < 10) return .10;
    if (zoom < 12) return .050;
    if (zoom < 14) return .018;
    if (zoom < 16) return .006;
    if (zoom < 18) return .0025;
    return .0011;
  }

  List<_MapNode> _cluster(List<_MapPin> pins, double zoom) {
    final cell = _cellSizeForZoom(zoom);
    final groups = <String, List<_MapPin>>{};
    for (final pin in pins) {
      if (!pin.latitude.isFinite || !pin.longitude.isFinite) continue;
      final x = (pin.latitude / cell).floor();
      final y = (pin.longitude / cell).floor();
      groups.putIfAbsent('$x:$y', () => <_MapPin>[]).add(pin);
    }

    final nodes = <_MapNode>[];
    for (final entry in groups.entries) {
      final members = entry.value;
      var lat = 0.0;
      var lon = 0.0;
      for (final p in members) {
        lat += p.latitude;
        lon += p.longitude;
      }
      nodes.add(_MapNode(
        key: entry.key,
        center: LatLng(lat / members.length, lon / members.length),
        members: List.unmodifiable(members),
      ));
    }
    nodes.sort((a, b) {
      final sa = _nodePriority(a);
      final sb = _nodePriority(b);
      return sb.compareTo(sa);
    });
    return nodes;
  }

  double _nodePriority(_MapNode node) {
    if (node.members.isEmpty) return 0;
    final origin = _userLocation ?? _center;
    var best = 0.0;
    for (final p in node.members) {
      final distanceKm = _distanceKm(origin, LatLng(p.latitude, p.longitude));
      best = math.max(best, 1 / (1 + distanceKm));
    }
    return node.members.length * .08 + best;
  }

  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0088;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final h = math.pow(math.sin(dLat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h.toDouble()), math.sqrt(math.max(0.0, 1 - h.toDouble())));
  }

  double _degToRad(double value) => value * math.pi / 180;

  double _discoveryScore(_MapPin pin, LatLng origin, {required bool preferFresh}) {
    final distanceKm = _distanceKm(origin, LatLng(pin.latitude, pin.longitude));
    final proximity = 1 / (1 + distanceKm);
    final unseen = _seen.contains(pin.id) ? 0.0 : 1.0;
    final recency = pin.memory?.createdAt != null
        ? math.max(0, 1 - DateTime.now().difference(pin.memory!.createdAt).inDays / 45).toDouble()
        : .25;
    final social = math.min(1.0, pin.likes / 150.0);
    return proximity * .54 + unseen * .23 + (preferFresh ? recency : recency * .12) + social * .05;
  }

  List<_MapPin> _rankedPins({LatLng? origin, String? excluding}) {
    final from = origin ?? _userLocation ?? _center;
    final candidates = _pins.where((p) => p.id != excluding).toList();
    candidates.sort((a, b) => _discoveryScore(b, from, preferFresh: true).compareTo(_discoveryScore(a, from, preferFresh: true)));
    return candidates;
  }

  void _selectPin(_MapPin pin, {bool addHistory = true}) {
    if (!mounted) return;
    final previous = _selectedPin;
    if (addHistory && previous != null && previous.id != pin.id) {
      _history.add(previous.id);
      if (_history.length > 20) _history.removeAt(0);
    }
    _seen.add(pin.id);
    setState(() {
      _selectedPin = pin;
      _expandedClusterKey = null;
    });
    _persistLocalState();
    if (_mapReady) _controller.move(LatLng(pin.latitude, pin.longitude), math.max(_currentZoom, 15.8));
  }

  void _selectNode(_MapNode node) {
    if (node.members.length == 1) {
      _selectPin(node.members.first);
      return;
    }
    setState(() {
      _expandedClusterKey = node.key;
      _selectedPin = null;
    });
    final nextZoom = math.min(17.2, _currentZoom + (node.members.length > 12 ? 2.2 : 1.7));
    _controller.move(node.center, nextZoom);
  }

  void _exploreNext() {
    final current = _selectedPin;
    final origin = current == null ? (_userLocation ?? _center) : LatLng(current.latitude, current.longitude);
    final ranked = _rankedPins(origin: origin, excluding: current?.id);
    final candidate = ranked.firstOrNull;
    if (candidate != null) _selectPin(candidate);
  }

  void _explorePrevious() {
    if (_history.isEmpty) return;
    final lastId = _history.removeLast();
    final target = _pins.where((p) => p.id == lastId).firstOrNull;
    if (target != null) _selectPin(target, addHistory: false);
  }

  int _commentCount(_MapPin pin) => pin.comments + (_comments[pin.id]?.length ?? 0);

  Future<void> _toggleLike(_MapPin pin) async {
    setState(() {
      if (!_liked.add(pin.id)) _liked.remove(pin.id);
    });
    await _persistLocalState();
  }

  Future<void> _toggleSave(_MapPin pin) async {
    setState(() {
      if (!_saved.add(pin.id)) _saved.remove(pin.id);
    });
    await _persistLocalState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_saved.contains(pin.id) ? 'BEN izi kaydedildi.' : 'BEN izi kayıtlardan çıkarıldı.')));
  }

  Future<void> _showComments(_MapPin pin) async {
    await BenRoutes.openComments(
      context,
      memoryId: pin.memory == null ? null : int.tryParse(pin.memory!.id),
      memoryKey: pin.memory?.id ?? pin.id,
      title: 'Yorumlar',
      initialCount: _commentCount(pin),
    );
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await _locationService.getCurrent(context, showFeedback: true);
    if (!mounted) return;
    final point = result.snapshot?.latLng;
    setState(() {
      _locating = false;
      if (point != null) {
        _userLocation = point;
        _center = point;
      }
    });
    if (point != null && _mapReady) {
      _controller.move(point, 15.4);
    }
  }

  void _openPin(_MapPin pin) {
    if (pin.memory != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryFullscreenViewer(memory: pin.memory!, memories: widget.memories)));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MapDemoSheet(
        pin: pin,
        liked: _liked.contains(pin.id),
        saved: _saved.contains(pin.id),
        commentCount: _commentCount(pin),
        onLike: () => _toggleLike(pin),
        onSave: () => _toggleSave(pin),
        onComments: () => _showComments(pin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pins = _pins;
    final nodes = _nodes;
    final suggestion = _rankedPins().firstOrNull;

    if (!_preparedLocation) {
      return const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _currentZoom,
            minZoom: 3.2,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            onMapReady: () => _mapReady = true,
            onMapEvent: (event) {
              final nextZoom = event.camera.zoom;
              if ((nextZoom - _currentZoom).abs() >= .12 && mounted) {
                setState(() {
                  _currentZoom = nextZoom;
                  _expandedClusterKey = null;
                });
              } else {
                _currentZoom = nextZoom;
              }
              _center = event.camera.center;
            },
            onTap: (_, _) {
              if (!mounted) return;
              setState(() {
                _selectedPin = null;
                _expandedClusterKey = null;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: dark
                  ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.benapp.mobile',
            ),
            if (_userLocation != null)
              MarkerLayer(markers: [
                Marker(
                  point: _userLocation!,
                  width: 34,
                  height: 34,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => _UserLocationMarker(pulse: _pulse.value),
                  ),
                ),
              ]),
            MarkerLayer(
              markers: nodes.map((node) {
                final isExpanded = node.key == _expandedClusterKey;
                return Marker(
                  point: node.center,
                  width: node.members.length > 1 ? 62 : 66,
                  height: node.members.length > 1 ? 62 : 66,
                  child: GestureDetector(
                    onTap: () => _selectNode(node),
                    child: _MapNodeWidget(
                      node: node,
                      selected: node.members.length == 1 && node.members.first.id == _selectedPin?.id,
                      pulse: _pulse.value,
                      expanded: isExpanded,
                    ),
                  ),
                );
              }).toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(dark ? '© OpenStreetMap contributors © CARTO' : 'OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _MapHeader(
                  count: pins.length,
                  nearbyCount: suggestion == null ? 0 : _pins.where((p) => _distanceKm(_userLocation ?? _center, LatLng(p.latitude, p.longitude)) < 2.5).length,
                  locating: _locating,
                  show3D: defaultTargetPlatform != TargetPlatform.iOS,
                  onLocate: _locateMe,
                  onOpen3D: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Ben3DMapScreen(memories: widget.memories))),
                ),
                const SizedBox(height: 9),
                _MapFilters(selected: _filter, onChanged: (value) => setState(() { _filter = value; _selectedPin = null; _expandedClusterKey = null; })),
              ],
            ),
          ),
        ),
        Positioned(
          top: 136,
          left: 16,
          child: SafeArea(
            bottom: false,
            child: _ExploreChip(
              next: suggestion,
              onTap: _exploreNext,
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: SafeArea(
            top: false,
            child: _selectedPin == null
                ? _ExploreBottomCard(
                    count: pins.length,
                    suggestion: suggestion,
                    onExplore: _exploreNext,
                    onLocate: _locateMe,
                  )
                : _SelectedMapPinCard(
                    pin: _selectedPin!,
                    liked: _liked.contains(_selectedPin!.id),
                    saved: _saved.contains(_selectedPin!.id),
                    commentCount: _commentCount(_selectedPin!),
                    distanceKm: _distanceKm(_userLocation ?? _center, LatLng(_selectedPin!.latitude, _selectedPin!.longitude)),
                    hasPrevious: _history.isNotEmpty,
                    onLike: () => _toggleLike(_selectedPin!),
                    onSave: () => _toggleSave(_selectedPin!),
                    onComments: () => _showComments(_selectedPin!),
                    onOpen: () => _openPin(_selectedPin!),
                    onNext: _exploreNext,
                    onPrevious: _explorePrevious,
                  ),
          ),
        ),
      ],
    );
  }
}

class _MapNode {
  final String key;
  final LatLng center;
  final List<_MapPin> members;
  const _MapNode({required this.key, required this.center, required this.members});
}

enum _MapPinKind { memory, person, place }

class _MapPin {
  final String id;
  final String user;
  final String place;
  final String text;
  final double latitude;
  final double longitude;
  final IconData icon;
  final int likes;
  final int comments;
  final _MapPinKind kind;
  final Memory? memory;

  const _MapPin(this.id, this.user, this.place, this.text, this.latitude, this.longitude, this.icon, this.likes, this.comments, this.kind, {this.memory});

  factory _MapPin.fromMemory(Memory memory) => _MapPin(
        'real-${memory.id}',
        memory.ownerUsername?.trim().isNotEmpty == true ? memory.ownerUsername! : 'BEN',
        memory.title?.trim().isNotEmpty == true ? memory.title! : 'BEN Anısı',
        memory.hasText ? memory.text! : 'Bu konumda bir BEN anısı bıraktı.',
        memory.latitude!,
        memory.longitude!,
        memory.postType == 'story' ? Icons.auto_awesome_rounded : Icons.location_on_rounded,
        memory.isFavorite ? 1 : 0,
        0,
        _MapPinKind.memory,
        memory: memory,
      );
}

class _UserLocationMarker extends StatelessWidget {
  final double pulse;
  const _UserLocationMarker({required this.pulse});

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 28 + pulse * 6, height: 28 + pulse * 6, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .10 + pulse * .08))),
          Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan, border: Border.all(color: BenTokens.ink, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)])),
        ],
      );
}

class _MapNodeWidget extends StatelessWidget {
  final _MapNode node;
  final bool selected;
  final double pulse;
  final bool expanded;
  const _MapNodeWidget({required this.node, required this.selected, required this.pulse, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final count = node.members.length;
    if (count > 1) {
      final size = math.min(58.0, 38 + math.log(count + 1) * 7);
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(width: size + pulse * 5, height: size + pulse * 5, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .09))),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: BenTokens.ink.withValues(alpha: .94),
              shape: BoxShape.circle,
              border: Border.all(color: expanded ? BenTokens.cyanBright : BenTokens.cyan, width: 2.2),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Center(child: Text(_compact(count), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
        ],
      );
    }
    final pin = node.members.first;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (selected) Container(width: 58 + pulse * 8, height: 58 + pulse * 8, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .11))),
        Container(
          width: selected ? 52 : 44,
          height: selected ? 52 : 44,
          decoration: BoxDecoration(color: BenTokens.cyan, shape: BoxShape.circle, border: Border.all(color: BenTokens.ink, width: selected ? 3 : 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 5))]),
          child: Icon(pin.icon, color: BenTokens.ink, size: selected ? 25 : 20),
        ),
      ],
    );
  }

  String _compact(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    return '$value';
  }
}

class _MapHeader extends StatelessWidget {
  final int count;
  final int nearbyCount;
  final bool locating;
  final bool show3D;
  final VoidCallback onLocate;
  final VoidCallback onOpen3D;
  const _MapHeader({required this.count, required this.nearbyCount, required this.locating, required this.show3D, required this.onLocate, required this.onOpen3D});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MapGlass(
            child: Row(children: [
              const Icon(Icons.public_rounded, size: 20),
              const SizedBox(width: 8),
              Text('$count BEN izi', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              if (nearbyCount > 0) Text('$nearbyCount yakın', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: BenTokens.cyan)),
            ]),
          ),
        ),
        if (show3D) ...[
          const SizedBox(width: 8),
          Material(color: BenTokens.cyan.withValues(alpha: .96), shape: const CircleBorder(), child: IconButton(tooltip: '3D Dünya', onPressed: onOpen3D, icon: const Icon(Icons.threed_rotation_rounded, color: Color(0xFF061116)))),
        ],
        const SizedBox(width: 6),
        Material(color: Theme.of(context).colorScheme.surface.withValues(alpha: .94), shape: const CircleBorder(), child: IconButton(onPressed: locating ? null : onLocate, icon: locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded))),
      ],
    );
  }
}

class _MapGlass extends StatelessWidget {
  final Widget child;
  const _MapGlass({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .94), borderRadius: BorderRadius.circular(18), boxShadow: BenTokens.softShadow(Theme.of(context).brightness == Brightness.dark)),
        child: child,
      );
}

class _MapFilters extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _MapFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Tümü', 'Anı', 'İnsan', 'Mekân'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: selected == index ? BenTokens.gold : Theme.of(context).colorScheme.surface.withValues(alpha: .92), borderRadius: BorderRadius.circular(99), border: Border.all(color: selected == index ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: .35))),
            child: Center(child: Text(labels[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: selected == index ? BenTokens.ink : Theme.of(context).colorScheme.onSurface))),
          ),
        ),
      ),
    );
  }
}

class _ExploreChip extends StatelessWidget {
  final _MapPin? next;
  final VoidCallback onTap;
  const _ExploreChip({required this.next, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (next == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xEA081117), borderRadius: BorderRadius.circular(18), border: Border.all(color: BenTokens.cyan.withValues(alpha: .22)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.explore_rounded, color: BenTokens.cyan, size: 18), const SizedBox(width: 8), Text('Yakın keşif', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)), const SizedBox(width: 6), Text(next!.place, style: TextStyle(color: Colors.white.withValues(alpha: .58), fontWeight: FontWeight.w700, fontSize: 10))]),
      ),
    );
  }
}

class _ExploreBottomCard extends StatelessWidget {
  final int count;
  final _MapPin? suggestion;
  final VoidCallback onExplore;
  final VoidCallback onLocate;
  const _ExploreBottomCard({required this.count, required this.suggestion, required this.onExplore, required this.onLocate});

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: BenTokens.cyan.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.explore_rounded, color: BenTokens.cyan)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('BEN dünyasında dolaş', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), Text(suggestion == null ? '$count keşfedilebilir iz' : 'Sıradaki öneri: ${suggestion?.place ?? 'Yakındaki anı'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))])),
              IconButton(tooltip: 'Konumum', onPressed: onLocate, icon: const Icon(Icons.my_location_rounded)),
              FilledButton(onPressed: suggestion == null ? null : onExplore, style: FilledButton.styleFrom(backgroundColor: BenTokens.cyan, foregroundColor: BenTokens.ink), child: const Text('GEZ')),
            ],
          ),
        ),
      );
}

class _SelectedMapPinCard extends StatelessWidget {
  final _MapPin pin;
  final bool liked;
  final bool saved;
  final int commentCount;
  final double distanceKm;
  final bool hasPrevious;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComments;
  final VoidCallback onOpen;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _SelectedMapPinCard({required this.pin, required this.liked, required this.saved, required this.commentCount, required this.distanceKm, required this.hasPrevious, required this.onLike, required this.onSave, required this.onComments, required this.onOpen, required this.onNext, required this.onPrevious});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 10,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(children: [
            Row(children: [
              Container(width: 58, height: 58, decoration: BoxDecoration(color: BenTokens.navy, borderRadius: BorderRadius.circular(17)), child: Icon(pin.icon, color: BenTokens.cyan, size: 28)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pin.user, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text('📍 ${pin.place}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(pin.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: BenTokens.cyan.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.open_in_full_rounded, size: 17, color: BenTokens.cyan)),
            ]),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text('${distanceKm.toStringAsFixed(distanceKm < 1 ? 2 : 1)} km • anılar arasında keşif', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)))),
            const SizedBox(height: 7),
            Row(children: [
              IconButton(tooltip: 'Önceki anı', onPressed: hasPrevious ? onPrevious : null, icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(child: FilledButton.icon(onPressed: onNext, style: FilledButton.styleFrom(backgroundColor: BenTokens.cyan, foregroundColor: BenTokens.ink), icon: const Icon(Icons.explore_rounded, size: 18), label: const Text('SONRAKİ ANI'))),
              IconButton(tooltip: 'Yorumlar', onPressed: onComments, icon: const Icon(Icons.chat_bubble_outline_rounded)),
              IconButton(tooltip: saved ? 'Kaydedildi' : 'Kaydet', onPressed: onSave, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
              IconButton(tooltip: liked ? 'Beğenildi' : 'Beğen', onPressed: onLike, icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MapDemoSheet extends StatefulWidget {
  final _MapPin pin;
  final bool liked;
  final bool saved;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComments;
  const _MapDemoSheet({required this.pin, required this.liked, required this.saved, required this.commentCount, required this.onLike, required this.onSave, required this.onComments});
  @override
  State<_MapDemoSheet> createState() => _MapDemoSheetState();
}

class _MapDemoSheetState extends State<_MapDemoSheet> {
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .3), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Row(children: [Container(width: 50, height: 50, decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: Icon(widget.pin.icon, color: BenTokens.ink)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.pin.user, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(widget.pin.place, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700))]))]),
            const SizedBox(height: 20),
            Text(widget.pin.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
            const SizedBox(height: 14),
            Row(children: [_MapAction(icon: widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '${widget.pin.likes + (widget.liked ? 1 : 0)}', active: widget.liked, onTap: () { widget.onLike(); setState(() {}); }), _MapAction(icon: Icons.chat_bubble_outline_rounded, label: '${widget.commentCount}', onTap: widget.onComments), const Spacer(), _MapAction(icon: widget.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: 'Kaydet', active: widget.saved, onTap: () { widget.onSave(); setState(() {}); })]),
          ]),
        ),
      );
}

class _MapAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MapAction({required this.icon, required this.label, this.active = false, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Row(children: [Icon(icon, size: 17, color: active ? BenTokens.cyan : Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))])));
}
