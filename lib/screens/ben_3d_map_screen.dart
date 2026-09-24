import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/theme/app_tokens.dart';
import '../models/memory.dart';
import '../services/location_service.dart';
import 'memory_fullscreen_viewer.dart';

/// BEN WORLD V179 — Spatial Street Explorer.
///
/// Bu ekran mevcut 2D haritayı değiştirmez. MapLibre'ın gerçek vector-tile
/// bina/yol verisini yüksek pitch + street camera ile kullanır. Android/iOS
/// native MapLibre'da gerçek DEM terrain/street-photography desteği olmadığı
/// için burada sahte bir 3D dünya yerine dürüstçe "3D şehir + sokak kamerası"
/// deneyimi verilir.
class Ben3DMapScreen extends StatefulWidget {
  final List<Memory> memories;
  final bool embedded;

  const Ben3DMapScreen({super.key, required this.memories, this.embedded = false});

  @override
  State<Ben3DMapScreen> createState() => _Ben3DMapScreenState();
}

class _Ben3DMapScreenState extends State<Ben3DMapScreen>
    with SingleTickerProviderStateMixin {
  static const _style = 'https://tiles.openfreemap.org/styles/dark';
  static const _buildingsSource = 'ben-openfreemap-buildings';
  static const _buildingsLayer = 'ben-3d-buildings';
  static const _roadsLayer = 'ben-3d-roads';

  MapLibreMapController? _controller;
  bool _loading3D = false;
  bool _showMemoryLayer = true;
  final bool _cinematic = true;
  bool _streetMode = false;
  Memory? _selectedMemory;
  LatLng? _userLocation;
  final LocationService _locationService = LocationService();

  double _zoom = 15.2;
  double _bearing = 22;
  double _tilt = 58;
  LatLng _target = const LatLng(41.0082, 28.9784);

  late final AnimationController _pulseController;

  List<Memory> get _locatedMemories =>
      widget.memories.where((memory) => memory.hasLocation).toList();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final result = await _locationService.getCurrent(context, showFeedback: false);
    if (!mounted || result.snapshot == null) return;
    setState(() => _userLocation = LatLng(
      result.snapshot!.latLng.latitude,
      result.snapshot!.latLng.longitude,
    ));
    if (_locatedMemories.isEmpty && _controller != null) {
      await _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _userLocation!, zoom: 15.4, tilt: 58, bearing: 22)));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = _locatedMemories.firstOrNull;
    final center = first == null
        ? const LatLng(41.0082, 28.9784)
        : LatLng(first.latitude!, first.longitude!);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _zoom,
              tilt: _tilt,
              bearing: _bearing,
            ),
            styleString: _style,
            compassEnabled: false,
            trackCameraPosition: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            myLocationEnabled: false,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            onMapCreated: (controller) => _controller = controller,
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraMove: (position) {
              _zoom = position.zoom;
              _bearing = position.bearing;
              _tilt = position.tilt;
              _target = position.target;
            },
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _cinematic ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xC6000000),
                      Color(0x00000000),
                      Color(0x16000000),
                      Color(0xE3000000),
                    ],
                    stops: [0, .18, .62, 1],
                  ),
                ),
              ),
            ),
          ),
          if (!widget.embedded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    children: [
                      _GlassButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassHeader(
                          title: _streetMode ? 'BEN WORLD • STREET' : 'BEN WORLD',
                          subtitle: _streetMode
                              ? 'Sokak kamerası • yürüme modu • ${_locatedMemories.length} anı'
                              : '${_locatedMemories.length} anı • 3D şehir • keşif modu',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _GlassButton(
                        icon: _streetMode ? Icons.explore_rounded : Icons.directions_walk_rounded,
                        onTap: _toggleStreetMode,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 14,
              top: 12,
              child: SafeArea(
                bottom: false,
                child: _GlassHeader(
                  title: _streetMode ? 'STREET' : '3D WORLD',
                  subtitle: _streetMode ? 'Yürüme modu' : '${_locatedMemories.length} BEN anısı',
                ),
              ),
            ),
          Positioned(
            top: widget.embedded ? 82 : 108,
            right: 14,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _GlassButton(
                    icon: _showMemoryLayer
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    onTap: _toggleMemoryLayer,
                  ),
                  const SizedBox(height: 8),
                  _GlassButton(
                    icon: Icons.threed_rotation_rounded,
                    onTap: _resetPerspective,
                  ),
                  const SizedBox(height: 8),
                  _GlassButton(
                    icon: Icons.my_location_rounded,
                    onTap: _flyToFirstMemory,
                  ),
                ],
              ),
            ),
          ),
          if (_streetMode)
            Positioned(
              left: 16,
              bottom: 168,
              child: SafeArea(
                top: false,
                child: _WalkPad(
                  onForward: () => _walk(1),
                  onBack: () => _walk(-1),
                  onLeft: () => _turn(-22),
                  onRight: () => _turn(22),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 168,
            child: SafeArea(
              top: false,
              child: _ModeBadge(streetMode: _streetMode, zoom: _zoom),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _selectedMemory == null
                    ? _WorldHint(
                        key: const ValueKey('world-hint'),
                        onTap: _flyToFirstMemory,
                        count: _locatedMemories.length,
                      )
                    : _Memory3DCard(
                        key: ValueKey(_selectedMemory!.id),
                        memory: _selectedMemory!,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryFullscreenViewer(
                              memory: _selectedMemory!,
                              memories: widget.memories,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (_loading3D)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    setState(() => _loading3D = true);
    try {
      // iOS'ta MapLibre native tarafında özel vector-layer ifadeleri eski/özel
      // stillerle birlikte native crash üretebildiği için temel haritayı önce
      // güvenli şekilde gösteriyoruz. 0.27.1'in iOS crash düzeltmesiyle birlikte
      // BEN pin katmanı ayrıca yükleniyor. Android'de tam özel 3D katmanları koruyoruz.
      if (!Platform.isIOS) {
        await controller.addSource(
          _buildingsSource,
          const VectorSourceProperties(url: 'https://tiles.openfreemap.org/planet', attribution: '© OpenStreetMap contributors • OpenFreeMap'),
        );
        await controller.addFillExtrusionLayer(
          _buildingsSource,
          _buildingsLayer,
          const FillExtrusionLayerProperties(
            fillExtrusionColor: ['interpolate',['linear'],['coalesce',['get','render_height'],0],0,'#071114',12,'#0A1A1F',28,'#10282E',60,'#173C44'],
            fillExtrusionOpacity: .97,
            fillExtrusionHeight: ['coalesce',['get','render_height'],10],
            fillExtrusionBase: ['coalesce',['get','render_min_height'],0],
            fillExtrusionVerticalGradient: true,
          ), sourceLayer: 'building', minzoom: 13.8, enableInteraction: false,
        );
        try {
          await controller.addLineLayer(
            _buildingsSource, _roadsLayer,
            const LineLayerProperties(lineColor:'#2ED9D0',lineOpacity:.34,lineWidth:2.0,lineBlur:.15),
            sourceLayer:'transportation',minzoom:13,enableInteraction:false,
          );
        } catch (_) {}
      }
      await _addBenMemoryLayer(controller);
      if (!mounted) return;

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('3D şehir hazırlanamadı: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading3D = false);
    }
  }

  Future<void> _addBenMemoryLayer(MapLibreMapController controller) async {
    final located = _locatedMemories;
    if (located.isEmpty) return;

    try {
      final bytes = (await rootBundle.load('assets/branding/ben_master_logo.png'))
          .buffer
          .asUint8List();
      await controller.addImage('ben-master-marker', bytes);

      final options = located
          .map(
            (memory) => SymbolOptions(
              geometry: LatLng(memory.latitude!, memory.longitude!),
              iconImage: 'ben-master-marker',
              iconSize: .10,
              iconOpacity: .98,
              textField: memory.title?.trim().isNotEmpty == true
                  ? memory.title
                  : 'BEN',
              textSize: 9,
              textColor: '#FFFFFF',
              textHaloColor: '#061116',
              textHaloWidth: 1.6,
            ),
          )
          .toList();
      await controller.addSymbols(
        options,
        located.map((memory) => {'memoryId': memory.id}).toList(),
      );
      controller.onSymbolTapped.add(_onSymbolTapped);
      return;
    } catch (_) {
      final options = located
          .map(
            (memory) => CircleOptions(
              geometry: LatLng(memory.latitude!, memory.longitude!),
              circleRadius: 10,
              circleColor: '#19D9D1',
              circleOpacity: .95,
              circleStrokeColor: '#061116',
              circleStrokeWidth: 3,
              circleStrokeOpacity: 1,
            ),
          )
          .toList();
      await controller.addCircles(
        options,
        located.map((memory) => {'memoryId': memory.id}).toList(),
      );
      controller.onCircleTapped.add(_onCircleTapped);
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    final memoryId = symbol.data?['memoryId']?.toString();
    if (memoryId != null) _selectMemory(memoryId);
  }

  void _onCircleTapped(Circle circle) {
    final memoryId = circle.data?['memoryId']?.toString();
    if (memoryId != null) _selectMemory(memoryId);
  }

  void _selectMemory(String memoryId) {
    final memory = _locatedMemories.firstOrNullWhere((item) => item.id == memoryId);
    if (memory == null || !mounted) return;
    setState(() => _selectedMemory = memory);
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(memory.latitude!, memory.longitude!),
          zoom: _streetMode ? 18.7 : 17.3,
          tilt: _streetMode ? 74 : 62,
          bearing: _bearing,
        ),
      ),
      duration: const Duration(milliseconds: 1050),
    );
  }

  Future<void> _toggleStreetMode() async {
    final next = !_streetMode;
    setState(() => _streetMode = next);
    final controller = _controller;
    if (controller == null) return;

    final target = _selectedMemory == null
        ? _target
        : LatLng(_selectedMemory!.latitude!, _selectedMemory!.longitude!);

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: next ? math.max(_zoom, 18.4) : math.min(_zoom, 16.0),
          tilt: next ? 74 : 58,
          bearing: _bearing,
        ),
      ),
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _walk(int direction) async {
    final controller = _controller;
    if (controller == null) return;

    final current = await controller.queryCameraPosition() ??
        CameraPosition(target: _target, zoom: _zoom, tilt: _tilt, bearing: _bearing);
    final distanceMeters = direction * 12.0;
    final bearingRadians = current.bearing * math.pi / 180.0;
    final latRadians = current.target.latitude * math.pi / 180.0;
    final dLat = distanceMeters * math.cos(bearingRadians) / 111320.0;
    final dLon = distanceMeters * math.sin(bearingRadians) /
        (111320.0 * math.max(.2, math.cos(latRadians)));

    final target = LatLng(
      current.target.latitude + dLat,
      current.target.longitude + dLon,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: math.max(current.zoom, 18.4),
          tilt: math.max(current.tilt, 72),
          bearing: current.bearing,
        ),
      ),
      duration: const Duration(milliseconds: 420),
    );
  }

  Future<void> _turn(double degrees) async {
    final controller = _controller;
    if (controller == null) return;
    final current = await controller.queryCameraPosition() ??
        CameraPosition(target: _target, zoom: _zoom, tilt: _tilt, bearing: _bearing);
    final bearing = (current.bearing + degrees) % 360;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: current.target,
          zoom: math.max(current.zoom, 18.4),
          tilt: math.max(current.tilt, 72),
          bearing: bearing < 0 ? bearing + 360 : bearing,
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _toggleMemoryLayer() async {
    setState(() => _showMemoryLayer = !_showMemoryLayer);
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setLayerVisibility('ben-master-marker-layer', _showMemoryLayer);
    } catch (_) {
      // Annotation API symbols are not always addressable by style layer id;
      // fallback is to leave the existing annotations untouched.
    }
  }

  Future<void> _resetPerspective() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _streetMode = false);
    final first = _selectedMemory ?? _locatedMemories.firstOrNull;
    final target = first == null
        ? const LatLng(41.0082, 28.9784)
        : LatLng(first.latitude!, first.longitude!);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.2, tilt: 58, bearing: 22),
      ),
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _flyToFirstMemory() async {
    final controller = _controller;
    if (controller == null) return;
    if (_userLocation != null) {
      await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _userLocation!, zoom: 16.2, tilt: 60, bearing: _bearing)), duration: const Duration(milliseconds: 800));
      return;
    }
    final first = _locatedMemories.firstOrNull;
    if (first != null) _selectMemory(first.id);
  }
}

class _GlassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _GlassHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xED081117),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: BenTokens.cyan.withValues(alpha: .24)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: .8)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .62))),
          ],
        ),
      );
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xEE081117),
        shape: const CircleBorder(),
        elevation: 8,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: BenTokens.cyan, size: 22),
          ),
        ),
      );
}

class _ModeBadge extends StatelessWidget {
  final bool streetMode;
  final double zoom;
  const _ModeBadge({required this.streetMode, required this.zoom});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xD9081117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BenTokens.cyan.withValues(alpha: .20)),
        ),
        child: Text(
          streetMode ? 'SOKAK • ${zoom.toStringAsFixed(1)}x' : '3D • ${zoom.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .4),
        ),
      );
}

class _WalkPad extends StatelessWidget {
  final VoidCallback onForward;
  final VoidCallback onBack;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _WalkPad({required this.onForward, required this.onBack, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) => Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: const Color(0xCC081117),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _WalkButton(icon: Icons.keyboard_arrow_up_rounded, onTap: onForward, top: 5, left: 42),
            _WalkButton(icon: Icons.keyboard_arrow_down_rounded, onTap: onBack, bottom: 5, left: 42),
            _WalkButton(icon: Icons.keyboard_arrow_left_rounded, onTap: onLeft, left: 5, top: 42),
            _WalkButton(icon: Icons.keyboard_arrow_right_rounded, onTap: onRight, right: 5, top: 42),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .14), border: Border.all(color: BenTokens.cyan.withValues(alpha: .30))),
              child: const Icon(Icons.person_pin_circle_rounded, color: BenTokens.cyan, size: 20),
            ),
          ],
        ),
      );
}

class _WalkButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double? top, left, right, bottom;
  const _WalkButton({required this.icon, required this.onTap, this.top, this.left, this.right, this.bottom});

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: Material(
          color: const Color(0xEE12232A),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white, size: 25)),
          ),
        ),
      );
}

class _WorldHint extends StatelessWidget {
  final VoidCallback onTap;
  final int count;
  const _WorldHint({super.key, required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xE6091117),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: BenTokens.cyan.withValues(alpha: .12), border: Border.all(color: BenTokens.cyan.withValues(alpha: .32))),
                  child: const Icon(Icons.explore_rounded, color: BenTokens.cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BEN izlerini keşfet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text('$count konumlu anı • sokak seviyesine yaklaş', style: TextStyle(color: Colors.white.withValues(alpha: .60), fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: BenTokens.cyan),
              ],
            ),
          ),
        ),
      );
}

class _Memory3DCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onOpen;
  const _Memory3DCard({super.key, required this.memory, required this.onOpen});

  String get _kindLabel {
    switch (memory.type) {
      case MemoryType.photo:
        return 'FOTOĞRAF';
      case MemoryType.video:
        return 'VİDEO';
      case MemoryType.text:
        return 'YAZI';
      case MemoryType.music:
        return 'MÜZİK';
      case MemoryType.location:
        return 'KONUM';
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xF20A1218),
        borderRadius: BorderRadius.circular(25),
        elevation: 18,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _MemoryThumb(memory: memory),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: BenTokens.cyan.withValues(alpha: .13), borderRadius: BorderRadius.circular(7), border: Border.all(color: BenTokens.cyan.withValues(alpha: .16))),
                            child: Text(_kindLabel, style: const TextStyle(color: BenTokens.cyan, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .5)),
                          ),
                          const SizedBox(width: 6),
                          const Text('BEN WORLD', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          const Icon(Icons.open_in_full_rounded, color: BenTokens.cyan, size: 17),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(memory.title ?? 'BEN Anısı', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(memory.hasText ? memory.text! : 'Bu konumda bırakılmış bir BEN anısı.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 11, fontWeight: FontWeight.w600, height: 1.25)),
                      const SizedBox(height: 9),
                      const Row(
                        children: [
                          Icon(Icons.favorite_rounded, color: Colors.white70, size: 13),
                          SizedBox(width: 4),
                          Text('Beğen', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800)),
                          SizedBox(width: 12),
                          Icon(Icons.chat_bubble_rounded, color: Colors.white70, size: 13),
                          SizedBox(width: 4),
                          Text('Yorum', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800)),
                          SizedBox(width: 12),
                          Icon(Icons.bookmark_rounded, color: Colors.white70, size: 13),
                          SizedBox(width: 4),
                          Text('Kaydet', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MemoryThumb extends StatelessWidget {
  final Memory memory;
  const _MemoryThumb({required this.memory});

  @override
  Widget build(BuildContext context) {
    if (memory.hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(memory.photo!, width: 78, height: 92, fit: BoxFit.cover, filterQuality: FilterQuality.high),
      );
    }
    return Container(
      width: 78,
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [BenTokens.cyan.withValues(alpha: .24), const Color(0xFF10242C)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BenTokens.cyan.withValues(alpha: .18)),
      ),
      child: Icon(memory.type == MemoryType.video ? Icons.play_circle_fill_rounded : Icons.auto_awesome_rounded, color: BenTokens.cyan, size: 30),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstOrNullWhere(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
