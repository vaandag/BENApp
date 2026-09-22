import 'memory.dart';

enum MemorySort {
  newest,
  oldest,
  updated,
}

class MemoryFilter {
  final String query;
  final Set<MemoryType> types;

  final DateTime? startDate;
  final DateTime? endDate;

  final bool favoritesOnly;
  final bool pinnedOnly;

  final String? collectionId;

  final double? latitude;
  final double? longitude;
  final double? radiusInMeters;

  final MemorySort sort;

  const MemoryFilter({
    this.query = '',
    this.types = const {},
    this.startDate,
    this.endDate,
    this.favoritesOnly = false,
    this.pinnedOnly = false,
    this.collectionId,
    this.latitude,
    this.longitude,
    this.radiusInMeters,
    this.sort = MemorySort.newest,
  });

  bool get hasQuery =>
      query.trim().isNotEmpty;

  bool get hasTypeFilter =>
      types.isNotEmpty;

  bool get hasDateFilter =>
      startDate != null ||
      endDate != null;

  bool get hasLocationFilter =>
      latitude != null &&
      longitude != null &&
      radiusInMeters != null;

  bool get isEmpty =>
      !hasQuery &&
      !hasTypeFilter &&
      !hasDateFilter &&
      !favoritesOnly &&
      !pinnedOnly &&
      collectionId == null &&
      !hasLocationFilter;

  MemoryFilter copyWith({
    String? query,
    Set<MemoryType>? types,
    DateTime? startDate,
    DateTime? endDate,
    bool? favoritesOnly,
    bool? pinnedOnly,
    String? collectionId,
    double? latitude,
    double? longitude,
    double? radiusInMeters,
    MemorySort? sort,
  }) {
    return MemoryFilter(
      query: query ?? this.query,
      types: types ?? this.types,
      startDate:
          startDate ?? this.startDate,
      endDate:
          endDate ?? this.endDate,
      favoritesOnly:
          favoritesOnly ??
              this.favoritesOnly,
      pinnedOnly:
          pinnedOnly ??
              this.pinnedOnly,
      collectionId:
          collectionId ?? this.collectionId,
      latitude:
          latitude ?? this.latitude,
      longitude:
          longitude ?? this.longitude,
      radiusInMeters:
          radiusInMeters ??
              this.radiusInMeters,
      sort: sort ?? this.sort,
    );
  }

  MemoryFilter clearQuery() {
    return MemoryFilter(
      query: '',
      types: types,
      startDate: startDate,
      endDate: endDate,
      favoritesOnly: favoritesOnly,
      pinnedOnly: pinnedOnly,
      collectionId: collectionId,
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
      sort: sort,
    );
  }

  MemoryFilter clearTypes() {
    return MemoryFilter(
      query: query,
      types: const {},
      startDate: startDate,
      endDate: endDate,
      favoritesOnly: favoritesOnly,
      pinnedOnly: pinnedOnly,
      collectionId: collectionId,
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
      sort: sort,
    );
  }

  MemoryFilter clearDates() {
    return MemoryFilter(
      query: query,
      types: types,
      favoritesOnly: favoritesOnly,
      pinnedOnly: pinnedOnly,
      collectionId: collectionId,
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
      sort: sort,
    );
  }

  MemoryFilter clearLocation() {
    return MemoryFilter(
      query: query,
      types: types,
      startDate: startDate,
      endDate: endDate,
      favoritesOnly: favoritesOnly,
      pinnedOnly: pinnedOnly,
      collectionId: collectionId,
      sort: sort,
    );
  }

  MemoryFilter clearAll() {
    return const MemoryFilter();
  }

  static const MemoryFilter all =
      MemoryFilter();
}