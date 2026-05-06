import '../models/calendar_day.dart';
import '../models/member.dart';
import '../models/month_schedule.dart';

class AssignmentService {
  const AssignmentService();

  MonthSchedule generateMonthlySchedule({
    required int year,
    required int month,
    required List<Member> members,
    required String startMemberId,
  }) {
    if (members.isEmpty) {
      throw ArgumentError.value(
        members,
        'members',
        'Members must not be empty.',
      );
    }

    final List<Member> orderedMembers = <Member>[...members]
      ..sort((Member a, Member b) => a.sortOrder.compareTo(b.sortOrder));
    final int startIndex = orderedMembers.indexWhere(
      (Member member) => member.id == startMemberId,
    );
    if (startIndex == -1) {
      throw ArgumentError.value(
        startMemberId,
        'startMemberId',
        'Start member must exist in members.',
      );
    }

    final int dayCount = DateTime(year, month + 1, 0).day;
    int assignmentIndex = startIndex;
    final List<CalendarDay> days = <CalendarDay>[];

    for (int day = 1; day <= dayCount; day++) {
      final DateTime date = DateTime(year, month, day);
      final bool isActive = _isAssignmentDay(date);
      final String? memberId;

      if (isActive) {
        memberId = orderedMembers[assignmentIndex].id;
        assignmentIndex = (assignmentIndex + 1) % orderedMembers.length;
      } else {
        memberId = null;
      }

      days.add(
        CalendarDay(
          date: date,
          memberId: memberId,
          isActive: isActive,
          eventText: '',
        ),
      );
    }

    return MonthSchedule(
      year: year,
      month: month,
      startMemberId: startMemberId,
      days: days,
    );
  }

  bool _isAssignmentDay(DateTime date) {
    return date.weekday != DateTime.saturday &&
        date.weekday != DateTime.sunday &&
        !isJapaneseHoliday(date);
  }

  bool isJapaneseHoliday(DateTime date) {
    return _japaneseHolidayDates(date.year).contains(_dateOnly(date));
  }

  Set<DateTime> _japaneseHolidayDates(int year) {
    final Set<DateTime> holidays = _baseJapaneseHolidayDates(year);
    final Set<DateTime> expanded = <DateTime>{...holidays};

    for (final DateTime holiday in holidays) {
      if (holiday.weekday == DateTime.sunday) {
        DateTime substitute = holiday.add(const Duration(days: 1));
        while (expanded.contains(_dateOnly(substitute))) {
          substitute = substitute.add(const Duration(days: 1));
        }
        expanded.add(_dateOnly(substitute));
      }
    }

    for (int dayOfYear = 2; dayOfYear <= 365; dayOfYear++) {
      final DateTime date = DateTime(year, 1, dayOfYear);
      if (date.year != year) {
        break;
      }
      final DateTime previous = date.subtract(const Duration(days: 1));
      final DateTime next = date.add(const Duration(days: 1));
      if (!expanded.contains(_dateOnly(date)) &&
          expanded.contains(_dateOnly(previous)) &&
          expanded.contains(_dateOnly(next))) {
        expanded.add(_dateOnly(date));
      }
    }

    return expanded;
  }

  Set<DateTime> _baseJapaneseHolidayDates(int year) {
    final Set<DateTime> holidays = <DateTime>{
      DateTime(year, 1, 1),
      DateTime(year, 2, 11),
      DateTime(year, 3, _vernalEquinoxDay(year)),
      DateTime(year, 5, 3),
      DateTime(year, 5, 5),
      DateTime(year, 9, _autumnalEquinoxDay(year)),
      DateTime(year, 11, 3),
      DateTime(year, 11, 23),
    };

    if (year >= 2000) {
      holidays.add(_nthMonday(year, 1, 2));
    } else {
      holidays.add(DateTime(year, 1, 15));
    }

    if (year >= 2020) {
      holidays.add(DateTime(year, 2, 23));
    } else if (year >= 1989 && year <= 2018) {
      holidays.add(DateTime(year, 12, 23));
    }

    if (year >= 2007) {
      holidays.add(DateTime(year, 4, 29));
      holidays.add(DateTime(year, 5, 4));
    } else {
      holidays.add(DateTime(year, 4, 29));
      if (year >= 1986) {
        holidays.add(DateTime(year, 5, 4));
      }
    }

    if (year == 2020) {
      holidays
        ..add(DateTime(year, 7, 23))
        ..add(DateTime(year, 7, 24))
        ..add(DateTime(year, 8, 10));
    } else if (year == 2021) {
      holidays
        ..add(DateTime(year, 7, 22))
        ..add(DateTime(year, 7, 23))
        ..add(DateTime(year, 8, 8));
    } else {
      if (year >= 2003) {
        holidays.add(_nthMonday(year, 7, 3));
      } else if (year >= 1996) {
        holidays.add(DateTime(year, 7, 20));
      }
      if (year >= 2016) {
        holidays.add(DateTime(year, 8, 11));
      }
    }

    if (year >= 2003) {
      holidays.add(_nthMonday(year, 9, 3));
    } else {
      holidays.add(DateTime(year, 9, 15));
    }

    if (year == 2020) {
      holidays.add(DateTime(year, 7, 24));
    } else if (year == 2021) {
      holidays.add(DateTime(year, 7, 23));
    } else if (year >= 2000) {
      holidays.add(_nthMonday(year, 10, 2));
    } else {
      holidays.add(DateTime(year, 10, 10));
    }

    return holidays.map(_dateOnly).toSet();
  }

  DateTime _nthMonday(int year, int month, int nth) {
    DateTime date = DateTime(year, month);
    while (date.weekday != DateTime.monday) {
      date = date.add(const Duration(days: 1));
    }
    return date.add(Duration(days: 7 * (nth - 1)));
  }

  int _vernalEquinoxDay(int year) {
    if (year <= 1979) {
      return (20.8357 + 0.242194 * (year - 1980) - ((year - 1983) ~/ 4))
          .floor();
    }
    if (year <= 2099) {
      return (20.8431 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4))
          .floor();
    }
    return (21.851 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4)).floor();
  }

  int _autumnalEquinoxDay(int year) {
    if (year <= 1979) {
      return (23.2588 + 0.242194 * (year - 1980) - ((year - 1983) ~/ 4))
          .floor();
    }
    if (year <= 2099) {
      return (23.2488 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4))
          .floor();
    }
    return (24.2488 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4)).floor();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
