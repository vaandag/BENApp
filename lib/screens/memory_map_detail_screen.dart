import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';

import '../models/memory.dart';
import '../services/memory_repository.dart';
import '../core/navigation/ben_routes.dart';

class MemoryMapDetailScreen extends StatefulWidget {
  final Memory memory;
  final List<Memory> memories;

  const MemoryMapDetailScreen({
    super.key,
    required this.memory,
    required this.memories,
  });

  @override
  State<MemoryMapDetailScreen> createState() =>
      _MemoryMapDetailScreenState();
}

class _MemoryMapDetailScreenState
    extends State<MemoryMapDetailScreen> {
  final MapController _mapController =
      MapController();

  final MemoryRepository _repository =
      MemoryRepository();

  late Memory _memory;

  VideoPlayerController? _videoController;


  @override
  void initState() {
    super.initState();

    _memory = widget.memory;

    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    if (_memory.video == null ||
        _memory.video!.isEmpty) {
      return;
    }

    try {
      final videoPath = _memory.video!;
      final file = File(videoPath);
      final controller = file.existsSync()
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(videoPath));

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController =
            controller;
      });
    } catch (_) {
      // Video yüklenemezse harita ve
      // anı ekranı çalışmaya devam eder.
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    await _repository.toggleFavorite(
      _memory.id,
    );

    final updated =
        await _repository.getById(
      _memory.id,
    );

    if (!mounted ||
        updated == null) {
      return;
    }

    setState(() {
      _memory = updated;
    });
  }

  Future<void> _togglePinned() async {
    await _repository.togglePinned(
      _memory.id,
    );

    final updated =
        await _repository.getById(
      _memory.id,
    );

    if (!mounted ||
        updated == null) {
      return;
    }

    setState(() {
      _memory = updated;
    });
  }

  void _flyToMemory(
    Memory memory,
  ) {
    if (!memory.hasLocation) {
      return;
    }

    _mapController.move(
      LatLng(
        memory.latitude!,
        memory.longitude!,
      ),
      17.5,
    );

    setState(() {
      _memory = memory;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_memory.hasLocation) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Anı'),
        ),
        body: const Center(
          child: Text(
            'Bu anının kayıtlı bir konumu yok.',
          ),
        ),
      );
    }

    final center = LatLng(
      _memory.latitude!,
      _memory.longitude!,
    );

    final locatedMemories =
        widget.memories
            .where(
              (memory) =>
                  memory.hasLocation,
            )
            .toList();

    return Scaffold(
      backgroundColor:
          const Color(0xFF0B1118),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController:
                  _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 17.5,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions:
                    const InteractionOptions(
                  flags:
                      InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  // BEN harita deneyiminde konum detayı da ana harita ile
                  // aynı koyu görsel dilde kalır. Açık OSM katmanına düşmez.
                  urlTemplate:
                      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName:
                      'com.benapp.mobile',
                ),

                // Haritaya hafif bir "derinlik"
                // hissi veren gölge katmanı.
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors © CARTO',
                    ),
                  ],
                ),

                MarkerLayer(
                  markers:
                      locatedMemories.map(
                    (memory) {
                      final selected =
                          memory.id ==
                              _memory.id;

                      return Marker(
                        point: LatLng(
                          memory.latitude!,
                          memory.longitude!,
                        ),
                        width: selected
                            ? 110
                            : 64,
                        height: selected
                            ? 110
                            : 64,
                        child:
                            GestureDetector(
                          onTap: () =>
                              _flyToMemory(
                            memory,
                          ),
                          child:
                              _MemoryMapMarker(
                            memory: memory,
                            selected:
                                selected,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),

          // Üst gradient / geri butonu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                child: Row(
                  children: [
                    _GlassButton(
                      icon: Icons
                          .arrow_back_rounded,
                      onTap: () =>
                          Navigator.pop(
                        context,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Text(
                        'Anının konumu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color:
                                  Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _GlassButton(
                      icon: Icons
                          .my_location_rounded,
                      onTap: () =>
                          _flyToMemory(
                        _memory,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt anı paneli
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _MemoryBottomSheet(
                memory: _memory,
                videoController:
                    _videoController,
                onFavorite:
                    _toggleFavorite,
                onPinned:
                    _togglePinned,
                onComments: () {
                  BenRoutes.openComments(
                    context,
                    memoryId: int.tryParse(_memory.id),
                    memoryKey: _memory.id,
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

class _MemoryMapMarker
    extends StatelessWidget {
  final Memory memory;
  final bool selected;

  const _MemoryMapMarker({
    required this.memory,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1 : .82,
      duration:
          const Duration(milliseconds: 220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 76 : 48,
            height: selected ? 76 : 48,
            padding:
                const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    const Color(0xFF172033),
                width: selected ? 3 : 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: memory.photo != null
                  ? Image.file(
                      memory.photo!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color:
                          const Color(
                        0xFF172033,
                      ),
                      child: Icon(
                        _typeIcon(
                          memory.type,
                        ),
                        color: Colors.white,
                        size: selected
                            ? 30
                            : 22,
                      ),
                    ),
            ),
          ),
          if (selected)
            Container(
              width: 3,
              height: 18,
              color:
                  const Color(0xFF172033),
            ),
          if (selected)
            Container(
              width: 9,
              height: 9,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF172033),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return Icons.photo_rounded;
      case MemoryType.text:
        return Icons.edit_rounded;
      case MemoryType.video:
        return Icons.videocam_rounded;
      case MemoryType.music:
        return Icons.music_note_rounded;
      case MemoryType.location:
        return Icons.location_on_rounded;
    }
  }
}

class _MemoryBottomSheet
    extends StatelessWidget {
  final Memory memory;
  final VideoPlayerController?
      videoController;
  final VoidCallback onFavorite;
  final VoidCallback onPinned;
  final VoidCallback onComments;

  const _MemoryBottomSheet({
    required this.memory,
    required this.videoController,
    required this.onFavorite,
    required this.onPinned,
    required this.onComments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: .97,
        ),
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Preview(
            memory: memory,
            videoController:
                videoController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  memory.title ??
                      _typeTitle(
                        memory.type,
                      ),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${memory.createdAt.day.toString().padLeft(2, '0')}.'
                '${memory.createdAt.month.toString().padLeft(2, '0')}.'
                '${memory.createdAt.year}',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (memory.hasText) ...[
            const SizedBox(height: 7),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                memory.text!,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionButton(
                icon: memory.isFavorite
                    ? Icons
                        .favorite_rounded
                    : Icons
                        .favorite_border_rounded,
                label: 'Beğen',
                active:
                    memory.isFavorite,
                onTap: onFavorite,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons
                    .chat_bubble_outline_rounded,
                label: 'Yorum',
                onTap: onComments,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: memory.isPinned
                    ? Icons
                        .push_pin_rounded
                    : Icons
                        .push_pin_outlined,
                label: 'Sabitle',
                active:
                    memory.isPinned,
                onTap: onPinned,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeTitle(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf anısı';
      case MemoryType.text:
        return 'Yazı anısı';
      case MemoryType.video:
        return 'Video anısı';
      case MemoryType.music:
        return 'Müzik anısı';
      case MemoryType.location:
        return 'Konum anısı';
    }
  }
}

class _Preview
    extends StatelessWidget {
  final Memory memory;
  final VideoPlayerController?
      videoController;

  const _Preview({
    required this.memory,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    if (memory.photo != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 2.2,
          child: Image.file(
            memory.photo!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (videoController != null &&
        videoController!
            .value
            .isInitialized) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: videoController!
              .value.aspectRatio,
          child: VideoPlayer(
            videoController!,
          ),
        ),
      );
    }

    return Container(
      height: 92,
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0F1EE),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(
          _typeIcon(memory.type),
          size: 34,
          color:
              const Color(0xFF172033),
        ),
      ),
    );
  }

  IconData _typeIcon(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return Icons.photo_rounded;
      case MemoryType.text:
        return Icons.edit_rounded;
      case MemoryType.video:
        return Icons.videocam_rounded;
      case MemoryType.music:
        return Icons.music_note_rounded;
      case MemoryType.location:
        return Icons.location_on_rounded;
    }
  }
}

class _ActionButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active
            ? const Color(0xFF172033)
            : const Color(0xFFF2F3F0),
        borderRadius:
            BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(15),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: active
                      ? Colors.white
                      : const Color(
                          0xFF172033,
                        ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                    color: active
                        ? Colors.white
                        : const Color(
                            0xFF172033,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(
        alpha: .38,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}
