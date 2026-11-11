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

/// Reusable HTTP boundary for the BEN API.
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

  static String? token;

  String? get currentToken => token;

  /// Headers used by image/video widgets loading protected media.
  Map<String, String> get authorizationHeaders => <String, String>{
        'Accept': '*/*',
        if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
      };

  /// Resolve a stored media URL on this configured API origin only.
  /// The host and path prefix from a stored absolute URL are never trusted.
  Uri resolveMediaUri(String value) {
    if (_baseUrl.isEmpty) {
      throw const ApiException('BEN sunucu adresi tanımlı değil.');
    }

    final source = Uri.tryParse(value.trim());
    if (source == null) {
      throw const ApiException('Medya adresi geçersiz.');
    }

    final segments = source.pathSegments;
    if (segments.length < 2 ||
        segments[segments.length - 2] != 'media' ||
        !RegExp(r'^[A-Za-z0-9._-]{1,200}$').hasMatch(segments.last)) {
      throw const ApiException(
        'Medya adresi BEN güvenli medya yoluna ait değil.',
      );
    }

    final configuredApi = Uri.parse(_baseUrl);
    final apiPath = configuredApi.path.replaceFirst(RegExp(r'/+$'), '');
    return configuredApi.replace(
      path: '$apiPath/media/${segments.last}',
      query: null,
      fragment: null,
    );
  }

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

  Future<dynamic> delete(String path) => _request('DELETE', path);

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
    } on TimeoutException catch (error) {
      throw ApiException('Dosya yükleme zaman aşımına uğradı.', cause: error);
    } on http.ClientException catch (error) {
      throw NetworkException('Sunucuya bağlanılamadı.', cause: error);
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
    AppException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final uri = _buildUri(path, query: query);
        final headers = await _headers();
        if (body != null) {
          headers['Content-Type'] = 'application/json; charset=UTF-8';
        }

        final request = http.Request(method, uri)..headers.addAll(headers);
        if (body != null) request.body = jsonEncode(body);

        final streamed = await _client.send(request).timeout(_requestTimeout);
        final response = await http.Response.fromStream(streamed);
        final decoded = _decode(response.body);
        _throwForStatus(response, decoded);
        return decoded;
      } on AppException catch (error) {
        lastError = error;
        if (!_shouldRetry(error, attempt, maxAttempts)) rethrow;
      } on TimeoutException catch (error) {
        lastError = ApiException('İstek zaman aşımına uğradı.', cause: error);
        if (attempt == maxAttempts) throw lastError;
      } on SocketException catch (error) {
        lastError = ApiException('Sunucuya bağlanılamadı.', cause: error);
        if (attempt == maxAttempts) throw lastError;
      } on http.ClientException catch (error) {
        lastError = ApiException('Ağ isteği başarısız oldu.', cause: error);
        if (attempt == maxAttempts) throw lastError;
      }

      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }

    throw lastError ?? const ApiException('İstek başarısız oldu.');
  }

  Uri _buildUri(String path, {Map<String, String>? query}) {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        'BEN sunucu adresi tanımlı değil. BEN_API_URL ayarını kontrol et.',
      );
    }

    final clean = path.replaceFirst(RegExp(r'^/+'), '');
    final base = Uri.parse('$_baseUrl/$clean');
    if (query == null || query.isEmpty) return base;

    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...query,
      },
    );
  }

  Future<Map<String, String>> _headers() async {
    var authToken = token;
    final tokenStore = _tokenStore;
    if ((authToken == null || authToken.isEmpty) && tokenStore != null) {
      authToken = await tokenStore.read();
      token = authToken;
    }

    return <String, String>{
      'Accept': 'application/json',
      'X-Request-Id': _requestId(),
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
  }

  static String _requestId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${Object().hashCode.toRadixString(16)}';

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{
        'message': 'Sunucudan geçersiz JSON döndü.',
      };
    }
  }

  static void _throwForStatus(http.Response response, dynamic decoded) {
    if (response.statusCode >= 200 && response.statusCode < 400) return;

    final message = decoded is Map ? decoded['message']?.toString() : null;
    final requestId = response.headers['x-request-id'];
    final text = message == null || message.isEmpty
        ? 'Sunucu isteği reddetti (${response.statusCode}).'
        : message;

    throw switch (response.statusCode) {
      401 => UnauthorizedException(text, cause: requestId),
      >= 500 => ServerException(
          text,
          statusCode: response.statusCode,
          cause: requestId,
        ),
      _ => ApiException(
          text,
          statusCode: response.statusCode,
          cause: requestId,
        ),
    };
  }

  static bool _shouldRetry(
    AppException error,
    int attempt,
    int maxAttempts,
  ) {
    if (attempt >= maxAttempts) return false;
    if (error.statusCode == null) return true;
    return error.statusCode == 408 ||
        error.statusCode == 429 ||
        error.statusCode! >= 500;
  }

  Future<void> close() async => _client.close();
}
