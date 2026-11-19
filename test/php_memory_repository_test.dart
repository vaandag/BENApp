import 'dart:convert';

import 'package:benapp/core/network/api_client.dart';
import 'package:benapp/features/memories/data/php_memory_repository.dart';
import 'package:benapp/models/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('PHP database media_type restores photo and video memory types', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/memories');
      return http.Response(
        jsonEncode([
          {
            'id': 10,
            'user_id': 2,
            'title': 'Eski fotoğraf',
            'body': '',
            'media_type': 'photo',
            'media_url': '/api/media/old_photo.jpg',
            'created_at': '2026-01-01 10:00:00',
          },
          {
            'id': 11,
            'user_id': 2,
            'title': 'Eski video',
            'body': '',
            'media_type': 'video',
            'media_url': '/api/media/old_video.mp4',
            'created_at': '2026-01-02 10:00:00',
          },
          {
            'id': 12,
            'user_id': 2,
            'title': 'Eski yazı',
            'body': 'Bir anı',
            'media_type': 'text',
            'media_url': '',
            'created_at': '2026-01-03 10:00:00',
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ApiClient(
      client: client,
      baseUrl: 'https://api.example.test/api',
    );

    try {
      final memories = await PhpMemoryRepository(api).list();

      expect(memories, hasLength(3));
      expect(memories[0].type, MemoryType.photo);
      expect(memories[0].mediaUrl, '/api/media/old_photo.jpg');
      expect(memories[1].type, MemoryType.video);
      expect(memories[1].video, '/api/media/old_video.mp4');
      expect(memories[2].type, MemoryType.text);
    } finally {
      await api.close();
    }
  });

  test('legacy type field remains supported', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': 20,
            'user_id': 2,
            'title': 'Alternatif API',
            'body': '',
            'type': 'photo',
            'media_url': '/api/media/legacy.jpg',
            'created_at': '2026-01-04 10:00:00',
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final api = ApiClient(
      client: client,
      baseUrl: 'https://api.example.test/api',
    );

    try {
      final memories = await PhpMemoryRepository(api).list();
      expect(memories.single.type, MemoryType.photo);
    } finally {
      await api.close();
    }
  });
}
