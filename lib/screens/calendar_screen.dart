import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../models/member.dart';
import '../models/month_schedule.dart';
import '../providers/member_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/image_export_service.dart';
import '../widgets/calendar_edit_sheet.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  CalendarScreen({super.key, DateTime? month})
    : month = DateTime(
        (month ?? DateTime.now()).year,
        (month ?? DateTime.now()).month,
      );

  final DateTime month;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final ScheduleMonth scheduleMonth = ScheduleMonth.fromDate(widget.month);
    final AsyncValue<MonthSchedule?> schedule = ref.watch(
      scheduleProvider(scheduleMonth),
    );
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);
    final List<Member> memberList = members.valueOrNull ?? <Member>[];
    final Map<String, String> memberNamesById = <String, String>{
      for (final Member member in memberList) member.id: member.name,
    };
    final List<CalendarDay> days =
        schedule.valueOrNull?.days ?? const <CalendarDay>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.month.year}年${widget.month.month}月 当番表'),
        actions: <Widget>[
          IconButton(
            tooltip: '画像出力',
            icon: _isExporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
            onPressed: schedule.isLoading || _isExporting
                ? null
                : () => _exportCalendar(widget.month, days, memberNamesById),
          ),
        ],
      ),
      body: SafeArea(
        child: schedule.when(
          data: (MonthSchedule? monthSchedule) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: CalendarGrid(
                month: widget.month,
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

  Future<void> _exportCalendar(
    DateTime month,
    List<CalendarDay> days,
    Map<String, String> memberNamesById,
  ) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final String filePath = await const ImageExportService().exportCalendar(
        month: month,
        days: days,
        memberNamesById: memberNamesById,
        theme: Theme.of(context),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像を保存しました: $filePath')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像保存に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
