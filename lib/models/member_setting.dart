import 'package:hive/hive.dart';

import 'member.dart';

class MemberSetting {
  const MemberSetting({
    required this.id,
    required this.name,
    required this.members,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final List<Member> members;
  final int sortOrder;

  MemberSetting copyWith({
    String? id,
    String? name,
    List<Member>? members,
    int? sortOrder,
  }) {
    return MemberSetting(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class MemberSettingAdapter extends TypeAdapter<MemberSetting> {
  @override
  final int typeId = 2;

  @override
  MemberSetting read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return MemberSetting(
      id: fields[0] as String,
      name: fields[1] as String,
      members: (fields[2] as List).cast<Member>(),
      sortOrder: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MemberSetting obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.members)
      ..writeByte(3)
      ..write(obj.sortOrder);
  }
}
