import 'package:flutter/material.dart';

import '../models/calendar_day.dart';
import 'calendar_cell.dart';

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.days,
    this.memberNamesById = const <String, String>{},
    this.onDayTap,
  });

  final DateTime month;
  final List<CalendarDay> days;
  final Map<String, String> memberNamesById;
  final ValueChanged<CalendarDay>? onDayTap;

  static const List<String> _weekdays = <String>[
    '日',
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
  ];

  @override
  Widget build(BuildContext context) {
    final Map<int, CalendarDay> daysByDay = <int, CalendarDay>{
      for (final CalendarDay day in days)
        if (day.date.year == month.year && day.date.month == month.month)
          day.date.day: day,
    };
    final int dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final int leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;

    return Column(
      children: <Widget>[
        const _WeekdayHeader(labels: _weekdays),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingEmptyCells + dayCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: CalendarCell.height,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index < leadingEmptyCells) {
              return const SizedBox.shrink();
            }

            final int dayNumber = index - leadingEmptyCells + 1;
            final CalendarDay day =
                daysByDay[dayNumber] ?? _defaultDay(dayNumber);
            final String? memberName = day.memberId == null
                ? null
                : memberNamesById[day.memberId];

            return InkWell(
              onTap: onDayTap == null ? null : () => onDayTap!(day),
              borderRadius: BorderRadius.circular(4),
              child: CalendarCell(
                day: day,
                weekdayIndex: index % 7,
                memberName: memberName,
              ),
            );
          },
        ),
      ],
    );
  }

  CalendarDay _defaultDay(int dayNumber) {
    final DateTime date = DateTime(month.year, month.month, dayNumber);
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

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        for (int index = 0; index < labels.length; index++)
          Expanded(
            child: Center(
              child: Text(
                labels[index],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _weekdayColor(colorScheme, index),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _weekdayColor(ColorScheme colorScheme, int index) {
    if (index == 0) {
      return Colors.red;
    }
    if (index == 6) {
      return Colors.blue;
    }
    return colorScheme.onSurface;
  }
}
