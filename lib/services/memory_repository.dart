import 'package:latlong2/latlong.dart';

import '../models/memory.dart';
import '../models/memory_collection.dart';
import '../models/memory_filter.dart';
import 'memory_storage_service.dart';

class MemoryRepository {
  final MemoryStorageService _storageService;

  MemoryRepository({
    MemoryStorageService? storageService,
  }) : _storageService =
            storageService ??
                MemoryStorageService();

  List<Memory> _memories = [];

  List<MemoryCollection> _collections = [];

  bool _loaded = false;

  Future<void> initialize() async {
    if (_loaded) {
      return;
    }

    _memories =
        await _storageService.loadMemories();

    _collections =
        await _storageService.loadCollections();

    _loaded = true;
  }

  Future<List<Memory>> getAll() async {
    await initialize();

    return List.unmodifiable(
      _sortedMemories(
        _memories,
        MemorySort.newest,
      ),
    );
  }

  Future<List<Memory>> query(
    MemoryFilter filter,
  ) async {
    await initialize();

    Iterable<Memory> result =
        _memories;

    if (filter.hasQuery) {
      final query =
          filter.query
              .trim()
              .toLowerCase();

      result = result.where(
        (memory) {
          final searchable = [
            memory.id,
            memory.type.name,
            memory.title ?? '',
            memory.description ?? '',
            memory.text ?? '',
            ...memory.tags,
          ].join(' ').toLowerCase();

          return searchable.contains(
            query,
          );
        },
      );
    }

    if (filter.hasTypeFilter) {
      result = result.where(
        (memory) =>
            filter.types.contains(
          memory.type,
        ),
      );
    }

    if (filter.startDate != null) {
      result = result.where(
        (memory) =>
            !memory.createdAt.isBefore(
          filter.startDate!,
        ),
      );
    }

    if (filter.endDate != null) {
      result = result.where(
        (memory) =>
            !memory.createdAt.isAfter(
          filter.endDate!,
        ),
      );
    }

    if (filter.favoritesOnly) {
      result = result.where(
        (memory) =>
            memory.isFavorite,
      );
    }

    if (filter.pinnedOnly) {
      result = result.where(
        (memory) =>
            memory.isPinned,
      );
    }

    if (filter.collectionId != null) {
      result = result.where(
        (memory) =>
            memory.collectionIds.contains(
          filter.collectionId,
        ),
      );
    }

    if (filter.hasLocationFilter) {
      result = result.where(
        (memory) {
          if (!memory.hasLocation) {
            return false;
          }

          final distance =
              _distanceInMeters(
            filter.latitude!,
            filter.longitude!,
            memory.latitude!,
            memory.longitude!,
          );

          return distance <=
              filter.radiusInMeters!;
        },
      );
    }

    final sorted =
        _sortedMemories(
      result.toList(),
      filter.sort,
    );

    return List.unmodifiable(
      sorted,
    );
  }

  Future<Memory?> getById(
    String id,
  ) async {
    await initialize();

    for (final memory in _memories) {
      if (memory.id == id) {
        return memory;
      }
    }

    return null;
  }

  Future<void> add(
    Memory memory,
  ) async {
    await initialize();

    _memories.insert(
      0,
      memory,
    );

    await _persist();
  }

  Future<void> addAll(
    Iterable<Memory> memories,
  ) async {
    await initialize();

    _memories.insertAll(
      0,
      memories,
    );

    await _persist();
  }

  Future<void> remove(
    String id,
  ) async {
    await initialize();

    _memories.removeWhere(
      (memory) =>
          memory.id == id,
    );

    await _persist();
  }

  Future<void> replace(
    Memory memory,
  ) async {
    await initialize();

    final index =
        _memories.indexWhere(
      (item) =>
          item.id == memory.id,
    );

    if (index == -1) {
      return;
    }

    _memories[index] =
        memory.copyWith(
      updatedAt: DateTime.now(),
    );

    await _persist();
  }

  Future<void> toggleFavorite(
    String id,
  ) async {
    final memory =
        await getById(id);

    if (memory == null) {
      return;
    }

    await replace(
      memory.copyWith(
        isFavorite:
            !memory.isFavorite,
      ),
    );
  }

  Future<void> togglePinned(
    String id,
  ) async {
    final memory =
        await getById(id);

    if (memory == null) {
      return;
    }

    await replace(
      memory.copyWith(
        isPinned:
            !memory.isPinned,
      ),
    );
  }

  Future<void> addToCollection({
    required String memoryId,
    required String collectionId,
  }) async {
    final memory =
        await getById(memoryId);

    if (memory == null) {
      return;
    }

    if (memory.collectionIds
        .contains(collectionId)) {
      return;
    }

    await replace(
      memory.copyWith(
        collectionIds: [
          ...memory.collectionIds,
          collectionId,
        ],
      ),
    );
  }

  Future<void> removeFromCollection({
    required String memoryId,
    required String collectionId,
  }) async {
    final memory =
        await getById(memoryId);

    if (memory == null) {
      return;
    }

    final ids =
        memory.collectionIds
            .where(
              (id) =>
                  id != collectionId,
            )
            .toList();

    await replace(
      memory.copyWith(
        collectionIds: ids,
      ),
    );
  }

  Future<void> clear() async {
    await initialize();

    _memories.clear();

    await _persist();
  }

  Future<List<MemoryCollection>>
      getCollections() async {
    await initialize();

    return List.unmodifiable(
      _collections,
    );
  }

  Future<MemoryCollection>
      createCollection({
    required String name,
    String? description,
  }) async {
    await initialize();

    final collection =
        MemoryCollection.create(
      name: name,
      description: description,
    );

    _collections.add(
      collection,
    );

    await _persistCollections();

    return collection;
  }

  Future<void> updateCollection(
    MemoryCollection collection,
  ) async {
    await initialize();

    final index =
        _collections.indexWhere(
      (item) =>
          item.id == collection.id,
    );

    if (index == -1) {
      return;
    }

    _collections[index] =
        collection.copyWith(
      updatedAt: DateTime.now(),
    );

    await _persistCollections();
  }

  Future<void> deleteCollection(
    String id,
  ) async {
    await initialize();

    _collections.removeWhere(
      (collection) =>
          collection.id == id,
    );

    for (var i = 0;
        i < _memories.length;
        i++) {
      final memory =
          _memories[i];

      if (memory.collectionIds
          .contains(id)) {
        _memories[i] =
            memory.copyWith(
          collectionIds:
              memory.collectionIds
                  .where(
                    (item) =>
                        item != id,
                  )
                  .toList(),
        );
      }
    }

    await _persist();
    await _persistCollections();
  }

  Future<void> _persist() async {
    await _storageService
        .saveMemories(
      _memories,
    );
  }

  Future<void>
      _persistCollections() async {
    await _storageService
        .saveCollections(
      _collections,
    );
  }

  List<Memory> _sortedMemories(
    Iterable<Memory> memories,
    MemorySort sort,
  ) {
    final result =
        memories.toList();

    switch (sort) {
      case MemorySort.newest:
        result.sort(
          (a, b) =>
              b.createdAt.compareTo(
            a.createdAt,
          ),
        );
        break;

      case MemorySort.oldest:
        result.sort(
          (a, b) =>
              a.createdAt.compareTo(
            b.createdAt,
          ),
        );
        break;

      case MemorySort.updated:
        result.sort(
          (a, b) =>
              b.updatedAt.compareTo(
            a.updatedAt,
          ),
        );
        break;
    }

    return result;
  }

  double _distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const distance = Distance();

    return distance.as(
      LengthUnit.Meter,
      LatLng(
        lat1,
        lon1,
      ),
      LatLng(
        lat2,
        lon2,
      ),
    );
  }
}