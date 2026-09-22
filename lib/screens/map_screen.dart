import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_tokens.dart';
import '../core/navigation/ben_routes.dart';
import 'memory_fullscreen_viewer.dart';
import 'ben_3d_map_screen.dart';
import '../models/memory.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  final List<Memory> memories;

  const MapScreen({super.key, required this.memories});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  final MapController _controller = MapController();
  final LocationService _locationService = LocationService();
  late final AnimationController _pulse;
  late final AnimationController _fan;
  String? _expandedPinId;
  bool _mapReady = false;

  int _filter = 0;
  _MapPin? _selectedPin;
  LatLng _center = const LatLng(41.0082, 28.9784);
  bool _locating = false;
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
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fan = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fan.addListener(() { if (mounted) setState(() {}); });
    _loadSocialState();
    final first = widget.memories.where((m) => m.hasLocation).firstOrNull;
    if (first != null) _center = LatLng(first.latitude!, first.longitude!);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fan.dispose();
    super.dispose();
  }

  List<_MapPin> get _pins {
    final real = widget.memories.where((m) => m.hasLocation).map(_MapPin.fromMemory);
    final demo = _demoPins.where((p) {
      if (_filter == 1) return p.kind == _MapPinKind.memory;
      if (_filter == 2) return p.kind == _MapPinKind.person;
      if (_filter == 3) return p.kind == _MapPinKind.place;
      return true;
    });
    return [...real, ...demo];
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pins = _pins;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 11.2,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            onMapReady: () => _mapReady = true,
            onTap: (_, _) {
              if (!mounted) return;
              setState(() {
                _selectedPin = null;
                _expandedPinId = null;
                _fan.reverse();
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
            MarkerLayer(
              markers: pins.map((pin) {
                final selected = pin.id == _selectedPin?.id;
                final expanded = _expandedPinId != null;
                final cluster = expanded ? _clusterMembers(pins, _expandedPinId!) : const <_MapPin>[];
                final memberIndex = cluster.indexWhere((p) => p.id == pin.id);
                final point = memberIndex >= 0
                    ? _fanPoint(pin, memberIndex, cluster.length, _fan.value)
                    : LatLng(pin.latitude, pin.longitude);
                return Marker(
                  point: point,
                  width: selected ? 92 : 66,
                  height: selected ? 92 : 66,
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (memberIndex >= 0 && cluster.length > 1) {
                        _selectPin(pin);
                      } else {
                        _expandCluster(pin, pins);
                      }
                    },
                    onLongPressMoveUpdate: (details) {
                      if (cluster.isEmpty) return;
                      final candidates = cluster;
                      final dx = details.offsetFromOrigin.dx;
                      final dy = details.offsetFromOrigin.dy;
                      final target = Offset(dx, dy);
                      var best = candidates.first;
                      var bestDistance = double.infinity;
                      for (var i = 0; i < candidates.length; i++) {
                        final angle = -math.pi / 2 + (2 * math.pi * i / candidates.length);
                        final candidate = Offset(math.cos(angle) * 90, math.sin(angle) * 90);
                        final distance = (candidate - target).distance;
                        if (distance < bestDistance) { bestDistance = distance; best = candidates[i]; }
                      }
                      if (best.id != _selectedPin?.id) _selectPin(best);
                    },
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => _MapPinWidget(pin: pin, selected: selected, pulse: _pulse.value, emphasized: memberIndex >= 0 && expanded),
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
                  locating: _locating,
                  onLocate: _locateMe,
                  onOpen3D: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Ben3DMapScreen(memories: widget.memories),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                _MapFilters(selected: _filter, onChanged: (value) => setState(() { _filter = value; _selectedPin = null; })),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: SafeArea(
            top: false,
            child: _selectedPin == null
                ? _MapLiveStrip(count: pins.length, onTap: () => _selectPin(pins.first))
                : _SelectedMapPinCard(
                    pin: _selectedPin!,
                    liked: _liked.contains(_selectedPin!.id),
                    saved: _saved.contains(_selectedPin!.id),
                    commentCount: _commentCount(_selectedPin!),
                    onLike: () => _toggleLike(_selectedPin!),
                    onSave: () => _toggleSave(_selectedPin!),
                    onComments: () => _showComments(_selectedPin!),
                    onOpen: () => _openPin(_selectedPin!),
                  ),
          ),
        ),
      ],
    );
  }

  int _commentCount(_MapPin pin) => pin.comments + (_comments[pin.id]?.length ?? 0);

  Future<void> _loadSocialState() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('ben_map_liked_memories') ?? const <String>[];
    final saved = prefs.getStringList('ben_map_saved_memories') ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _liked.addAll(liked);
      _saved.addAll(saved);
    });
  }

  Future<void> _persistMapSocial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ben_map_liked_memories', _liked.toList());
    await prefs.setStringList('ben_map_saved_memories', _saved.toList());
  }

  void _toggleLike(_MapPin pin) {
    setState(() {
      if (!_liked.add(pin.id)) _liked.remove(pin.id);
    });
    _persistMapSocial();
  }

  void _toggleSave(_MapPin pin) {
    setState(() {
      if (!_saved.add(pin.id)) _saved.remove(pin.id);
    });
    _persistMapSocial();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_saved.contains(pin.id) ? 'BEN izi kaydedildi.' : 'BEN izi kayıtlardan çıkarıldı.')),
    );
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

  List<_MapPin> _clusterMembers(List<_MapPin> pins, String anchorId) {
    final anchor = pins.where((p) => p.id == anchorId).firstOrNull;
    if (anchor == null) return const [];
    final members = pins.where((pin) {
      final dLat = pin.latitude - anchor.latitude;
      final dLon = pin.longitude - anchor.longitude;
      return (dLat * dLat + dLon * dLon) <= 0.00055;
    }).toList();
    return members.isEmpty ? [anchor] : members;
  }

  LatLng _fanPoint(_MapPin pin, int index, int count, double t) {
    if (count <= 1) return LatLng(pin.latitude, pin.longitude);
    final ring = index < 5 ? 0.0062 : 0.0035;
    final actualIndex = index % 5;
    final a = -math.pi / 2 + (2 * math.pi * actualIndex / 5);
    final targetLat = pin.latitude + math.sin(a) * ring;
    final targetLon = pin.longitude + math.cos(a) * ring;
    final anchor = _expandedPinId == null ? pin : _clusterMembers(_pins, _expandedPinId!).firstOrNull ?? pin;
    return LatLng(
      anchor.latitude + (targetLat - anchor.latitude) * t,
      anchor.longitude + (targetLon - anchor.longitude) * t,
    );
  }

  void _expandCluster(_MapPin pin, List<_MapPin> pins) {
    final members = _clusterMembers(pins, pin.id);
    if (members.length <= 1) {
      _selectPin(pin);
      return;
    }
    setState(() {
      _expandedPinId = pin.id;
      _selectedPin = null;
    });
    _fan.forward(from: 0);
  }

  void _selectPin(_MapPin pin) {
    if (!mounted) return;
    setState(() => _selectedPin = pin);
    if (_mapReady) {
      _controller.move(LatLng(pin.latitude, pin.longitude), 15.8);
    }
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    final point = await _locationService.getCurrentLatLng(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null) _center = point;
    });
    if (point != null && _mapReady) _controller.move(point, 15.5);
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
        'Bican',
        memory.title ?? 'BEN Anısı',
        memory.hasText ? memory.text! : 'Bu konumda bir anı bıraktım.',
        memory.latitude!,
        memory.longitude!,
        Icons.location_on_rounded,
        memory.isFavorite ? 1 : 0,
        0,
        _MapPinKind.memory,
        memory: memory,
      );
}

class _MapHeader extends StatelessWidget {
  final int count;
  final bool locating;
  final VoidCallback onLocate;
  final VoidCallback onOpen3D;

  const _MapHeader({required this.count, required this.locating, required this.onLocate, required this.onOpen3D});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MapGlass(
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 20),
                const SizedBox(width: 8),
                Text('$count BEN izi', style: const TextStyle(fontWeight: FontWeight.w900)),
                const Spacer(),
                const Text('CANLI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Color(0xFF2EDB8C))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: BenTokens.cyan.withValues(alpha: .96),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: '3D Dünya',
            onPressed: onOpen3D,
            icon: const Icon(Icons.threed_rotation_rounded, color: Color(0xFF061116)),
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: locating ? null : onLocate,
            icon: locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
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
            decoration: BoxDecoration(
              color: selected == index ? BenTokens.gold : Theme.of(context).colorScheme.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected == index ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: .35)),
            ),
            child: Center(child: Text(labels[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: selected == index ? BenTokens.ink : Theme.of(context).colorScheme.onSurface))),
          ),
        ),
      ),
    );
  }
}

class _MapGlass extends StatelessWidget {
  final Widget child;
  const _MapGlass({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: BenTokens.softShadow(Theme.of(context).brightness == Brightness.dark),
        ),
        child: child,
      );
}

class _MapPinWidget extends StatelessWidget {
  final _MapPin pin;
  final bool selected;
  final double pulse;
  final bool emphasized;
  const _MapPinWidget({required this.pin, required this.selected, required this.pulse, this.emphasized = false});

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          if (selected) Container(width: 58 + pulse * 12, height: 58 + pulse * 12, decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.gold.withValues(alpha: .10 + pulse * .08))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 58 : (emphasized ? 50 : 46),
            height: selected ? 58 : (emphasized ? 50 : 46),
            decoration: BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle, border: Border.all(color: BenTokens.ink, width: selected ? 3 : 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 6))]),
            child: Icon(pin.icon, color: BenTokens.ink, size: selected ? 28 : (emphasized ? 24 : 21)),
          ),
        ],
      );
}

class _MapLiveStrip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MapLiveStrip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: _MapGlass(
          child: Row(
            children: [
              Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF2EDB8C), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Şehirde yeni BEN izleri var.', style: TextStyle(fontWeight: FontWeight.w800))),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 7),
              const Icon(Icons.arrow_forward_ios_rounded, size: 13),
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
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComments;
  final VoidCallback onOpen;

  const _SelectedMapPinCard({required this.pin, required this.liked, required this.saved, required this.commentCount, required this.onLike, required this.onSave, required this.onComments, required this.onOpen});

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
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 62, height: 62, decoration: BoxDecoration(color: BenTokens.navy, borderRadius: BorderRadius.circular(18)), child: Icon(pin.icon, color: BenTokens.gold, size: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pin.user, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('📍 ${pin.place}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(pin.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: BenTokens.cyan.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fullscreen_rounded, size: 18, color: BenTokens.cyan),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Anıyı görmek için karta dokun',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .48),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
              children: [
                _MapAction(icon: liked ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, label: '${pin.likes + (liked ? 1 : 0)}', active: liked, onTap: onLike),
                _MapAction(icon: Icons.edit_rounded, label: '$commentCount', onTap: onComments),
                const Spacer(),
                _MapAction(icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: 'Kaydet', active: saved, onTap: onSave),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MapAction({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(children: [Icon(icon, size: 17, color: active ? BenTokens.gold : Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
        ),
      );
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .3), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(width: 50, height: 50, decoration: const BoxDecoration(color: BenTokens.gold, shape: BoxShape.circle), child: Icon(widget.pin.icon, color: BenTokens.ink)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.pin.user, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(widget.pin.place, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700))]),
              ],
            ),
            const SizedBox(height: 20),
            Text(widget.pin.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
            const SizedBox(height: 14),
            Row(
              children: [
                _MapAction(icon: widget.liked ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, label: '${widget.pin.likes + (widget.liked ? 1 : 0)}', active: widget.liked, onTap: () { widget.onLike(); setState(() {}); }),
                _MapAction(icon: Icons.edit_rounded, label: '${widget.commentCount}', onTap: widget.onComments),
                const Spacer(),
                _MapAction(icon: widget.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: 'Kaydet', active: widget.saved, onTap: () { widget.onSave(); setState(() {}); }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
