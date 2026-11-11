import 'dart:convert';

import 'package:benapp/core/network/api_client.dart';
import 'package:benapp/core/network/auth_token_store.dart';
import 'package:benapp/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTokenStore extends AuthTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.currentUser = null;
    ApiClient.token = null;
  });

  Future<void> seedCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ben_current_user',
      jsonEncode({
        'id': 42,
        'username': 'ben_test',
        'email': 'ben@example.test',
        'xp': 0,
        'coins': 0,
      }),
    );
  }

  test('temporary server outage preserves the cached session', () async {
    await seedCachedUser();
    final tokenStore = _MemoryTokenStore()..value = 'test-token';
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'temporary outage'}),
          503,
        ),
      ),
      tokenStore: tokenStore,
      baseUrl: 'https://api.example.test/api',
    );
    final auth = AuthService(api, tokenStore: tokenStore);

    expect(await auth.restoreSession(), isTrue);
    expect(AuthService.currentUser?.id, 42);
    expect(tokenStore.value, 'test-token');
    expect(
      (await SharedPreferences.getInstance()).containsKey('ben_current_user'),
      isTrue,
    );
  });

  test('a definitive 401 clears an expired session', () async {
    await seedCachedUser();
    final tokenStore = _MemoryTokenStore()..value = 'expired-token';
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'session expired'}),
          401,
        ),
      ),
      tokenStore: tokenStore,
      baseUrl: 'https://api.example.test/api',
    );
    final auth = AuthService(api, tokenStore: tokenStore);

    expect(await auth.restoreSession(), isFalse);
    expect(AuthService.currentUser, isNull);
    expect(tokenStore.value, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('ben_current_user'),
      isFalse,
    );
  });
}
