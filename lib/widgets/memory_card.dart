import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/memory.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: .25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildPreview(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        7,
        13,
      ),
      child: Row(
        children: [
          _TypeIcon(
            type: memory.type,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _typeTitle(memory.type),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _formatDate(
                    memory.createdAt,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: .52),
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            icon: Icon(
              Icons.more_horiz_rounded,
              color:
                  theme.colorScheme.onSurface.withValues(alpha: .52),
              size: 21,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_outline_rounded,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Sil'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (memory.hasPhoto) {
      return AspectRatio(
        aspectRatio: 1.08,
        child: Image.file(
          memory.photo!,
          width: double.infinity,
          fit: BoxFit.cover,
          cacheWidth: 900,
          errorBuilder:
              (_, _, _) {
            return const _ErrorPreview(
              icon:
                  Icons.broken_image_outlined,
            );
          },
        ),
      );
    }

    if (memory.hasVideo) {
      return _VideoPreview(
        videoPath: memory.video!,
      );
    }

    if (memory.hasText) {
      return _TextMemoryPreview(
        text: memory.text!,
      );
    }

    if (memory.type ==
        MemoryType.location) {
      return _LocationPreview(
        memory: memory,
      );
    }

    return Container(
      width: double.infinity,
      height: 180,
      color: const Color(0xFFF0F1EE),
      child: Icon(
        _typeIcon(memory.type),
        size: 48,
        color: const Color(0xFF172033),
      ),
    );
  }

  static IconData _typeIcon(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return Icons.photo_outlined;

      case MemoryType.text:
        return Icons.edit_outlined;

      case MemoryType.video:
        return Icons.videocam_outlined;

      case MemoryType.music:
        return Icons.music_note_outlined;

      case MemoryType.location:
        return Icons.location_on_outlined;
    }
  }

  static String _typeTitle(
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

  static String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}


// ======================================================
// VIDEO CARD
// ======================================================

class _VideoPreview extends StatefulWidget {
  final String videoPath;

  const _VideoPreview({
    required this.videoPath,
  });

  @override
  State<_VideoPreview> createState() =>
      _VideoPreviewState();
}

class _VideoPreviewState
    extends State<_VideoPreview> {
  VideoPlayerController? _controller;

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller =
          VideoPlayerController.file(
        File(widget.videoPath),
      );

      _controller = controller;

      await controller.initialize();

      await controller.setLooping(true);

      // Ana sayfadaki videolar sessiz başlasın.
      await controller.setVolume(0);

      await controller.play();

      if (!mounted) return;

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const _ErrorPreview(
        icon: Icons.video_file_outlined,
      );
    }

    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 205,
        color: const Color(0xFF172033),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 205,
      color: const Color(0xFF172033),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    controller.value.size.width,
                height:
                    controller.value.size.height,
                child: VideoPlayer(
                  controller,
                ),
              ),
            ),
          ),

          // Hafif karartma.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: 0.05,
                      ),
                      Colors.black.withValues(
                        alpha: 0.18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ortadaki oynat / durdur.
          GestureDetector(
            onTap: _togglePlayback,
            child: AnimatedOpacity(
              opacity:
                  controller.value.isPlaying
                      ? 0.0
                      : 1.0,
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              child: Container(
                width: 60,
                height: 60,
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color:
                      const Color(0xFF172033),
                  size: 34,
                ),
              ),
            ),
          ),

          // Video etiketi.
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.black54,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .videocam_outlined,
                    color: Colors.white,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Süre.
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.black54,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(
                  controller.value.position,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final minutes =
        duration.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        duration.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }
}


// ======================================================
// TEXT PREVIEW
// ======================================================

class _TextMemoryPreview
    extends StatelessWidget {
  final String text;

  const _TextMemoryPreview({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints:
          const BoxConstraints(
        minHeight: 190,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        22,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xFFF0F0EC),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 30,
            color:
                Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            text,
            maxLines: 6,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              height: 1.42,
              fontWeight:
                  FontWeight.w500,
              letterSpacing: -0.2,
              color:
                  Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }
}


// ======================================================
// LOCATION PREVIEW
// ======================================================

class _LocationPreview
    extends StatelessWidget {
  final Memory memory;

  const _LocationPreview({
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration:
          const BoxDecoration(
        color: Color(0xFFECEDE9),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF172033),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 29,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (memory.hasLocation)
              Text(
                '${memory.latitude!.toStringAsFixed(5)}, '
                '${memory.longitude!.toStringAsFixed(5)}',
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// ======================================================
// TYPE ICON
// ======================================================

class _TypeIcon
    extends StatelessWidget {
  final MemoryType type;

  const _TypeIcon({
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        MemoryCard._typeIcon(type),
        size: 18,
        color:
            const Color(0xFF172033),
      ),
    );
  }
}


// ======================================================
// ERROR
// ======================================================

class _ErrorPreview
    extends StatelessWidget {
  final IconData icon;

  const _ErrorPreview({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 205,
      color:
          const Color(0xFFF0F1EE),
      child: Icon(
        icon,
        size: 48,
        color:
            const Color(0xFF172033),
      ),
    );
  }
}