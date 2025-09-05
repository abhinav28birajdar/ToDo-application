import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String id;
  String title;
  String content;
  bool isFavorite;
  String? userId;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    String? id,
    required this.title,
    this.content = '',
    this.isFavorite = false,
    this.userId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Creates a copy of the note with specified fields updated
  Note copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    String? userId,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Note(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Create a Note from a map/JSON object
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  // Convert Note to a map/JSON object for database storage
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  // For Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_favorite': isFavorite,
      'user_id': userId,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a Note from Supabase
  factory Note.fromSupabase(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      isFavorite: map['is_favorite'] as bool? ?? false,
      userId: map['user_id'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Utility methods
  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  String get preview {
    if (content.isEmpty) return '';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}
