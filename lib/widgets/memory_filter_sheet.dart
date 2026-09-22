import 'package:flutter/material.dart';

import '../models/memory.dart';
import '../models/memory_filter.dart';

class MemoryFilterSheet
    extends StatefulWidget {
  final MemoryFilter initialFilter;

  const MemoryFilterSheet({
    super.key,
    this.initialFilter =
        MemoryFilter.all,
  });

  static Future<MemoryFilter?>
      show(
    BuildContext context, {
    MemoryFilter initialFilter =
        MemoryFilter.all,
  }) {
    return showModalBottomSheet<
        MemoryFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          MemoryFilterSheet(
        initialFilter:
            initialFilter,
      ),
    );
  }

  @override
  State<MemoryFilterSheet>
      createState() =>
          _MemoryFilterSheetState();
}

class _MemoryFilterSheetState
    extends State<MemoryFilterSheet> {
  late MemoryFilter _filter;

  @override
  void initState() {
    super.initState();

    _filter =
        widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 700,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .grey.shade300,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              const Text(
                'Anıları filtrele',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Anı türü',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    MemoryType.values.map(
                  (type) {
                    final selected =
                        _filter.types
                            .contains(
                      type,
                    );

                    return FilterChip(
                      selected:
                          selected,
                      label: Text(
                        _typeTitle(type),
                      ),
                      avatar: Icon(
                        _typeIcon(type),
                        size: 17,
                      ),
                      onSelected: (_) {
                        final types =
                            <MemoryType>{
                          ..._filter
                              .types,
                        };

                        if (selected) {
                          types
                              .remove(
                            type,
                          );
                        } else {
                          types.add(type);
                        }

                        setState(() {
                          _filter =
                              _filter.copyWith(
                            types: types,
                          );
                        });
                      },
                    );
                  },
                ).toList(),
              ),
              const SizedBox(
                height: 18,
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Sadece favoriler',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                secondary:
                    const Icon(
                  Icons
                      .favorite_outline_rounded,
                ),
                value:
                    _filter.favoritesOnly,
                onChanged: (value) {
                  setState(() {
                    _filter =
                        _filter.copyWith(
                      favoritesOnly:
                          value,
                    );
                  });
                },
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Sabitlenenler',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                secondary:
                    const Icon(
                  Icons
                      .push_pin_outlined,
                ),
                value:
                    _filter.pinnedOnly,
                onChanged: (value) {
                  setState(() {
                    _filter =
                        _filter.copyWith(
                      pinnedOnly:
                          value,
                    );
                  });
                },
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Sıralama',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SegmentedButton<
                  MemorySort>(
                segments: const [
                  ButtonSegment<
                      MemorySort>(
                    value:
                        MemorySort.newest,
                    label:
                        Text('Yeni'),
                    icon: Icon(
                      Icons
                          .arrow_downward_rounded,
                    ),
                  ),
                  ButtonSegment<
                      MemorySort>(
                    value:
                        MemorySort.oldest,
                    label:
                        Text('Eski'),
                    icon: Icon(
                      Icons
                          .arrow_upward_rounded,
                    ),
                  ),
                  ButtonSegment<
                      MemorySort>(
                    value:
                        MemorySort.updated,
                    label:
                        Text('Güncel'),
                    icon: Icon(
                      Icons
                          .update_rounded,
                    ),
                  ),
                ],
                selected: {
                  _filter.sort,
                },
                onSelectionChanged:
                    (selection) {
                  setState(() {
                    _filter =
                        _filter.copyWith(
                      sort:
                          selection.first,
                    );
                  });
                },
              ),
              const SizedBox(
                height: 22,
              ),
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filter =
                              const MemoryFilter();
                        });
                      },
                      child:
                          const Text(
                        'Temizle',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _filter,
                        );
                      },
                      child:
                          const Text(
                        'Uygula',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return Icons
            .photo_outlined;
      case MemoryType.text:
        return Icons
            .edit_outlined;
      case MemoryType.video:
        return Icons
            .videocam_outlined;
      case MemoryType.music:
        return Icons
            .music_note_outlined;
      case MemoryType.location:
        return Icons
            .location_on_outlined;
    }
  }

  String _typeTitle(
    MemoryType type,
  ) {
    switch (type) {
      case MemoryType.photo:
        return 'Fotoğraf';
      case MemoryType.text:
        return 'Yazı';
      case MemoryType.video:
        return 'Video';
      case MemoryType.music:
        return 'Müzik';
      case MemoryType.location:
        return 'Konum';
    }
  }
}