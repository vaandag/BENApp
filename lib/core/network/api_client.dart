import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

/// Mevcut PHP REST sözleşmesi için tek erişim noktası.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static String? token;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<String> uploadFile(String path, {required String field, String endpoint = 'uploads'}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (token != null && token!.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(field, path));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    dynamic decoded;
    try { decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body); } catch (_) { decoded = {'message': response.body}; }
    if (response.statusCode < 200 || response.statusCode >= 400) throw ApiException((decoded is Map ? decoded['message'] : null)?.toString() ?? 'Dosya yükleme hatası (${response.statusCode})');
    final url = decoded is Map ? decoded['url']?.toString() : null;
    if (url == null || url.isEmpty) throw const ApiException('Sunucu dosya adresi döndürmedi.');
    return url;
  }

  Future<dynamic> _request(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/${path.replaceFirst(RegExp(r'^/+'), '')}')
        .replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json; charset=UTF-8';
    if (token != null && token!.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request).timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamed);
    dynamic decoded;
    try { decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body); } catch (_) { decoded = {'message': response.body}; }
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw ApiException((decoded is Map ? decoded['message'] : null)?.toString() ?? 'Sunucu hatası (${response.statusCode})');
    }
    return decoded;
  }
}
