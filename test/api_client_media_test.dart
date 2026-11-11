import 'package:benapp/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('absolute media URLs are resolved on the configured API origin', () async {
    final api = ApiClient(
      baseUrl: 'https://api.example.test/api',
    );

    expect(
      api.resolveMediaUri(
        'https://attacker.example/legacy/uploads/media/photo_1.jpg',
      ).toString(),
      'https://api.example.test/api/media/photo_1.jpg',
    );

    await api.close();
  });

  test('relative protected media paths keep the configured API prefix', () async {
    final api = ApiClient(
      baseUrl: 'https://api.example.test/v1',
    );

    expect(
      api.resolveMediaUri('/v1/media/video_2.mp4').toString(),
      'https://api.example.test/v1/media/video_2.mp4',
    );

    await api.close();
  });

  test('unrecognized media paths are rejected', () async {
    final api = ApiClient(
      baseUrl: 'https://api.example.test/api',
    );

    expect(
      () => api.resolveMediaUri('https://attacker.example/private/secret.jpg'),
      throwsA(isA<ApiException>()),
    );

    await api.close();
  });
}
