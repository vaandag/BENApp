import '../../../core/network/api_client.dart';
import '../../../models/memory.dart';

/// PHP API'den gelen anıları uygulamanın domain modeline dönüştürür.
class PhpMemoryRepository {
  PhpMemoryRepository(this._api);
  final ApiClient _api;

  Future<List<Memory>> list({String query = '', int userId = 1, String scope = 'mine'}) async {
    final json = await _api.get('memories', query: {'q': query, 'user_id': '$userId', 'scope': scope});
    final rows = json is List ? json : (json is Map && json['data'] is List ? json['data'] as List : <dynamic>[]);
    return rows.whereType<Map>().map(_memoryFromJson).toList();
  }

  Future<int?> create(Memory memory, {int userId = 1}) async {
    final result = await _api.post('memories', body: {
        'user_id': userId,
        'title': memory.title ?? _typeTitle(memory.type),
        'place': memory.hasLocation ? '${memory.latitude},${memory.longitude}' : '',
        'body': memory.text ?? memory.description ?? '',
        'type': memory.type.name,
        if (memory.mediaUrl != null) 'media_url': memory.mediaUrl,
        'privacy': memory.privacy,
        'post_type': memory.postType,
        if (memory.expiresAt != null) 'expires_at': memory.expiresAt!.toIso8601String(),
        if (memory.latitude != null) 'lat': memory.latitude,
        if (memory.longitude != null) 'lng': memory.longitude,
        if (memory.locationAccuracy != null) 'location_accuracy': memory.locationAccuracy,
      });
    if (result is Map) return int.tryParse('${result['id']}');
    return null;
  }

  Memory _memoryFromJson(Map row) {
    final rawType = (row['type'] ?? 'text').toString();
    final type = MemoryType.values.where((e) => e.name == rawType).firstOrNull ?? MemoryType.text;
    final lat = _number(row['lat']);
    final lng = _number(row['lng']);
    return Memory(
      id: row['id'].toString(), ownerId: int.tryParse('${row['user_id'] ?? row['owner_id'] ?? ''}'), ownerUsername: row['username']?.toString(), ownerAvatarUrl: row['avatar_url']?.toString(), type: type,
      title: row['title']?.toString(), mediaUrl: row['media_url']?.toString(), text: row['body']?.toString(),
      description: row['place']?.toString(),
      privacy: row['privacy']?.toString() ?? 'public',
      postType: row['post_type']?.toString() ?? 'memory',
      expiresAt: DateTime.tryParse(row['expires_at']?.toString() ?? ''),
      latitude: lat, longitude: lng, locationAccuracy: _number(row['location_accuracy']),
      isFavorite: row['liked'] == true || row['liked'] == 1, isPinned: row['saved'] == true || row['saved'] == 1,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
  double? _number(Object? value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  String _typeTitle(MemoryType type) => '${type.name[0].toUpperCase()}${type.name.substring(1)} anısı';
}
