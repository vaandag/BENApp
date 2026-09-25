import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'auth_token_store.dart';

class ApiException extends AppException {
  const ApiException(
    super.message, {
    super.statusCode,
    super.code,
    super.cause,
  });
}

/// Small, reusable HTTP boundary for the BEN API.
///
/// Responsibilities intentionally stop at transport concerns: auth header,
/// timeouts, retries for safe requests, request correlation, JSON decoding,
/// and consistent exception mapping. Feature repositories own endpoint
/// semantics.
class ApiClient {
  ApiClient({
    http.Client? client,
    AuthTokenStore? tokenStore,
    String? baseUrl,
    Duration requestTimeout = const Duration(seconds: 15),
    Duration uploadTimeout = const Duration(seconds: 90),
  })  : _client = client ?? http.Client(),
        _tokenStore = tokenStore,
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl)
            .replaceFirst(RegExp(r'/+$'), ''),
        _requestTimeout = requestTimeout,
        _uploadTimeout = uploadTimeout;

  final http.Client _client;
  final AuthTokenStore? _tokenStore;
  final String _baseUrl;
  final Duration _requestTimeout;
  final Duration _uploadTimeout;

  // Kept for source compatibility with the current UI while the app is
  // migrated screen-by-screen to the composition root.
  static String? token;

  String? get currentToken => token;

  Future<void> setToken(String? value) async {
    token = value?.trim().isEmpty == true ? null : value?.trim();
    final store = _tokenStore;
    if (store == null) return;
    final next = token;
    if (next == null) {
      await store.clear();
    } else {
      await store.write(next);
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query, retrySafe: true);

  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> delete(String path) =>
      _request('DELETE', path);

  Future<String> uploadFile(
    String path, {
    required String field,
    String endpoint = 'uploads',
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers());
    request.files.add(await http.MultipartFile.fromPath(field, path));

    try {
      final streamed = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decode(response.body);
      _throwForStatus(response, decoded);
      final url = decoded is Map ? decoded['url']?.toString().trim() : null;
      if (url == null || url.isEmpty) {
        throw const ApiException('Sunucu dosya adresi döndürmedi.');
      }
      return url;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException('Dosya yükleme zaman aşımına uğradı.', cause: e);
    } on http.ClientException catch (e) {
      throw NetworkException('Sunucuya bağlanılamadı.', cause: e);
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool retrySafe = false,
  }) async {
    final maxAttempts = retrySafe ? 2 : 1;
    AppException? last;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final uri = _buildUri(path, query: query);
        final headers = await _headers();
        if (body != null) {
          headers['Content-Type'] = 'application/json; charset=UTF-8';
        }
        final request = http.Request(method, uri)..headers.addAll(headers);
        if (body != null) request.body = jsonEncode(body);

        final streamed = await _client
            .send(request)
            .timeout(_requestTimeout);
        final response = await http.Response.fromStream(streamed);
        final decoded = _decode(response.body);
        _throwForStatus(response, decoded);
        return decoded;
      } on AppException catch (e) {
        last = e;
        if (!_shouldRetry(e, attempt, maxAttempts)) rethrow;
      } on TimeoutException catch (e) {
        last = ApiException('İstek zaman aşımına uğradı.', cause: e);
        if (attempt == maxAttempts) throw last;
      } on SocketException catch (e) {
        last = ApiException('Sunucuya bağlanılamadı.', cause: e);
        if (attempt == maxAttempts) throw last;
      } on http.ClientException catch (e) {
        last = ApiException('Ağ isteği başarısız oldu.', cause: e);
        if (attempt == maxAttempts) throw last;
      }

      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }

    throw last ?? const ApiException('İstek başarısız oldu.');
  }

  Uri _buildUri(String path, {Map<String, String>? query}) {
    final clean = path.replaceFirst(RegExp(r'^/+'), '');
    final base = Uri.parse('$_baseUrl/$clean');
    return query == null || query.isEmpty
        ? base
        : base.replace(queryParameters: {
            ...base.queryParameters,
            ...query,
          });
  }

  Future<Map<String, String>> _headers() async {
    var authToken = token;
    final tokenStore = _tokenStore;
    if ((authToken == null || authToken.isEmpty) && tokenStore != null) {
      authToken = await tokenStore.read();
      token = authToken;
    }
    final requestId = _requestId();
    return <String, String>{
      'Accept': 'application/json',
      'X-Request-Id': requestId,
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
  }

  static String _requestId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${Object().hashCode.toRadixString(16)}';

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{'message': 'Sunucudan geçersiz JSON döndü.'};
    }
  }

  static void _throwForStatus(http.Response response, dynamic decoded) {
    if (response.statusCode >= 200 && response.statusCode < 400) return;

    final message = decoded is Map
        ? decoded['message']?.toString()
        : null;
    final requestId = response.headers['x-request-id'];
    final text = (message == null || message.isEmpty)
        ? 'Sunucu isteği reddetti (${response.statusCode}).'
        : message;
    throw switch (response.statusCode) {
      401 => UnauthorizedException(text, cause: requestId),
      >= 500 => ServerException(text, statusCode: response.statusCode, cause: requestId),
      _ => ApiException(text, statusCode: response.statusCode, cause: requestId),
    };
  }

  static bool _shouldRetry(
    AppException e,
    int attempt,
    int maxAttempts,
  ) {
    if (attempt >= maxAttempts) return false;
    if (e.statusCode == null) return true;
    return e.statusCode! == 408 || e.statusCode! == 429 || e.statusCode! >= 500;
  }

  Future<void> close() async => _client.close();
}
