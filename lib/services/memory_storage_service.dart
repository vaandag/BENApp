import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/memory.dart';
import '../models/memory_collection.dart';

class MemoryStorageService {
  static const String _memoriesFileName =
      'memories.json';

  static const String _collectionsFileName =
      'collections.json';

  Future<Directory> _getStorageDirectory() async {
    final baseDirectory =
        await getApplicationDocumentsDirectory();

    final memoriesDirectory = Directory(
      '${baseDirectory.path}/ben_memories',
    );

    if (!await memoriesDirectory.exists()) {
      await memoriesDirectory.create(
        recursive: true,
      );
    }

    return memoriesDirectory;
  }

  Future<File> _getMemoriesFile() async {
    final directory =
        await _getStorageDirectory();

    return File(
      '${directory.path}/$_memoriesFileName',
    );
  }

  Future<File> _getCollectionsFile() async {
    final directory =
        await _getStorageDirectory();

    return File(
      '${directory.path}/$_collectionsFileName',
    );
  }

  Future<List<Memory>> loadMemories() async {
    final file = await _getMemoriesFile();
    final decoded = await _readJsonListWithBackup(file);
    return decoded
        .whereType<Map>()
        .map((item) => _memoryFromJson(Map<String, dynamic>.from(item)))
        .whereType<Memory>()
        .toList();
  }

  Future<void> saveMemories(List<Memory> memories) async {
    final file = await _getMemoriesFile();
    final data = memories.map(_memoryToJson).toList();
    await _writeJsonAtomically(file, jsonEncode(data));
  }

  Future<List<MemoryCollection>> loadCollections() async {
    final file = await _getCollectionsFile();
    final decoded = await _readJsonListWithBackup(file);
    return decoded
        .whereType<Map>()
        .map((item) => MemoryCollection.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveCollections(List<MemoryCollection> collections) async {
    final file = await _getCollectionsFile();
    final data = collections.map((collection) => collection.toJson()).toList();
    await _writeJsonAtomically(file, jsonEncode(data));
  }

  Future<List<dynamic>> _readJsonListWithBackup(File file) async {
    final backup = File('${file.path}.bak');
    if (!await file.exists() && !await backup.exists()) return <dynamic>[];

    try {
      return await _decodeJsonList(file);
    } catch (primaryError) {
      if (!await backup.exists()) {
        throw FormatException(
          'BEN yerel kayıt dosyası okunamadı; kayıtların üzerine yazılmadı.',
          primaryError,
        );
      }

      try {
        final recovered = await _decodeJsonList(backup);
        final restore = File('${file.path}.restore');
        await backup.copy(restore.path);
        if (await file.exists()) await file.delete();
        await restore.rename(file.path);
        return recovered;
      } catch (backupError) {
        throw FormatException(
          'BEN yerel kayıt dosyası ve yedeği okunamadı.',
          backupError,
        );
      }
    }
  }

  Future<List<dynamic>> _decodeJsonList(File file) async {
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw const FormatException('Kayıt dosyası boş.');
    }
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw const FormatException('Kayıt dosyası beklenen liste biçiminde değil.');
    }
    return decoded;
  }

  Future<void> _writeJsonAtomically(File file, String content) async {
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');

    await temporary.writeAsString(content, flush: true);
    if (await file.exists()) {
      await file.copy(backup.path);
      await file.delete();
    }

    try {
      await temporary.rename(file.path);
    } catch (_) {
      if (!await file.exists() && await backup.exists()) {
        await backup.copy(file.path);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _memoryToJson(
    Memory memory,
  ) {
    return {
      'id': memory.id,
      'ownerId': memory.ownerId,
      'ownerUsername': memory.ownerUsername,
      'ownerAvatarUrl': memory.ownerAvatarUrl,
      'type': memory.type.name,
      'photo': memory.photo?.path,
      'text': memory.text,
      'video': memory.video,
      'music': memory.music,
      'mediaUrl': memory.mediaUrl,
      'latitude': memory.latitude,
      'longitude': memory.longitude,
      'locationAccuracy': memory.locationAccuracy,

      'title': memory.title,
      'description':
          memory.description,
      'tags': memory.tags,
      'privacy': memory.privacy,
      'postType': memory.postType,
      'expiresAt': memory.expiresAt?.toIso8601String(),

      'isFavorite':
          memory.isFavorite,
      'isPinned':
          memory.isPinned,

      'collectionIds':
          memory.collectionIds,

      'createdAt':
          memory.createdAt
              .toIso8601String(),

      'updatedAt':
          memory.updatedAt
              .toIso8601String(),
    };
  }

  Memory? _memoryFromJson(
    Map<String, dynamic> json,
  ) {
    try {
      final typeName =
          json['type'] as String?;

      if (typeName == null) {
        return null;
      }

      final type =
          MemoryType.values.firstWhere(
        (value) =>
            value.name == typeName,
      );

      final photoPath =
          json['photo'] as String?;

      final createdAt =
          DateTime.tryParse(
        json['createdAt'] as String? ??
            '',
      );

      if (createdAt == null) {
        return null;
      }

      final updatedAt =
          DateTime.tryParse(
        json['updatedAt'] as String? ??
            '',
      ) ??
          createdAt;

      final rawTags =
          json['tags'];

      final tags = rawTags is List
          ? rawTags
              .whereType<String>()
              .toList()
          : <String>[];

      final rawCollections =
          json['collectionIds'];

      final collectionIds =
          rawCollections is List
              ? rawCollections
                  .whereType<String>()
                  .toList()
              : <String>[];

      return Memory(
        id: json['id'] as String,
        ownerId: (json['ownerId'] as num?)?.toInt(),
        ownerUsername: json['ownerUsername'] as String?,
        ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
        type: type,
        photo: photoPath != null
            ? File(photoPath)
            : null,
        text: json['text'] as String?,
        video:
            json['video'] as String?,
        music:
            json['music'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        latitude:
            (json['latitude'] as num?)
                ?.toDouble(),
        longitude:
            (json['longitude'] as num?)
                ?.toDouble(),
        locationAccuracy:
            (json['locationAccuracy'] as num?)
                ?.toDouble(),

        title:
            json['title'] as String?,
        description:
            json['description']
                as String?,

        tags: tags,
        privacy: json['privacy'] as String? ?? 'public',
        postType: json['postType'] as String? ?? 'memory',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),

        isFavorite:
            json['isFavorite']
                    as bool? ??
                false,

        isPinned:
            json['isPinned']
                    as bool? ??
                false,

        collectionIds:
            collectionIds,

        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (_) {
      return null;
    }
  }
}