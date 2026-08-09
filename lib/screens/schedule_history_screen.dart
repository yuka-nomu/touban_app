import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/member_setting.dart';
import '../models/month_schedule.dart';
import '../providers/member_provider.dart';
import '../providers/schedule_provider.dart';

class ScheduleHistoryScreen extends ConsumerWidget {
  const ScheduleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MonthSchedule>> schedules = ref.watch(
      scheduleHistoryProvider,
    );
    final AsyncValue<List<MemberSetting>> settings = ref.watch(
      memberSettingsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存したカレンダー'),
        leading: IconButton(
          tooltip: 'ホーム',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: schedules.when(
        data: (List<MonthSchedule> scheduleList) {
          if (scheduleList.isEmpty) {
            return const Center(child: Text('保存したカレンダーはありません'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scheduleList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final MonthSchedule schedule = scheduleList[index];
              final String? memberListName = _memberListName(
                schedule,
                settings.valueOrNull ?? const <MemberSetting>[],
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text('${schedule.year}年${schedule.month}月'),
                  subtitle: Text(memberListName ?? 'メンバーリスト不明'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'カレンダーを削除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteSchedule(context, ref, schedule),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.go(
                    '/calendar?year=${schedule.year}&month=${schedule.month}',
                  ),
                ),
              );
            },
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text('履歴の読み込みに失敗しました: $error'));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String? _memberListName(
    MonthSchedule schedule,
    List<MemberSetting> settings,
  ) {
    for (final MemberSetting setting in settings) {
      if (setting.members.any(
        (member) => member.id == schedule.startMemberId,
      )) {
        return setting.name;
      }
    }
    return null;
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    MonthSchedule schedule,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カレンダーを削除'),
          content: Text('${schedule.year}年${schedule.month}月のカレンダーを削除しますか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(scheduleRepositoryProvider).delete(
        schedule.year,
        schedule.month,
      );
      ref.invalidate(scheduleHistoryProvider);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('カレンダーの削除に失敗しました: $error')));
    }
  }
}
