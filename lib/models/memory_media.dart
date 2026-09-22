import 'dart:io';

enum MemoryMediaType {
  image,
  video,
  audio,
  file,
}

class MemoryMedia {
  final String id;
  final MemoryMediaType type;
  final String path;
  final String? thumbnailPath;
  final String? mimeType;
  final int? sizeBytes;
  final Duration? duration;
  final DateTime createdAt;

  const MemoryMedia({
    required this.id,
    required this.type,
    required this.path,
    this.thumbnailPath,
    this.mimeType,
    this.sizeBytes,
    this.duration,
    required this.createdAt,
  });

  bool get isImage =>
      type == MemoryMediaType.image;

  bool get isVideo =>
      type == MemoryMediaType.video;

  bool get isAudio =>
      type == MemoryMediaType.audio;

  bool get isFile =>
      type == MemoryMediaType.file;

  File get file => File(path);

  MemoryMedia copyWith({
    String? id,
    MemoryMediaType? type,
    String? path,
    String? thumbnailPath,
    String? mimeType,
    int? sizeBytes,
    Duration? duration,
    DateTime? createdAt,
  }) {
    return MemoryMedia(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      thumbnailPath:
          thumbnailPath ?? this.thumbnailPath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes:
          sizeBytes ?? this.sizeBytes,
      duration:
          duration ?? this.duration,
      createdAt:
          createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'path': path,
      'thumbnailPath':
          thumbnailPath,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'durationMs':
          duration?.inMilliseconds,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }

  factory MemoryMedia.fromJson(
    Map<String, dynamic> json,
  ) {
    final typeName =
        json['type'] as String?;

    final type =
        MemoryMediaType.values.firstWhere(
      (value) =>
          value.name == typeName,
      orElse: () =>
          MemoryMediaType.file,
    );

    final durationMs =
        json['durationMs'] as num?;

    return MemoryMedia(
      id: json['id'] as String,
      type: type,
      path: json['path'] as String,
      thumbnailPath:
          json['thumbnailPath']
              as String?,
      mimeType:
          json['mimeType'] as String?,
      sizeBytes:
          (json['sizeBytes'] as num?)
              ?.toInt(),
      duration: durationMs != null
          ? Duration(
              milliseconds:
                  durationMs.toInt(),
            )
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
    );
  }

  static MemoryMedia image({
    required File file,
    String? mimeType,
  }) {
    return MemoryMedia(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      type: MemoryMediaType.image,
      path: file.path,
      mimeType: mimeType,
      createdAt: DateTime.now(),
    );
  }

  static MemoryMedia video({
    required File file,
    String? mimeType,
    Duration? duration,
    String? thumbnailPath,
  }) {
    return MemoryMedia(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      type: MemoryMediaType.video,
      path: file.path,
      thumbnailPath:
          thumbnailPath,
      mimeType: mimeType,
      duration: duration,
      createdAt: DateTime.now(),
    );
  }

  static MemoryMedia audio({
    required File file,
    String? mimeType,
    Duration? duration,
  }) {
    return MemoryMedia(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      type: MemoryMediaType.audio,
      path: file.path,
      mimeType: mimeType,
      duration: duration,
      createdAt: DateTime.now(),
    );
  }

  static MemoryMedia genericFile({
    required File file,
    String? mimeType,
  }) {
    return MemoryMedia(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      type: MemoryMediaType.file,
      path: file.path,
      mimeType: mimeType,
      createdAt: DateTime.now(),
    );
  }
}