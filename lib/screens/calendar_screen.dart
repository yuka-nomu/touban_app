import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/calendar_day.dart';
import '../models/member.dart';
import '../models/member_setting.dart';
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
  static const String _settingsBoxName = 'app_settings';
  static const String _calendarTutorialShownKey = 'calendar_tutorial_shown';

  bool _isExporting = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = _calendarTitle(widget.month);
    final ScheduleMonth scheduleMonth = ScheduleMonth.fromDate(widget.month);
    final AsyncValue<MonthSchedule?> schedule = ref.watch(
      scheduleProvider(scheduleMonth),
    );
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);
    final AsyncValue<List<MemberSetting>> settings = ref.watch(
      memberSettingsProvider,
    );
    final List<Member> memberList = members.valueOrNull ?? <Member>[];
    final Map<String, String> memberNamesById = <String, String>{
      for (final Member member in memberList) member.id: member.name,
    };
    final List<CalendarDay> days =
        schedule.valueOrNull?.days ?? const <CalendarDay>[];
    final String? memberListName = _memberListName(
      schedule.valueOrNull,
      settings.valueOrNull ?? const <MemberSetting>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title),
            if (memberListName != null)
              Text(
                memberListName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        leading: IconButton(
          tooltip: 'ホーム',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
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
                : () => _exportCalendar(
                    title,
                    widget.month,
                    days,
                    memberNamesById,
                  ),
          ),
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
            IconButton(
              tooltip: '画像を共有',
              icon: _isSharing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              onPressed: schedule.isLoading || _isExporting || _isSharing
                  ? null
                  : () => _shareCalendar(
                      title,
                      widget.month,
                      days,
                      memberNamesById,
                    ),
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

  String _calendarTitle(DateTime month) {
    return '${month.year}年${month.month}月 当番表';
  }

  String? _memberListName(
    MonthSchedule? schedule,
    List<MemberSetting> settings,
  ) {
    if (schedule == null) {
      return null;
    }
    for (final MemberSetting setting in settings) {
      if (setting.members.any(
        (Member member) => member.id == schedule.startMemberId,
      )) {
        return setting.name;
      }
    }
    return null;
  }

  Future<void> _showTutorialIfNeeded() async {
    try {
      final Box<bool> settingsBox = await Hive.openBox<bool>(_settingsBoxName);
      final bool hasShownTutorial = settingsBox.get(
        _calendarTutorialShownKey,
        defaultValue: false,
      )!;
      if (hasShownTutorial || !mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return const _CalendarTutorialDialog();
        },
      );
      await settingsBox.put(_calendarTutorialShownKey, true);
    } catch (_) {
      return;
    }
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
    String title,
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
        title: title,
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

  Future<void> _shareCalendar(
    String title,
    DateTime month,
    List<CalendarDay> days,
    Map<String, String> memberNamesById,
  ) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final String filePath = await const ImageExportService().exportCalendar(
        month: month,
        title: title,
        days: days,
        memberNamesById: memberNamesById,
        theme: Theme.of(context),
      );
      await SharePlus.instance.share(
        ShareParams(
          title: title,
          files: <XFile>[XFile(filePath, mimeType: 'image/png')],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像共有に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

class _CalendarTutorialDialog extends StatefulWidget {
  const _CalendarTutorialDialog();

  @override
  State<_CalendarTutorialDialog> createState() =>
      _CalendarTutorialDialogState();
}

class _CalendarTutorialDialogState extends State<_CalendarTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_TutorialStep> _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.touch_app_outlined,
      title: '日付をタップして編集',
      body: '担当者、対象日のON/OFF、イベントをBottomSheetで変更できます。',
    ),
    _TutorialStep(
      icon: Icons.drag_indicator,
      title: '名前を長押しして移動',
      body: 'メンバー名だけを長押しして別の日へ移動できます。イベントや日付は固定です。',
    ),
    _TutorialStep(
      icon: Icons.image_outlined,
      title: '画像として保存',
      body: '右上の画像ボタンから、現在の当番表をPNGとして保存できます。',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _steps.length - 1;

    return AlertDialog(
      title: const Text('カレンダーの使い方'),
      content: SizedBox(
        width: 320,
        height: 220,
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return _TutorialPage(step: _steps[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int index = 0; index < _steps.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentPage ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('スキップ'),
        ),
        FilledButton(
          onPressed: isLastPage ? _close : _nextPage,
          child: Text(isLastPage ? 'はじめる' : '次へ'),
        ),
      ],
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _close() {
    Navigator.of(context).pop();
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.step});

  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(step.icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          step.body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
