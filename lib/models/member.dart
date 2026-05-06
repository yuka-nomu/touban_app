import 'package:hive/hive.dart';

class Member {
  const Member({required this.id, required this.name, required this.sortOrder});

  final String id;
  final String name;
  final int sortOrder;

  Member copyWith({String? id, String? name, int? sortOrder}) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 1;

  @override
  Member read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return Member(
      id: fields[0] as String,
      name: fields[1] as String,
      sortOrder: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sortOrder);
  }
}
