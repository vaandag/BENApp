import 'dart:io';

import 'package:latlong2/latlong.dart';

enum MemoryType {
  photo,
  text,
  video,
  music,
  location,
}

class Memory {
  final String id;
  final int? ownerId;
  final String? ownerUsername;
  final String? ownerAvatarUrl;
  final MemoryType type;

  final File? photo;
  final String? text;
  final String? video;
  final String? music;
  final String? mediaUrl;

  final double? latitude;
  final double? longitude;

  final String? title;
  final String? description;
  final List<String> tags;
  final String privacy;
  /// 'memory' = kalıcı anı, 'story' = 24 saatlik paylaşım.
  final String postType;
  final DateTime? expiresAt;

  final bool isFavorite;
  final bool isPinned;

  final List<String> collectionIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Memory({
    required this.id,
    this.ownerId,
    this.ownerUsername,
    this.ownerAvatarUrl,
    required this.type,
    this.photo,
    this.text,
    this.video,
    this.music,
    this.mediaUrl,
    this.latitude,
    this.longitude,
    this.title,
    this.description,
    this.tags = const [],
    this.privacy = 'public',
    this.postType = 'memory',
    this.expiresAt,
    this.isFavorite = false,
    this.isPinned = false,
    this.collectionIds = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Memory.photo({
    required File photo,
    LatLng? location,
    String? title,
    String? description,
    List<String> tags = const [],
    String privacy = 'public',
    String postType = 'memory',
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();

    return Memory(
      id: now.microsecondsSinceEpoch.toString(),
      type: MemoryType.photo,
      photo: photo,
      latitude: location?.latitude,
      longitude: location?.longitude,
      title: title,
      description: description,
      tags: List.unmodifiable(tags),
      privacy: privacy,
      postType: postType,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Memory.text({
    required String text,
    LatLng? location,
    String? title,
    String? description,
    List<String> tags = const [],
    String privacy = 'public',
    String postType = 'memory',
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();

    return Memory(
      id: now.microsecondsSinceEpoch.toString(),
      type: MemoryType.text,
      text: text,
      latitude: location?.latitude,
      longitude: location?.longitude,
      title: title,
      description: description,
      tags: List.unmodifiable(tags),
      privacy: privacy,
      postType: postType,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Memory.video({
    required File video,
    LatLng? location,
    String? title,
    String? description,
    List<String> tags = const [],
    String privacy = 'public',
    String postType = 'memory',
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();

    return Memory(
      id: now.microsecondsSinceEpoch.toString(),
      type: MemoryType.video,
      video: video.path,
      latitude: location?.latitude,
      longitude: location?.longitude,
      title: title,
      description: description,
      tags: List.unmodifiable(tags),
      privacy: privacy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Memory.location({
    required double latitude,
    required double longitude,
    String? title,
    String? description,
    List<String> tags = const [],
    String privacy = 'public',
    String postType = 'memory',
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();

    return Memory(
      id: now.microsecondsSinceEpoch.toString(),
      type: MemoryType.location,
      latitude: latitude,
      longitude: longitude,
      title: title,
      description: description,
      tags: List.unmodifiable(tags),
      privacy: privacy,
      createdAt: now,
      updatedAt: now,
    );
  }

  Memory copyWith({
    String? id,
    int? ownerId,
    String? ownerUsername,
    String? ownerAvatarUrl,
    MemoryType? type,
    File? photo,
    String? text,
    String? video,
    String? music,
    String? mediaUrl,
    double? latitude,
    double? longitude,
    String? title,
    String? description,
    List<String>? tags,
    String? privacy,
    String? postType,
    DateTime? expiresAt,
    bool? isFavorite,
    bool? isPinned,
    List<String>? collectionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      type: type ?? this.type,
      photo: photo ?? this.photo,
      text: text ?? this.text,
      video: video ?? this.video,
      music: music ?? this.music,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: List.unmodifiable(
        tags ?? this.tags,
      ),
      privacy: privacy ?? this.privacy,
      postType: postType ?? this.postType,
      expiresAt: expiresAt ?? this.expiresAt,
      isFavorite:
          isFavorite ?? this.isFavorite,
      isPinned:
          isPinned ?? this.isPinned,
      collectionIds: List.unmodifiable(
        collectionIds ?? this.collectionIds,
      ),
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? DateTime.now(),
    );
  }

  bool get isStory => postType == 'story';

  bool get isExpired => isStory && expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get hasLocation =>
      latitude != null &&
      longitude != null;

  bool get hasPhoto =>
      photo != null;

  bool get hasText =>
      text != null &&
      text!.trim().isNotEmpty;

  bool get hasVideo =>
      video != null &&
      video!.trim().isNotEmpty;

  bool get hasMusic =>
      music != null &&
      music!.trim().isNotEmpty;

  bool get hasTitle =>
      title != null &&
      title!.trim().isNotEmpty;

  bool get hasDescription =>
      description != null &&
      description!.trim().isNotEmpty;

  bool get hasTags =>
      tags.isNotEmpty;

  bool belongsToCollection(
    String collectionId,
  ) {
    return collectionIds.contains(
      collectionId,
    );
  }
}