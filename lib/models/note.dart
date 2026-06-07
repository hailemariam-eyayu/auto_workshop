class Note {
  final int? id;
  final String name;
  final String content;
  final String createdAt;
  final String updatedAt;

  Note({
    this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id,
    String? name,
    String? content,
    String? createdAt,
    String? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      content: map['content'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
