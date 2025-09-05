import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

// Part directive for Hive's and JSON's generated code.
part 'category.g.dart';

// Manually implementing JSON serialization
@HiveType(typeId: 1) // Unique ID for Category model
class Category extends HiveObject {
  @HiveField(0)
  @JsonKey(includeToJson: true)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  int colorValue; // Store color as int value

  @HiveField(4)
  @JsonKey(includeFromJson: false, includeToJson: false)
  IconData iconData; // Store icon data

  @HiveField(5)
  @JsonKey(name: 'created_at')
  DateTime createdAt;

  @HiveField(6)
  bool isDefault; // Whether this is a default category

  @HiveField(7)
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  @HiveField(8)
  @JsonKey(name: 'user_id')
  String? userId;

  @HiveField(9)
  String? icon; // Store icon as string name

  Category({
    String? id,
    required this.name,
    this.description = '',
    required this.colorValue,
    required this.iconData,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDefault = false,
    this.userId,
    this.icon,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // For creating from color instead of colorValue
  factory Category.withColor({
    String? id,
    required String name,
    String description = '',
    required Color color,
    required IconData iconData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isDefault = false,
    String? userId,
    String? icon,
  }) {
    return Category(
      id: id,
      name: name,
      description: description,
      colorValue: color.value,
      iconData: iconData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDefault: isDefault,
      userId: userId,
      icon: icon,
    );
  }

  // Get Color object from colorValue
  Color get color => Color(colorValue);

  // Set color from Color object
  set color(Color newColor) => colorValue = newColor.value;

  Category copyWith({
    String? name,
    String? description,
    int? colorValue,
    IconData? iconData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    String? userId,
    String? icon,
  }) {
    return Category(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconData: iconData ?? this.iconData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      icon: icon ?? this.icon,
    );
  }

  // Create a Category from a map/JSON object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int,
      iconData: Icons
          .folder, // Default icon - would need a way to map string to IconData
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      userId: json['user_id'] as String?,
      icon: json['icon'] as String?,
    );
  }

  // Convert Category to a map/JSON object for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'created_at': createdAt.toIso8601String(),
      'isDefault': isDefault,
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'icon': icon,
    };
  }

  // For Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': '#${colorValue.toRadixString(16).substring(2).toUpperCase()}',
      'user_id': userId,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_default': isDefault,
    };
  }

  // Create a Category from Supabase
  factory Category.fromSupabase(Map<String, dynamic> map) {
    // Convert hex color string to int color value
    String hexColor = map['color'] as String? ?? '#7D8D86';
    hexColor = hexColor.replaceFirst('#', '');
    final colorValue = int.parse('FF$hexColor', radix: 16);

    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      colorValue: colorValue,
      iconData: Icons
          .folder, // Default icon - would need a way to map string to IconData
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDefault: map['is_default'] as bool? ?? false,
      userId: map['user_id'] as String?,
      icon: map['icon'] as String?,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, isDefault: $isDefault}';
  }
}
