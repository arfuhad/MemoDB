import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin client for the PKM backend. Clients never touch the DB — only this API.
class ApiClient {
  final http.Client _http;
  ApiClient([http.Client? client]) : _http = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.apiToken}',
      };

  Uri _u(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${AppConfig.apiBase}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<CaptureResult> capture(String text, {String? title, List<String> tags = const []}) async {
    final resp = await _http.post(
      _u('/capture'),
      headers: _headers,
      body: jsonEncode({'text': text, 'title': title, 'tags': tags}),
    );
    _ensure(resp, 201);
    return CaptureResult.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<SearchHit>> search(String query, {int limit = 10}) async {
    final resp = await _http.get(_u('/search', {'q': query, 'limit': limit}), headers: _headers);
    _ensure(resp, 200);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['hits'] as List)
        .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentDetail> document(String id) async {
    final resp = await _http.get(_u('/documents/$id'), headers: _headers);
    _ensure(resp, 200);
    return DocumentDetail.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<NoteItem>> documents({int limit = 50}) async {
    final resp = await _http.get(
        _u('/documents', {'limit': limit}), headers: _headers);
    _ensure(resp, 200);
    return (jsonDecode(resp.body) as List)
        .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> suggestTitle(String text) async {
    final resp = await _http.post(
      _u('/suggest-title'),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
    _ensure(resp, 200);
    return (jsonDecode(resp.body) as Map<String, dynamic>)['title'] as String;
  }

  Future<NoteItem> updateDocument(String id, String text, {String? title, List<String> tags = const []}) async {
    final resp = await _http.put(
      _u('/documents/$id'),
      headers: _headers,
      body: jsonEncode({'text': text, 'title': title, 'tags': tags}),
    );
    _ensure(resp, 200);
    return NoteItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> deleteDocument(String id) async {
    final resp = await _http.delete(_u('/documents/$id'), headers: _headers);
    _ensure(resp, 204);
  }

  Future<bool> health() async {
    try {
      final resp = await _http.get(_u('/health'));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  Future<BackendConfig> getConfig() async {
    final resp = await _http.get(_u('/config'), headers: _headers);
    _ensure(resp, 200);
    return BackendConfig.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<BackendConfig> updateConfig(BackendConfig config) async {
    final resp = await _http.put(
      _u('/config'),
      headers: _headers,
      body: jsonEncode(config.toJson()),
    );
    _ensure(resp, 200);
    return BackendConfig.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  void _ensure(http.Response resp, int expected) {
    if (resp.statusCode != expected) {
      throw ApiException(resp.statusCode, resp.body);
    }
  }
}
