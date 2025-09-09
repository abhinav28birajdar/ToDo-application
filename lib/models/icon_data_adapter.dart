import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 2; // Must be unique

  @override
  IconData read(BinaryReader reader) {
    final codePoint = reader.readInt();
    final fontFamily = reader.readString();
    final fontPackage = reader.readString();
    final matchTextDirection = reader.readBool();

    return IconData(
      codePoint,
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontPackage: fontPackage.isEmpty ? null : fontPackage,
      matchTextDirection: matchTextDirection,
    );
  }

  @override
  void write(BinaryWriter writer, IconData obj) {
    writer.writeInt(obj.codePoint);
    writer.writeString(obj.fontFamily ?? '');
    writer.writeString(obj.fontPackage ?? '');
    writer.writeBool(obj.matchTextDirection);
  }
}
