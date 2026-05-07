import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../models/month_schedule.dart';
import '../repositories/schedule_repository.dart';

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

    final int sourceIndex = currentSchedule.days.indexWhere(
      (CalendarDay day) => DateUtils.isSameDay(day.date, sourceDay.date),
    );
    final int targetIndex = currentSchedule.days.indexWhere(
      (CalendarDay day) => DateUtils.isSameDay(day.date, targetDay.date),
    );
    if (sourceIndex == -1 || targetIndex == -1) {
      return;
    }

    final CalendarDay currentSourceDay = currentSchedule.days[sourceIndex];
    final CalendarDay currentTargetDay = currentSchedule.days[targetIndex];
    if (currentSourceDay.memberId == null ||
        currentTargetDay.memberId == null) {
      return;
    }

    final List<CalendarDay> days = <CalendarDay>[...currentSchedule.days];
    days[sourceIndex] = currentSourceDay.copyWith(
      memberId: currentTargetDay.memberId,
    );
    days[targetIndex] = currentTargetDay.copyWith(
      memberId: currentSourceDay.memberId,
    );

    final MonthSchedule nextSchedule = currentSchedule.copyWith(days: days);
    await ref.read(scheduleRepositoryProvider).save(nextSchedule);
    state = AsyncData<MonthSchedule?>(nextSchedule);
  }

  MonthSchedule _updateSchedule(
    MonthSchedule? currentSchedule,
    CalendarDay updatedDay,
  ) {
    final List<CalendarDay> days = <CalendarDay>[
      ...?currentSchedule?.days.where(
        (CalendarDay day) => !DateUtils.isSameDay(day.date, updatedDay.date),
      ),
      updatedDay,
    ]..sort((CalendarDay a, CalendarDay b) => a.date.compareTo(b.date));

    return MonthSchedule(
      year: arg.year,
      month: arg.month,
      startMemberId:
          currentSchedule?.startMemberId ?? updatedDay.memberId ?? '',
      days: days,
    );
  }
}

class DateUtils {
  const DateUtils._();

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
