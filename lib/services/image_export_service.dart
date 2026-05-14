import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/calendar_day.dart';

class ImageExportService {
  const ImageExportService();

  Future<String> exportCalendar({
    required DateTime month,
    required List<CalendarDay> days,
    required Map<String, String> memberNamesById,
    required ThemeData theme,
  }) async {
    final ScreenshotController controller = ScreenshotController();
    final Uint8List imageBytes = await controller.captureFromWidget(
      _ExportCalendarImage(
        month: month,
        days: days,
        memberNamesById: memberNamesById,
        theme: theme,
      ),
      pixelRatio: 2,
      targetSize: const Size(1200, 760),
    );

    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory exportDirectory = Directory('${directory.path}/exports');
    await exportDirectory.create(recursive: true);

    final String filePath =
        '${exportDirectory.path}/touban_${month.year}_${month.month.toString().padLeft(2, '0')}.png';
    final File file = File(filePath);
    await file.writeAsBytes(imageBytes, flush: true);

    return filePath;
  }
}

class _ExportCalendarImage extends StatelessWidget {
  const _ExportCalendarImage({
    required this.month,
    required this.days,
    required this.memberNamesById,
    required this.theme,
  });

  final DateTime month;
  final List<CalendarDay> days;
  final Map<String, String> memberNamesById;
  final ThemeData theme;

  static const double _width = 1200;
  static const double _height = 760;
  static const double _padding = 32;
  static const double _headerHeight = 42;
  static const double _weekdayHeight = 28;
  static const double _cellGap = 4;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(_width, _height)),
        child: Theme(
          data: theme,
          child: Container(
            width: _width,
            height: _height,
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: _headerHeight,
                  child: Center(
                    child: Text(
                      '${month.year}年${month.month}月 見守り当番表',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _ExportWeekdayHeader(),
                const SizedBox(height: _cellGap),
                Expanded(
                  child: _ExportCalendarGrid(
                    month: month,
                    days: days,
                    memberNamesById: memberNamesById,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportWeekdayHeader extends StatelessWidget {
  const _ExportWeekdayHeader();

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _ExportCalendarImage._weekdayHeight,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < _weekdays.length; index++)
            Expanded(
              child: Center(
                child: Text(
                  _weekdays[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _weekdayColor(colorScheme, index),
                  ),
                ),
              ),
            ),
        ],
      ),
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

class _ExportCalendarGrid extends StatelessWidget {
  const _ExportCalendarGrid({
    required this.month,
    required this.days,
    required this.memberNamesById,
  });

  final DateTime month;
  final List<CalendarDay> days;
  final Map<String, String> memberNamesById;

  @override
  Widget build(BuildContext context) {
    final int dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final int leadingEmptyCells = DateTime(month.year, month.month).weekday % 7;
    final int cellCount = leadingEmptyCells + dayCount;
    final int rowCount = (cellCount / 7).ceil();
    final Map<int, CalendarDay> daysByDay = <int, CalendarDay>{
      for (final CalendarDay day in days)
        if (day.date.year == month.year && day.date.month == month.month)
          day.date.day: day,
    };

    return Column(
      children: <Widget>[
        for (int row = 0; row < rowCount; row++) ...<Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                for (int column = 0; column < 7; column++) ...<Widget>[
                  Expanded(
                    child: _buildCell(
                      context,
                      row * 7 + column,
                      leadingEmptyCells,
                      dayCount,
                      daysByDay,
                    ),
                  ),
                  if (column != 6)
                    const SizedBox(width: _ExportCalendarImage._cellGap),
                ],
              ],
            ),
          ),
          if (row != rowCount - 1)
            const SizedBox(height: _ExportCalendarImage._cellGap),
        ],
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    int index,
    int leadingEmptyCells,
    int dayCount,
    Map<int, CalendarDay> daysByDay,
  ) {
    if (index < leadingEmptyCells || index >= leadingEmptyCells + dayCount) {
      return const SizedBox.shrink();
    }

    final int dayNumber = index - leadingEmptyCells + 1;
    final CalendarDay day = daysByDay[dayNumber] ?? _defaultDay(dayNumber);
    final String memberName = day.memberId == null
        ? ''
        : memberNamesById[day.memberId] ?? '';

    return _ExportCalendarCell(
      day: day,
      weekdayIndex: index % 7,
      memberName: memberName,
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

class _ExportCalendarCell extends StatelessWidget {
  const _ExportCalendarCell({
    required this.day,
    required this.weekdayIndex,
    required this.memberName,
  });

  final CalendarDay day;
  final int weekdayIndex;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: day.isActive
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${day.date.day}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _dateColor(colorScheme),
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  memberName,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                day.eventText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _dateColor(ColorScheme colorScheme) {
    if (weekdayIndex == 0) {
      return Colors.red;
    }
    if (weekdayIndex == 6) {
      return Colors.blue;
    }
    return colorScheme.onSurface;
  }
}
