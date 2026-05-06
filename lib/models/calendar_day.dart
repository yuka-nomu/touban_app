import 'package:hive/hive.dart';

const Object _unset = Object();

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.memberId,
    required this.isActive,
    required this.eventText,
  });

  final DateTime date;
  final String? memberId;
  final bool isActive;
  final String eventText;

  CalendarDay copyWith({
    DateTime? date,
    Object? memberId = _unset,
    bool? isActive,
    String? eventText,
  }) {
    return CalendarDay(
      date: date ?? this.date,
      memberId: memberId == _unset ? this.memberId : memberId as String?,
      isActive: isActive ?? this.isActive,
      eventText: eventText ?? this.eventText,
    );
  }
}

class CalendarDayAdapter extends TypeAdapter<CalendarDay> {
  @override
  final int typeId = 2;

  @override
  CalendarDay read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return CalendarDay(
      date: fields[0] as DateTime,
      memberId: fields[1] as String?,
      isActive: fields[2] as bool,
      eventText: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarDay obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.eventText);
  }
}
