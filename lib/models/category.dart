import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

// Part directive for Hive's generated code.
part 'category.g.dart';

@HiveType(typeId: 1) // Unique ID for Category model
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  int colorValue; // Store color as int value

  @HiveField(4)
  IconData iconData; // Store icon data

  @HiveField(5)
  DateTime creationDate;

  @HiveField(6)
  bool isDefault; // Whether this is a default category

  Category({
    required this.id,
    required this.name,
    this.description = '',
    required this.colorValue,
    required this.iconData,
    required this.creationDate,
    this.isDefault = false,
  });

  // Get Color object from colorValue
  Color get color => Color(colorValue);

  // Set color from Color object
  set color(Color newColor) => colorValue = newColor.value;

  Category copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    IconData? iconData,
    DateTime? creationDate,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconData: iconData ?? this.iconData,
      creationDate: creationDate ?? this.creationDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, isDefault: $isDefault}';
  }
}
