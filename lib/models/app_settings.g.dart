// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: fields[0] as String,
      sortOrder: fields[1] as String,
      filterOption: fields[2] as String,
      notificationsEnabled: fields[3] as bool,
      autoBackup: fields[4] as bool,
      defaultPriority: fields[5] as int,
      showCompletedTodos: fields[6] as bool,
      dateFormat: fields[7] as String,
      timeFormat: fields[8] as String,
      confirmBeforeDelete: fields[9] as bool,
      reminderMinutesBefore: fields[10] as int,
      groupByCategory: fields[11] as bool,
      defaultCategoryId: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.sortOrder)
      ..writeByte(2)
      ..write(obj.filterOption)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.autoBackup)
      ..writeByte(5)
      ..write(obj.defaultPriority)
      ..writeByte(6)
      ..write(obj.showCompletedTodos)
      ..writeByte(7)
      ..write(obj.dateFormat)
      ..writeByte(8)
      ..write(obj.timeFormat)
      ..writeByte(9)
      ..write(obj.confirmBeforeDelete)
      ..writeByte(10)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(11)
      ..write(obj.groupByCategory)
      ..writeByte(12)
      ..write(obj.defaultCategoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
