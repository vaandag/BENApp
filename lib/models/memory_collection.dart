class MemoryCollection {
  final String id;
  final String name;
  final String? description;
  final String? coverMemoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  const MemoryCollection({
    required this.id,
    required this.name,
    this.description,
    this.coverMemoryId,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  MemoryCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? coverMemoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return MemoryCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description:
          description ?? this.description,
      coverMemoryId:
          coverMemoryId ?? this.coverMemoryId,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? DateTime.now(),
      isFavorite:
          isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverMemoryId': coverMemoryId,
      'createdAt':
          createdAt.toIso8601String(),
      'updatedAt':
          updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory MemoryCollection.fromJson(
    Map<String, dynamic> json,
  ) {
    final now = DateTime.now();

    return MemoryCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description:
          json['description'] as String?,
      coverMemoryId:
          json['coverMemoryId'] as String?,
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ??
                '',
          ) ??
          now,
      updatedAt: DateTime.tryParse(
            json['updatedAt'] as String? ??
                '',
          ) ??
          now,
      isFavorite:
          json['isFavorite'] as bool? ??
              false,
    );
  }

  factory MemoryCollection.create({
    required String name,
    String? description,
  }) {
    final now = DateTime.now();

    return MemoryCollection(
      id: now
          .microsecondsSinceEpoch
          .toString(),
      name: name.trim(),
      description:
          description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }
}