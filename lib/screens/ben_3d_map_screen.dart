import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/theme/app_tokens.dart';
import '../models/memory.dart';
import '../services/location_service.dart';
import 'memory_fullscreen_viewer.dart';

/// BEN WORLD V191 — Premium spatial memory explorer.
///
/// Bu ekran mevcut 2D haritayı değiştirmez. MapLibre'ın gerçek vector-tile
/// bina/yol verisini yüksek pitch + street camera ile kullanır. Android/iOS
/// native MapLibre'da gerçek DEM terrain/street-photography desteği olmadığı
/// için burada sahte bir 3D dünya yerine dürüstçe "3D şehir + sokak kamerası"
/// deneyimi verilir.
class Ben3DMapScreen extends StatefulWidget {
  final List<Memory> memories;
  final bool embedded;
  final Memory? focusMemory;

  const Ben3DMapScreen({super.key, required this.memories, this.embedded = false, this.focusMemory});

  @override
  State<Ben3DMapScreen> createState() => _Ben3DMapScreenState();
}

class _Ben3DMapScreenState extends State<Ben3DMapScreen>
    with SingleTickerProviderStateMixin {
  static const _style = 'https://tiles.openfreemap.org/styles/dark';
  static const _buildingsLayer = 'ben-3d-buildings';
  static const _memorySource = 'ben-memory-source';
  static const _clusterLayer = 'ben-memory-clusters';
  static const _clusterCountLayer = 'ben-memory-cluster-count';
  static const _memoryPointLayer = 'ben-memory-points';

  MapLibreMapController? _controller;
  bool _loading3D = false;
  bool _showMemoryLayer = true;
  final bool _cinematic = true;
  bool _streetMode = false;
  Memory? _selectedMemory;
  LatLng? _userLocation;
  LatLng? _initialCenter;
  bool _initialCenterReady = false;
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
    _prepareInitialCamera();
  }

  Future<void> _prepareInitialCamera() async {
    final focused = widget.focusMemory;
    if (focused?.hasLocation == true) {
      _initialCenter = LatLng(focused!.latitude!, focused.longitude!);
      _initialCenterReady = true;
      if (mounted) setState(() {});
      return;
    }

    // Do not create the native map over an arbitrary/sea coordinate.
    // Resolve the best available location first, then create MapLibre once.
    try {
      final result = await _locationService.getCurrent(context, showFeedback: false);
      if (result.snapshot != null) {
        final point = LatLng(
          result.snapshot!.latLng.latitude,
          result.snapshot!.latLng.longitude,
        );
        _userLocation = point;
        _initialCenter = point;
      }
    } catch (_) {}

    if (_initialCenter == null) {
      final first = _locatedMemories.firstOrNull;
      _initialCenter = first == null
          ? const LatLng(41.0082, 28.9784)
          : LatLng(first.latitude!, first.longitude!);
    }

    _initialCenterReady = true;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant Ben3DMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.focusMemory;
    if (next != null && next.id != oldWidget.focusMemory?.id && next.hasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectMemory(next.id);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _initialCenter ?? const LatLng(41.0082, 28.9784);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_initialCenterReady)
            const Center(
              child: CircularProgressIndicator(color: BenTokens.cyan),
            )
          else
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
            featureTapsTriggersMapClick: true,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapClick,
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
      // Android: restore the proven V186 OpenFreeMap planet source for
      // extrusion/road layers. iOS keeps the provider's native style layers
      // only; this avoids re-introducing the native MapLibre crash while the
      // map is now lazily mounted.
      if (!Platform.isIOS) {
        try {
          await controller.addSource(
            'ben-openfreemap-buildings',
            const VectorSourceProperties(
              url: 'https://tiles.openfreemap.org/planet',
              attribution: '© OpenStreetMap contributors • OpenFreeMap',
            ),
          );
        } catch (_) {
          // The style may already expose the source.
        }
        try {
          await controller.addFillExtrusionLayer(
            'ben-openfreemap-buildings',
            _buildingsLayer,
            const FillExtrusionLayerProperties(
              fillExtrusionColor: [
                'interpolate', ['linear'],
                ['coalesce', ['get', 'render_height'], 0],
                0, '#071114',
                12, '#0A1A1F',
                28, '#10282E',
                60, '#173C44',
              ],
              fillExtrusionOpacity: .97,
              fillExtrusionHeight: ['coalesce', ['get', 'render_height'], 10],
              fillExtrusionBase: ['coalesce', ['get', 'render_min_height'], 0],
              fillExtrusionVerticalGradient: true,
            ),
            sourceLayer: 'building',
            minzoom: 13.8,
            enableInteraction: false,
          );
        } catch (_) {}
        try {
          await controller.addLineLayer(
            'ben-openfreemap-buildings',
            'ben-3d-roads',
            const LineLayerProperties(
              lineColor: '#2ED9D0',
              lineOpacity: .34,
              lineWidth: 2.0,
              lineBlur: .15,
            ),
            sourceLayer: 'transportation',
            minzoom: 13,
            enableInteraction: false,
          );
        } catch (_) {}
        try {
          await controller.addLineLayer(
            'ben-openfreemap-buildings',
            'ben-building-edges',
            const LineLayerProperties(
              lineColor: '#36E5DE',
              lineOpacity: .16,
              lineWidth: 1.0,
              lineBlur: .25,
            ),
            sourceLayer: 'building',
            minzoom: 14.8,
            enableInteraction: false,
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

    final featureCollection = <String, dynamic>{
      'type': 'FeatureCollection',
      'features': located.map((memory) {
        return <String, dynamic>{
          'type': 'Feature',
          'id': memory.id,
          'geometry': <String, dynamic>{
            'type': 'Point',
            'coordinates': <double>[memory.longitude!, memory.latitude!],
          },
          'properties': <String, dynamic>{
            'memoryId': memory.id,
            'title': memory.title?.trim().isNotEmpty == true ? memory.title : 'BEN',
          },
        };
      }).toList(),
    };

    try {
      await controller.addSource(
        _memorySource,
        GeojsonSourceProperties(
          data: featureCollection,
          cluster: true,
          clusterRadius: 58,
          clusterMaxZoom: 15.5,
          clusterMinPoints: 2,
          generateId: true,
        ),
      );
    } catch (_) {
      try {
        await controller.setGeoJsonSource(_memorySource, featureCollection);
      } catch (_) {}
    }

    // Cluster bubbles: compact at city scale, larger when a dense memory pocket
    // contains many points. This is native MapLibre clustering, not a Flutter
    // overlay, so Android and iOS use the same spatial calculation.
    try {
      await controller.addCircleLayer(
        _memorySource,
        _clusterLayer,
        const CircleLayerProperties(
          circleRadius: [
            'step',
            ['get', 'point_count'],
            18,
            8, 22,
            25, 27,
            60, 33,
          ],
          circleColor: '#08D9D2',
          circleOpacity: .94,
          circleStrokeColor: '#B9FFFC',
          circleStrokeWidth: 2.0,
          circleStrokeOpacity: .72,
        ),
        filter: ['has', 'point_count'],
      );
      await controller.addSymbolLayer(
        _memorySource,
        _clusterCountLayer,
        const SymbolLayerProperties(
          textField: [Expressions.get, 'point_count_abbreviated'],
          textSize: 12.5,
          textColor: '#031014',
          textHaloColor: '#B9FFFC',
          textHaloWidth: .5,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        filter: ['has', 'point_count'],
      );
    } catch (_) {}

    // Individual BEN points appear only after the cluster has expanded.
    try {
      final bytes = (await rootBundle.load('assets/branding/ben_master_logo.png'))
          .buffer
          .asUint8List();
      await controller.addImage('ben-master-marker', bytes);
      await controller.addSymbolLayer(
        _memorySource,
        _memoryPointLayer,
        const SymbolLayerProperties(
          iconImage: 'ben-master-marker',
          iconSize: .105,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textField: [Expressions.get, 'title'],
          textSize: 8.5,
          textColor: '#FFFFFF',
          textHaloColor: '#061116',
          textHaloWidth: 1.5,
          textOffset: [0, 1.7],
          textAllowOverlap: false,
          textOptional: true,
        ),
        filter: ['!', ['has', 'point_count']],
      );
    } catch (_) {
      try {
        await controller.addCircleLayer(
          _memorySource,
          _memoryPointLayer,
          const CircleLayerProperties(
            circleRadius: 8,
            circleColor: '#19D9D1',
            circleOpacity: .96,
            circleStrokeColor: '#B9FFFC',
            circleStrokeWidth: 2,
          ),
          filter: ['!', ['has', 'point_count']],
        );
      } catch (_) {}
    }
  }

  Future<void> _onMapClick(math.Point<double> point, LatLng coordinates) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final features = await controller.queryRenderedFeatures(
        point,
        [_clusterLayer, _memoryPointLayer],
        null,
      );
      if (features.isEmpty) return;
      final feature = features.first;
      final properties = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (properties.containsKey('cluster_id')) {
        final clusterId = (properties['cluster_id'] as num?)?.toInt();
        if (clusterId == null) return;
        final zoom = await controller.getClusterExpansionZoom(_memorySource, clusterId);
        final geometry = feature['geometry'];
        if (geometry is Map && geometry['coordinates'] is List) {
          final coords = geometry['coordinates'] as List;
          if (coords.length >= 2) {
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
                zoom.toDouble(),
              ),
              duration: const Duration(milliseconds: 650),
            );
          }
        }
        return;
      }
      final memoryId = properties['memoryId']?.toString();
      if (memoryId != null) _selectMemory(memoryId);
    } catch (_) {}
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
    final target = _userLocation ?? (first == null
        ? const LatLng(41.0082, 28.9784)
        : LatLng(first.latitude!, first.longitude!));
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
