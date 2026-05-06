import 'package:flutter/material.dart';

import '../models/calendar_day.dart';

class CalendarCell extends StatelessWidget {
  const CalendarCell({
    super.key,
    required this.day,
    required this.weekdayIndex,
    this.memberName,
  });

  final CalendarDay day;
  final int weekdayIndex;
  final String? memberName;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isSunday = weekdayIndex == 0;
    final bool isSaturday = weekdayIndex == 6;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
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
              fontWeight: FontWeight.w600,
              color: _dateColor(colorScheme, isSunday, isSaturday),
            ),
          ),
          const SizedBox(height: 4),
          if (memberName != null && memberName!.isNotEmpty)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    memberName!,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          if (day.eventText.isNotEmpty)
            Text(
              day.eventText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Color _dateColor(ColorScheme colorScheme, bool isSunday, bool isSaturday) {
    if (isSunday) {
      return Colors.red;
    }
    if (isSaturday) {
      return Colors.blue;
    }
    return colorScheme.onSurface;
  }
}
