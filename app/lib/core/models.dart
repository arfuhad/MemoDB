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
