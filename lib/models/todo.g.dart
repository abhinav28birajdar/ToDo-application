// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      isCompleted: fields[3] as bool,
      creationDate: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      categoryId: fields[6] as String?,
      priority: fields[7] as int,
      tags: (fields[8] as List).cast<String>(),
      hasNotification: fields[9] as bool,
      notificationTime: fields[10] as DateTime?,
      completionDate: fields[11] as DateTime?,
      notes: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.creationDate)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.hasNotification)
      ..writeByte(10)
      ..write(obj.notificationTime)
      ..writeByte(11)
      ..write(obj.completionDate)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
