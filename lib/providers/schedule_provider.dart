import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../models/month_schedule.dart';
import '../repositories/schedule_repository.dart';
import '../services/member_assignment_slide_service.dart';

final Provider<ScheduleRepository> scheduleRepositoryProvider =
    Provider<ScheduleRepository>((Ref ref) {
      return ScheduleRepository();
    });

final AsyncNotifierProviderFamily<
  ScheduleNotifier,
  MonthSchedule?,
  ScheduleMonth
>
scheduleProvider =
    AsyncNotifierProviderFamily<
      ScheduleNotifier,
      MonthSchedule?,
      ScheduleMonth
    >(ScheduleNotifier.new);

final FutureProvider<List<MonthSchedule>> scheduleHistoryProvider =
    FutureProvider<List<MonthSchedule>>((Ref ref) {
      return ref.read(scheduleRepositoryProvider).getAll();
    });

class ScheduleMonth {
  const ScheduleMonth({required this.year, required this.month});

  final int year;
  final int month;

  factory ScheduleMonth.fromDate(DateTime date) {
    return ScheduleMonth(year: date.year, month: date.month);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScheduleMonth &&
            runtimeType == other.runtimeType &&
            year == other.year &&
            month == other.month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

class ScheduleNotifier
    extends FamilyAsyncNotifier<MonthSchedule?, ScheduleMonth> {
  @override
  Future<MonthSchedule?> build(ScheduleMonth arg) {
    return ref.read(scheduleRepositoryProvider).getByMonth(arg.year, arg.month);
  }

  Future<void> updateDay(CalendarDay updatedDay) async {
    final MonthSchedule? currentSchedule = await future;
    final MonthSchedule nextSchedule = _updateSchedule(
      currentSchedule,
      updatedDay,
    );

    await ref.read(scheduleRepositoryProvider).save(nextSchedule);
    state = AsyncData<MonthSchedule?>(nextSchedule);
  }

  Future<void> swapMembers(CalendarDay sourceDay, CalendarDay targetDay) async {
    if (DateUtils.isSameDay(sourceDay.date, targetDay.date)) {
      return;
    }

    final MonthSchedule? currentSchedule = await future;
    if (currentSchedule == null) {
      return;
    }

    final List<CalendarDay> days = const MemberAssignmentSlideService()
        .moveMember(
          days: currentSchedule.days,
          sourceDate: sourceDay.date,
          targetDate: targetDay.date,
        );

    final MonthSchedule nextSchedule = currentSchedule.copyWith(days: days);
    await ref.read(scheduleRepositoryProvider).save(nextSchedule);
    state = AsyncData<MonthSchedule?>(nextSchedule);
  }

  MonthSchedule _updateSchedule(
    MonthSchedule? currentSchedule,
    CalendarDay updatedDay,
  ) {
    final List<CalendarDay> existingDays = <CalendarDay>[
      ...?currentSchedule?.days.where(
        (CalendarDay day) => !DateUtils.isSameDay(day.date, updatedDay.date),
      ),
      updatedDay,
    ]..sort((CalendarDay a, CalendarDay b) => a.date.compareTo(b.date));

    final List<CalendarDay> days =
        currentSchedule != null &&
            currentSchedule.days.any(
              (CalendarDay day) =>
                  DateUtils.isSameDay(day.date, updatedDay.date) &&
                  day.isActive &&
                  day.memberId != null &&
                  !updatedDay.isActive,
            )
        ? _shiftAssignmentsAfterDeactivation(currentSchedule.days, updatedDay)
        : existingDays;

    return MonthSchedule(
      year: arg.year,
      month: arg.month,
      startMemberId:
          currentSchedule?.startMemberId ?? updatedDay.memberId ?? '',
      days: days,
    );
  }

  List<CalendarDay> _shiftAssignmentsAfterDeactivation(
    List<CalendarDay> currentDays,
    CalendarDay updatedDay,
  ) {
    final List<CalendarDay> days = <CalendarDay>[...currentDays]
      ..sort((CalendarDay a, CalendarDay b) => a.date.compareTo(b.date));
    final int sourceIndex = days.indexWhere(
      (CalendarDay day) => DateUtils.isSameDay(day.date, updatedDay.date),
    );
    if (sourceIndex == -1) {
      return days;
    }

    final List<int> laterActiveIndexes = <int>[
      for (int index = sourceIndex + 1; index < days.length; index++)
        if (days[index].isActive) index,
    ];
    final List<String?> assignments = <String?>[
      days[sourceIndex].memberId,
      for (final int index in laterActiveIndexes) days[index].memberId,
    ];

    final List<CalendarDay> updatedDays = <CalendarDay>[
      for (int index = 0; index < days.length; index++)
        DateUtils.isSameDay(days[index].date, updatedDay.date)
            ? updatedDay
            : days[index],
    ];
    for (int offset = 0; offset < laterActiveIndexes.length; offset++) {
      final int dayIndex = laterActiveIndexes[offset];
      updatedDays[dayIndex] = updatedDays[dayIndex].copyWith(
        memberId: assignments[offset],
      );
    }
    return updatedDays;
  }
}

class DateUtils {
  const DateUtils._();

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
