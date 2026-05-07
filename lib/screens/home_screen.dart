import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/member.dart';
import '../models/month_schedule.dart';
import '../providers/member_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/assignment_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _selectedMonth;
  String? _selectedMemberId;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('登校班当番表')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: members.when(
            data: (List<Member> memberList) => _HomeContent(
              selectedMonth: _selectedMonth,
              selectedMemberId: _validSelectedMemberId(memberList),
              members: memberList,
              isGenerating: _isGenerating,
              onMonthChanged: (DateTime month) {
                setState(() {
                  _selectedMonth = month;
                });
              },
              onMemberChanged: (String? memberId) {
                setState(() {
                  _selectedMemberId = memberId;
                });
              },
              onGenerate:
                  _validSelectedMemberId(memberList) == null || _isGenerating
                  ? null
                  : () => _generateSchedule(memberList),
              onOpenSettings: () => context.go('/settings'),
            ),
            error: (Object error, StackTrace stackTrace) {
              return Center(child: Text('読み込みに失敗しました: $error'));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  String? _validSelectedMemberId(List<Member> members) {
    final bool containsSelection = members.any(
      (Member member) => member.id == _selectedMemberId,
    );
    if (containsSelection) {
      return _selectedMemberId;
    }
    if (members.isEmpty) {
      return null;
    }
    return members.first.id;
  }

  Future<void> _generateSchedule(List<Member> members) async {
    final String? startMemberId = _validSelectedMemberId(members);
    if (startMemberId == null) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final MonthSchedule schedule = const AssignmentService()
          .generateMonthlySchedule(
            year: _selectedMonth.year,
            month: _selectedMonth.month,
            members: members,
            startMemberId: startMemberId,
          );
      final ScheduleMonth scheduleMonth = ScheduleMonth.fromDate(
        _selectedMonth,
      );

      await ref.read(scheduleRepositoryProvider).save(schedule);
      ref.invalidate(scheduleProvider(scheduleMonth));

      if (!mounted) {
        return;
      }
      context.go(
        '/calendar?year=${_selectedMonth.year}&month=${_selectedMonth.month}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('当番表の生成に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.selectedMonth,
    required this.selectedMemberId,
    required this.members,
    required this.isGenerating,
    required this.onMonthChanged,
    required this.onMemberChanged,
    required this.onGenerate,
    required this.onOpenSettings,
  });

  final DateTime selectedMonth;
  final String? selectedMemberId;
  final List<Member> members;
  final bool isGenerating;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String?> onMemberChanged;
  final VoidCallback? onGenerate;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> months = _selectableMonths();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('対象月'),
        const SizedBox(height: 8),
        _DropdownField(
          child: DropdownButton<DateTime>(
            value: selectedMonth,
            isExpanded: true,
            items: <DropdownMenuItem<DateTime>>[
              for (final DateTime month in months)
                DropdownMenuItem<DateTime>(
                  value: month,
                  child: Text(_formatMonth(month)),
                ),
            ],
            onChanged: (DateTime? month) {
              if (month != null) {
                onMonthChanged(month);
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text('開始メンバー'),
        const SizedBox(height: 8),
        _DropdownField(
          child: DropdownButton<String>(
            value: selectedMemberId,
            isExpanded: true,
            hint: const Text('メンバーを登録してください'),
            items: <DropdownMenuItem<String>>[
              for (final Member member in members)
                DropdownMenuItem<String>(
                  value: member.id,
                  child: Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: members.isEmpty ? null : onMemberChanged,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onGenerate,
          child: Text(isGenerating ? '生成中...' : '当番表を生成'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onOpenSettings, child: const Text('設定')),
      ],
    );
  }

  List<DateTime> _selectableMonths() {
    final DateTime now = DateTime.now();
    return <DateTime>[
      for (int index = 0; index < 12; index++)
        DateTime(now.year, now.month + index),
    ];
  }

  String _formatMonth(DateTime month) {
    return '${month.year}年${month.month}月';
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
