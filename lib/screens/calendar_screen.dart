import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../models/member.dart';
import '../models/month_schedule.dart';
import '../providers/member_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/calendar_edit_sheet.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends ConsumerWidget {
  CalendarScreen({super.key, DateTime? month})
    : month = DateTime(
        (month ?? DateTime.now()).year,
        (month ?? DateTime.now()).month,
      );

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScheduleMonth scheduleMonth = ScheduleMonth.fromDate(month);
    final AsyncValue<MonthSchedule?> schedule = ref.watch(
      scheduleProvider(scheduleMonth),
    );
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${month.year}年${month.month}月 当番表')),
      body: SafeArea(
        child: schedule.when(
          data: (MonthSchedule? monthSchedule) {
            final List<Member> memberList = members.valueOrNull ?? <Member>[];
            final Map<String, String> memberNamesById = <String, String>{
              for (final Member member in memberList) member.id: member.name,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: CalendarGrid(
                month: month,
                days: monthSchedule?.days ?? const <CalendarDay>[],
                memberNamesById: memberNamesById,
                onDayTap: (CalendarDay day) => _showEditSheet(context, day),
              ),
            );
          },
          error: (Object error, StackTrace stackTrace) {
            return Center(child: Text('読み込みに失敗しました: $error'));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, CalendarDay day) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return CalendarEditSheet(day: day);
      },
    );
  }
}
