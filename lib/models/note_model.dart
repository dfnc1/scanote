/// Model data catatan Scanote sesuai kontrak REST API.
class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  /// Parsing JSON secara aman terhadap field null dan format tanggal ISO 8601.
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawDate = json['created_at']?.toString();
    final parsedDate =
        rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return NoteModel(
      id: parsedId,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: parsedDate,
    );
  }

  /// Hanya mengirim title dan content sesuai payload create/update di API.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
