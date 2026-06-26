import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/connection.dart';

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => message;
}

/// A workspace (AnythingLLM) or model (OpenAI-compatible) the user can chat with.
class LlmOption {
  final String id;
  final String label;
  const LlmOption(this.id, this.label);
}

class ChatTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  const ChatTurn(this.role, this.content);
}

abstract class LlmClient {
  final Connection conn;
  LlmClient(this.conn);

  factory LlmClient.of(Connection c) => switch (c.type) {
        BackendType.anythingLlm => _AnythingLlmClient(c),
        BackendType.openai => _OpenAiClient(c),
      };

  /// Throws [LlmException] if the server is unreachable or auth fails.
  Future<void> test();

  /// Lists workspaces (AnythingLLM) or models (OpenAI-compatible).
  Future<List<LlmOption>> listOptions();

  /// Sends [history] (oldest first) and returns the assistant reply text.
  Future<String> send(List<ChatTurn> history, String optionId);

  String get _base {
    var b = conn.baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (conn.apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${conn.apiKey.trim()}',
      };

  Uri _uri(String path) {
    if (_base.isEmpty) {
      throw LlmException('Server URL is empty. Edit the connection and add one.');
    }
    try {
      return Uri.parse('$_base$path');
    } catch (_) {
      throw LlmException('Invalid server URL: "$_base"');
    }
  }
}

class _AnythingLlmClient extends LlmClient {
  _AnythingLlmClient(super.conn);

  @override
  Future<void> test() async {
    final r = await _get('/api/v1/auth');
    final body = _json(r);
    if (body is Map && body['authenticated'] == false) {
      throw LlmException('Server rejected the API key (not authenticated).');
    }
  }

  @override
  Future<List<LlmOption>> listOptions() async {
    final r = await _get('/api/v1/workspaces');
    final body = _json(r);
    final list = (body is Map ? body['workspaces'] : null);
    if (list is! List) return const [];
    return [
      for (final w in list)
        if (w is Map && w['slug'] != null)
          LlmOption(w['slug'].toString(),
              (w['name'] ?? w['slug']).toString()),
    ];
  }

  @override
  Future<String> send(List<ChatTurn> history, String optionId) async {
    final last = history.isNotEmpty ? history.last.content : '';
    final r = await _post('/api/v1/workspace/$optionId/chat', {
      'message': last,
      'mode': 'chat',
    });
    final body = _json(r);
    if (body is Map) {
      if (body['error'] != null && body['error'] != false) {
        throw LlmException(body['error'].toString());
      }
      final text = body['textResponse'];
      if (text is String) return text;
    }
    throw LlmException('Unexpected response from AnythingLLM.');
  }

  Future<http.Response> _get(String path) => _send(() =>
      http.get(_uri(path), headers: _headers));

  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_uri(path),
          headers: _headers, body: jsonEncode(body)));
}

class _OpenAiClient extends LlmClient {
  _OpenAiClient(super.conn);

  String get _apiBase => _base.endsWith('/v1') ? _base : '$_base/v1';

  @override
  Future<void> test() async {
    await _send(() => http.get(Uri.parse('$_apiBase/models'), headers: _headers));
  }

  @override
  Future<List<LlmOption>> listOptions() async {
    final r = await _send(
        () => http.get(Uri.parse('$_apiBase/models'), headers: _headers));
    final body = _json(r);
    final list = (body is Map ? body['data'] : null);
    if (list is! List) return const [];
    return [
      for (final m in list)
        if (m is Map && m['id'] != null)
          LlmOption(m['id'].toString(), m['id'].toString()),
    ];
  }

  @override
  Future<String> send(List<ChatTurn> history, String optionId) async {
    final r = await _send(() => http.post(
          Uri.parse('$_apiBase/chat/completions'),
          headers: _headers,
          body: jsonEncode({
            'model': optionId,
            'messages': [
              for (final t in history) {'role': t.role, 'content': t.content},
            ],
          }),
        ));
    final body = _json(r);
    if (body is Map) {
      final choices = body['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices.first['message'];
        if (msg is Map && msg['content'] is String) {
          return msg['content'] as String;
        }
      }
      if (body['error'] != null) {
        final e = body['error'];
        throw LlmException(e is Map ? '${e['message']}' : e.toString());
      }
    }
    throw LlmException('Unexpected response from the server.');
  }
}

/// Shared HTTP execution + error mapping for all clients.
extension on LlmClient {
  Future<http.Response> _send(Future<http.Response> Function() run) async {
    http.Response r;
    try {
      r = await run().timeout(const Duration(seconds: 60));
    } catch (e) {
      throw LlmException('Could not reach ${conn.baseUrl}: $e');
    }
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw LlmException('Authentication failed (HTTP ${r.statusCode}). '
          'Check the API key.');
    }
    if (r.statusCode == 404) {
      throw LlmException('Endpoint not found (HTTP 404). '
          'Check the server URL and backend type.');
    }
    if (r.statusCode >= 400) {
      throw LlmException('Server error HTTP ${r.statusCode}: '
          '${r.body.isEmpty ? '(no body)' : r.body}');
    }
    return r;
  }

  dynamic _json(http.Response r) {
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } catch (_) {
      throw LlmException('Server returned a non-JSON response.');
    }
  }
}
