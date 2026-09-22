import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/memory.dart';
import '../core/navigation/ben_routes.dart';

class MemoryDetailScreen
    extends StatefulWidget {
  final Memory memory;

  const MemoryDetailScreen({
    super.key,
    required this.memory,
  });

  @override
  State<MemoryDetailScreen> createState() =>
      _MemoryDetailScreenState();
}

class _MemoryDetailScreenState
    extends State<MemoryDetailScreen> {
  VideoPlayerController?
      _videoController;

  bool _videoError = false;
  late bool _liked;
  late bool _pinned;
  final int _comments = 0;

  @override
  void initState() {
    super.initState();
    _liked = widget.memory.isFavorite;
    _pinned = widget.memory.isPinned;

    if (widget.memory.hasVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final controller =
          VideoPlayerController.file(
        File(widget.memory.video!),
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _videoError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFAFAF8),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Anı',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          40,
        ),
        children: [
          _buildMainContent(),

          const SizedBox(height: 14),
          _SocialActions(
            liked: _liked,
            pinned: _pinned,
            comments: _comments,
            onLike: () => setState(() => _liked = !_liked),
            onPin: () => setState(() => _pinned = !_pinned),
            onComment: _openComment,
          ),

          const SizedBox(
            height: 22,
          ),

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon:
                      _typeIcon(memory.type),
                  title:
                      _typeTitle(
                    memory.type,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _InfoRow(
                  icon: Icons
                      .access_time_rounded,
                  title:
                      _formatDate(
                    memory.createdAt,
                  ),
                ),

                if (memory.hasLocation) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  _InfoRow(
                    icon: Icons
                        .location_on_outlined,
                    title:
                        '${memory.latitude!.toStringAsFixed(6)}, '
                        '${memory.longitude!.toStringAsFixed(6)}',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size(
                double.infinity,
                52,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Anılara dön',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openComment() async {
    await BenRoutes.openComments(
      context,
      memoryId: int.tryParse(widget.memory.id),
      memoryKey: widget.memory.id,
      initialCount: _comments,
    );
  }

  Widget _buildMainContent() {
    final memory = widget.memory;

    if (memory.hasPhoto) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(26),
        child: Image.file(
          memory.photo!,
          width: double.infinity,
          height: 430,
          fit: BoxFit.cover,
          errorBuilder:
              (_, _, _) {
            return _ErrorContent(
              icon: Icons
                  .broken_image_outlined,
              title:
                  'Fotoğraf açılamadı',
            );
          },
        ),
      );
    }

    if (memory.hasVideo) {
      if (_videoError) {
        return _ErrorContent(
          icon: Icons
              .video_file_outlined,
          title:
              'Video açılamadı',
        );
      }

      final controller =
          _videoController;

      if (controller == null ||
          !controller.value.isInitialized) {
        return Container(
          width: double.infinity,
          height: 430,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF172033),
            borderRadius:
                BorderRadius.circular(
              26,
            ),
          ),
          child: const Center(
            child:
                CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(26),
        child: Container(
          color:
              const Color(0xFF172033),
          child: Stack(
            alignment:
                Alignment.center,
            children: [
              AspectRatio(
                aspectRatio:
                    controller.value
                        .aspectRatio,
                child:
                    VideoPlayer(
                  controller,
                ),
              ),

              GestureDetector(
                onTap: () {
                  if (controller
                      .value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }

                  setState(() {});
                },
                child: Container(
                  width: 66,
                  height: 66,
                  decoration:
                      const BoxDecoration(
                    color:
                        Colors.black54,
                    shape:
                        BoxShape.circle,
                  ),
                  child: Icon(
                    controller
                            .value
                            .isPlaying
                        ? Icons
                            .pause_rounded
                        : Icons
                            .play_arrow_rounded,
                    color:
                        Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (memory.hasText) {
      return Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(
          minHeight: 360,
        ),
        padding:
            const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF0F0EC),
          borderRadius:
              BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons
                  .format_quote_rounded,
              size: 40,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 28,
            ),
            Text(
              memory.text!,
              style:
                  const TextStyle(
                fontSize: 22,
                height: 1.55,
                fontWeight:
                    FontWeight.w500,
                color:
                    Color(0xFF172033),
              ),
            ),
          ],
        ),
      );
    }

    if (memory.type ==
        MemoryType.location) {
      return Container(
        width: double.infinity,
        height: 320,
        decoration: BoxDecoration(
          color:
              const Color(0xFFECEDE9),
          borderRadius:
              BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF172033),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .location_on_rounded,
                size: 42,
                color:
                    Colors.white,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            if (memory.hasLocation)
              Text(
                '${memory.latitude!.toStringAsFixed(6)}, '
                '${memory.longitude!.toStringAsFixed(6)}',
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(26),
      ),
      child: Center(
        child: Icon(
          _typeIcon(memory.type),
          size: 64,
          color:
              const Color(0xFF172033),
        ),
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



class _SocialActions extends StatelessWidget {
  final bool liked;
  final bool pinned;
  final int comments;
  final VoidCallback onLike;
  final VoidCallback onPin;
  final VoidCallback onComment;

  const _SocialActions({
    required this.liked,
    required this.pinned,
    required this.comments,
    required this.onLike,
    required this.onPin,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: 'Beğen',
              active: liked,
              onPressed: onLike,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: comments > 0 ? 'Yorum $comments' : 'Yorum',
              onPressed: onComment,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: pinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: 'Sabitle',
              active: pinned,
              onPressed: onPin,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorContent
    extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ErrorContent({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0F1EE),
        borderRadius:
            BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 54,
            color:
                const Color(0xFF172033),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String title;

  const _InfoRow({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                Colors.grey.shade100,
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color:
                const Color(0xFF172033),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}