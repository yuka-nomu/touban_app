import 'package:hive/hive.dart';

import 'calendar_day.dart';

class MonthSchedule {
  const MonthSchedule({
    required this.year,
    required this.month,
    required this.startMemberId,
    required this.days,
  });

  final int year;
  final int month;
  final String startMemberId;
  final List<CalendarDay> days;

  MonthSchedule copyWith({
    int? year,
    int? month,
    String? startMemberId,
    List<CalendarDay>? days,
  }) {
    return MonthSchedule(
      year: year ?? this.year,
      month: month ?? this.month,
      startMemberId: startMemberId ?? this.startMemberId,
      days: days ?? this.days,
    );
  }
}

class MonthScheduleAdapter extends TypeAdapter<MonthSchedule> {
  @override
  final int typeId = 3;

  @override
  MonthSchedule read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return MonthSchedule(
      year: fields[0] as int,
      month: fields[1] as int,
      startMemberId: fields[2] as String,
      days: (fields[3] as List).cast<CalendarDay>(),
    );
  }

  @override
  void write(BinaryWriter writer, MonthSchedule obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.startMemberId)
      ..writeByte(3)
      ..write(obj.days);
  }
}
