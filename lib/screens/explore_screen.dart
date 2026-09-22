import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';

import '../models/memory.dart';
import '../models/memory_filter.dart';
import '../services/memory_repository.dart';
import '../widgets/memory_card.dart';
import '../widgets/memory_filter_sheet.dart';
import 'collections_screen.dart';
import 'memory_map_detail_screen.dart';
import 'timeline_screen.dart';

class ExploreScreen
    extends StatefulWidget {
  final List<Memory> memories;

  const ExploreScreen({
    super.key,
    required this.memories,
  });

  @override
  State<ExploreScreen> createState() =>
      _ExploreScreenState();
}

class _ExploreScreenState
    extends State<ExploreScreen> {
  final MemoryRepository _repository =
      MemoryRepository();

  final TextEditingController
      _searchController =
      TextEditingController();

  MemoryFilter _filter =
      const MemoryFilter();

  List<Memory> _results = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _results = [
      ...widget.memories,
    ];

    _load();
  }

  @override
  void didUpdateWidget(
    covariant ExploreScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.memories !=
        widget.memories) {
      _applyLocalFilter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _repository
          .initialize();

      await _runQuery();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _results = [
          ...widget.memories,
        ];
        _loading = false;
      });
    }
  }

  Future<void> _runQuery() async {
    final filter =
        _filter.copyWith(
      query:
          _searchController.text,
    );

    final results =
        await _repository.query(
      filter,
    );

    if (!mounted) return;

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _applyLocalFilter() {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    Iterable<Memory> result =
        widget.memories;

    if (query.isNotEmpty) {
      result = result.where(
        (memory) {
          final searchable = [
            memory.title ?? '',
            memory.description ?? '',
            memory.text ?? '',
            memory.type.name,
            ...memory.tags,
          ].join(' ').toLowerCase();

          return searchable.contains(
            query,
          );
        },
      );
    }

    if (_filter.types.isNotEmpty) {
      result = result.where(
        (memory) =>
            _filter.types.contains(
          memory.type,
        ),
      );
    }

    if (_filter.favoritesOnly) {
      result = result.where(
        (memory) =>
            memory.isFavorite,
      );
    }

    if (_filter.pinnedOnly) {
      result = result.where(
        (memory) =>
            memory.isPinned,
      );
    }

    setState(() {
      _results =
          result.toList();
    });
  }

  Future<void> _toggleFavorite(
    Memory memory,
  ) async {
    await _repository
        .toggleFavorite(
      memory.id,
    );

    await _load();
  }

  Future<void> _togglePinned(
    Memory memory,
  ) async {
    await _repository
        .togglePinned(
      memory.id,
    );

    await _load();
  }

  Future<void> _openFilter() async {
    final result =
        await MemoryFilterSheet.show(
      context,
      initialFilter: _filter,
    );

    if (result == null) return;

    setState(() {
      _filter = result;
      _loading = true;
    });

    await _runQuery();
  }

  Future<void>
      _openCollections() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CollectionsScreen(),
      ),
    );

    await _load();
  }

  Future<void> _openTimeline() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TimelineScreen(
          memories: _results,
        ),
      ),
    );
  }

  void _openMemory(
    Memory memory,
  ) {
    if (memory.hasLocation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MemoryMapDetailScreen(
            memory: memory,
            memories: _results,
          ),
        ),
      );
      return;
    }

    // Konumu olmayan anılar
    // mevcut detay ekranında
    // açılmaya devam eder.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FallbackMemoryDetail(
          memory: memory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilter = !_filter.isEmpty;

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            6,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .25),
                    ),
                  ),
                  child: TextField(
                    controller:
                        _searchController,
                    onChanged: (_) {
                      _runQuery();
                    },
                    decoration:
                        InputDecoration(
                      border:
                          InputBorder.none,
                      prefixIcon:
                          const Icon(
                        Icons
                            .search_rounded,
                      ),
                      hintText:
                          'Anılarını ara...',
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              _SquareButton(
                icon:
                    Icons.tune_rounded,
                active:
                    hasActiveFilter,
                onTap:
                    _openFilter,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection:
                Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            children: [
              _QuickAction(
                icon:
                    Icons.timeline_rounded,
                title: 'Timeline',
                onTap:
                    _openTimeline,
              ),
              _QuickAction(
                icon:
                    Icons.folder_outlined,
                title: 'Koleksiyonlar',
                onTap:
                    _openCollections,
              ),
              _QuickAction(
                icon: Icons
                    .favorite_outline_rounded,
                title: 'Favoriler',
                onTap: () {
                  setState(() {
                    _filter =
                        _filter.copyWith(
                      favoritesOnly:
                          true,
                    );
                  });

                  _runQuery();
                },
              ),
              _QuickAction(
                icon: Icons
                    .push_pin_outlined,
                title: 'Sabitlenenler',
                onTap: () {
                  setState(() {
                    _filter =
                        _filter.copyWith(
                      pinnedOnly:
                          true,
                    );
                  });

                  _runQuery();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Anı bulunamadı',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        110,
      ),
      itemCount:
          _results.length,
      separatorBuilder:
          (_, _) =>
              const SizedBox(
        height: 16,
      ),
      itemBuilder:
          (context, index) {
        final memory =
            _results[index];

        return Stack(
          children: [
            MemoryCard(
              memory: memory,
              onTap: () =>
                  _openMemory(
                memory,
              ),
            ),
            Positioned(
              right: 52,
              bottom: 78,
              child: Row(
                children: [
                  _MiniAction(
                    icon: memory.isFavorite
                        ? Icons
                            .favorite_rounded
                        : Icons
                            .favorite_border_rounded,
                    onTap: () =>
                        _toggleFavorite(
                      memory,
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  _MiniAction(
                    icon: memory.isPinned
                        ? Icons
                            .push_pin_rounded
                        : Icons
                            .push_pin_outlined,
                    onTap: () =>
                        _togglePinned(
                      memory,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FallbackMemoryDetail
    extends StatelessWidget {
  final Memory memory;

  const _FallbackMemoryDetail({
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anı'),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Text(
            memory.text ??
                'Bu anının konumu bulunmuyor.',
            textAlign:
                TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SquareButton
    extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active
          ? BenTokens.cyan
          : theme.colorScheme.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? BenTokens.cyan
                  : theme.dividerColor.withValues(alpha: .25),
            ),
          ),
          child: Icon(
            icon,
            color: active
                ? const Color(0xFF0E1014)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _QuickAction
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 17,
        ),
        label: Text(title),
        onPressed: onTap,
      ),
    );
  }
}

class _MiniAction
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape:
          const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: Padding(
          padding:
              const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 19,
            color:
                const Color(0xFF172033),
          ),
        ),
      ),
    );
  }
}