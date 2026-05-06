import 'package:flutter/material.dart';

import '../models/calendar_day.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key, DateTime? month})
    : month = DateTime(
        (month ?? DateTime.now()).year,
        (month ?? DateTime.now()).month,
      );

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${month.year}年${month.month}月 当番表')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: CalendarGrid(month: month, days: _currentMonthDays()),
        ),
      ),
    );
  }

  List<CalendarDay> _currentMonthDays() {
    final int dayCount = DateUtils.getDaysInMonth(month.year, month.month);

    return <CalendarDay>[
      for (int day = 1; day <= dayCount; day++)
        _calendarDay(DateTime(month.year, month.month, day)),
    ];
  }

  CalendarDay _calendarDay(DateTime date) {
    final bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return CalendarDay(
      date: date,
      memberId: null,
      isActive: !isWeekend,
      eventText: '',
    );
  }
}
