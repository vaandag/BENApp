import 'package:flutter/material.dart';

import '../models/memory.dart';
import '../screens/memory_detail_screen.dart';

class MemoryTimelineGroup
    extends StatelessWidget {
  final DateTime date;
  final List<Memory> memories;

  const MemoryTimelineGroup({
    super.key,
    required this.date,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            left: 4,
            bottom: 12,
          ),
          child: Text(
            _dateTitle(date),
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        ...memories.map(
          (memory) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child:
                _TimelineMemoryCard(
              memory: memory,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }

  String _dateTitle(
    DateTime date,
  ) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

class _TimelineMemoryCard
    extends StatelessWidget {
  final Memory memory;

  const _TimelineMemoryCard({
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MemoryDetailScreen(
                memory: memory,
              ),
            ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.all(13),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              _preview(),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      memory.title ??
                          _typeTitle(
                            memory.type,
                          ),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      '${memory.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${memory.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade500,
                      ),
                    ),
                    if (memory.hasText) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        memory.text!,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (memory.isPinned)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    left: 6,
                  ),
                  child: Icon(
                    Icons
                        .push_pin_rounded,
                    size: 18,
                  ),
                ),
              if (memory.isFavorite)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    left: 6,
                  ),
                  child: Icon(
                    Icons
                        .favorite_rounded,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    if (memory.hasPhoto) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.file(
          memory.photo!,
          width: 74,
          height: 74,
          fit: BoxFit.cover,
        ),
      );
    }

    IconData icon;

    switch (memory.type) {
      case MemoryType.photo:
        icon =
            Icons.photo_outlined;
        break;
      case MemoryType.video:
        icon =
            Icons.videocam_outlined;
        break;
      case MemoryType.text:
        icon =
            Icons.edit_outlined;
        break;
      case MemoryType.music:
        icon =
            Icons.music_note_outlined;
        break;
      case MemoryType.location:
        icon =
            Icons
                .location_on_outlined;
        break;
    }

    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0F1EE),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 30,
        color:
            const Color(0xFF172033),
      ),
    );
  }

  String _typeTitle(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf anısı';
      case MemoryType.video:
        return 'Video anısı';
      case MemoryType.text:
        return 'Yazı anısı';
      case MemoryType.music:
        return 'Müzik anısı';
      case MemoryType.location:
        return 'Konum anısı';
    }
  }
}