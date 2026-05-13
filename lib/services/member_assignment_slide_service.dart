import '../models/calendar_day.dart';

class MemberAssignmentSlideService {
  const MemberAssignmentSlideService();

  List<CalendarDay> moveMember({
    required List<CalendarDay> days,
    required DateTime sourceDate,
    required DateTime targetDate,
  }) {
    final List<int> assignedIndexes = <int>[
      for (int index = 0; index < days.length; index++)
        if (days[index].memberId != null) index,
    ];
    final int sourcePosition = assignedIndexes.indexWhere(
      (int index) => _isSameDay(days[index].date, sourceDate),
    );
    final int targetPosition = assignedIndexes.indexWhere(
      (int index) => _isSameDay(days[index].date, targetDate),
    );

    if (sourcePosition == -1 ||
        targetPosition == -1 ||
        sourcePosition == targetPosition) {
      return <CalendarDay>[...days];
    }

    final List<String> memberIds = <String>[
      for (final int index in assignedIndexes) days[index].memberId!,
    ];
    final String movedMemberId = memberIds.removeAt(sourcePosition);
    memberIds.insert(targetPosition, movedMemberId);

    final List<CalendarDay> updatedDays = <CalendarDay>[...days];
    for (int position = 0; position < assignedIndexes.length; position++) {
      final int dayIndex = assignedIndexes[position];
      updatedDays[dayIndex] = updatedDays[dayIndex].copyWith(
        memberId: memberIds[position],
      );
    }

    return updatedDays;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
