/// A configured LLM server the app can talk to.
enum BackendType { anythingLlm, openai }

extension BackendTypeX on BackendType {
  String get label => switch (this) {
        BackendType.anythingLlm => 'AnythingLLM',
        BackendType.openai => 'OpenAI-compatible',
      };

  String get hint => switch (this) {
        BackendType.anythingLlm => 'e.g. http://localhost:3001',
        BackendType.openai => 'e.g. http://localhost:11434 (Ollama), LM Studio, vLLM…',
      };

  String get wire => name;

  static BackendType fromWire(String? s) =>
      BackendType.values.firstWhere((t) => t.name == s,
          orElse: () => BackendType.anythingLlm);
}

class Connection {
  final String id;
  String name;
  String baseUrl;
  String apiKey;
  BackendType type;

  /// Selected workspace slug (AnythingLLM) or model id (OpenAI-compatible).
  String? option;

  Connection({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.type,
    this.option,
  });

  Connection copy() => Connection(
        id: id,
        name: name,
        baseUrl: baseUrl,
        apiKey: apiKey,
        type: type,
        option: option,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'type': type.wire,
        'option': option,
      };

  factory Connection.fromJson(Map<String, dynamic> j) => Connection(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'Connection',
        baseUrl: (j['baseUrl'] as String?) ?? '',
        apiKey: (j['apiKey'] as String?) ?? '',
        type: BackendTypeX.fromWire(j['type'] as String?),
        option: j['option'] as String?,
      );
}
