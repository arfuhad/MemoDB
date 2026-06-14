class SearchHit {
  final String documentId;
  final String title;
  final String snippet;
  final double score;
  final int? vectorRank;
  final int? keywordRank;

  SearchHit({
    required this.documentId,
    required this.title,
    required this.snippet,
    required this.score,
    this.vectorRank,
    this.keywordRank,
  });

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        documentId: j['document_id'] as String,
        title: j['title'] as String,
        snippet: j['snippet'] as String? ?? '',
        score: (j['score'] as num).toDouble(),
        vectorRank: j['vector_rank'] as int?,
        keywordRank: j['keyword_rank'] as int?,
      );

  bool get matchedSemantically => vectorRank != null;
  bool get matchedKeyword => keywordRank != null;
}

class DocumentDetail {
  final String id;
  final String title;
  final String bodyText;
  final List<String> tags;
  final DateTime createdAt;

  DocumentDetail({
    required this.id,
    required this.title,
    required this.bodyText,
    required this.tags,
    required this.createdAt,
  });

  factory DocumentDetail.fromJson(Map<String, dynamic> j) => DocumentDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        bodyText: j['body_text'] as String? ?? '',
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class CaptureResult {
  final String id;
  final String title;
  CaptureResult({required this.id, required this.title});
  factory CaptureResult.fromJson(Map<String, dynamic> j) =>
      CaptureResult(id: j['id'] as String, title: j['title'] as String);
}

class NoteItem {
  final String id;
  final String title;
  final List<String> tags;
  final String preview;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.tags,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteItem.fromJson(Map<String, dynamic> j) => NoteItem(
        id: j['id'] as String,
        title: j['title'] as String,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        preview: j['preview'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class BackendConfig {
  final String titleProvider;
  final String titleModel;
  final String titleApiUrl;
  final String titleApiKey;
  final String embedder;
  final String apiEmbedUrl;
  final String apiEmbedKey;
  final String apiEmbedModel;
  final String ollamaUrl;
  BackendConfig({
    required this.titleProvider,
    required this.titleModel,
    required this.titleApiUrl,
    required this.titleApiKey,
    required this.embedder,
    required this.apiEmbedUrl,
    required this.apiEmbedKey,
    required this.apiEmbedModel,
    required this.ollamaUrl,
  });
  factory BackendConfig.fromJson(Map<String, dynamic> j) => BackendConfig(
        titleProvider: j['title_provider'] as String? ?? 'ollama',
        titleModel: j['title_model'] as String? ?? '',
        titleApiUrl: j['title_api_url'] as String? ?? '',
        titleApiKey: j['title_api_key'] as String? ?? '',
        embedder: j['embedder'] as String? ?? 'ollama',
        apiEmbedUrl: j['api_embed_url'] as String? ?? '',
        apiEmbedKey: j['api_embed_key'] as String? ?? '',
        apiEmbedModel: j['api_embed_model'] as String? ?? '',
        ollamaUrl: j['ollama_url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title_provider': titleProvider,
        'title_model': titleModel,
        'title_api_url': titleApiUrl,
        'title_api_key': titleApiKey,
        'embedder': embedder,
        'api_embed_url': apiEmbedUrl,
        'api_embed_key': apiEmbedKey,
        'api_embed_model': apiEmbedModel,
        'ollama_url': ollamaUrl,
      };
}
