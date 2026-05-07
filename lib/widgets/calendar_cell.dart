import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../providers/schedule_provider.dart';

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
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _dateColor(colorScheme, isSunday, isSaturday),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _DraggableMemberName(day: day, memberName: memberName),
            ),
          ),
          SizedBox(
            height: 16,
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

class _DraggableMemberName extends ConsumerWidget {
  const _DraggableMemberName({required this.day, required this.memberName});

  final CalendarDay day;
  final String? memberName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget name = SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          memberName ?? '',
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    return DragTarget<CalendarDay>(
      onWillAcceptWithDetails: (DragTargetDetails<CalendarDay> details) {
        return _canSwap(details.data);
      },
      onAcceptWithDetails: (DragTargetDetails<CalendarDay> details) {
        final ScheduleMonth month = ScheduleMonth.fromDate(day.date);
        ref
            .read(scheduleProvider(month).notifier)
            .swapMembers(details.data, day);
      },
      builder:
          (
            BuildContext context,
            List<CalendarDay?> candidateData,
            List<dynamic> rejectedData,
          ) {
            if (!_hasMember) {
              return name;
            }

            return LongPressDraggable<CalendarDay>(
              data: day,
              feedback: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      memberName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: name),
              child: name,
            );
          },
    );
  }

  bool _canSwap(CalendarDay sourceDay) {
    return _hasMember &&
        sourceDay.memberId != null &&
        !DateUtils.isSameDay(sourceDay.date, day.date);
  }

  bool get _hasMember =>
      day.memberId != null && (memberName?.isNotEmpty ?? false);
}
