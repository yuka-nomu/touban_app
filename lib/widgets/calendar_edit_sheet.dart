import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_day.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';
import '../providers/schedule_provider.dart';

class CalendarEditSheet extends ConsumerStatefulWidget {
  const CalendarEditSheet({super.key, required this.day});

  final CalendarDay day;

  @override
  ConsumerState<CalendarEditSheet> createState() => _CalendarEditSheetState();
}

class _CalendarEditSheetState extends ConsumerState<CalendarEditSheet> {
  late bool _isActive;
  late String? _memberId;
  late TextEditingController _eventTextController;

  @override
  void initState() {
    super.initState();
    _isActive = widget.day.isActive;
    _memberId = widget.day.memberId;
    _eventTextController = TextEditingController(text: widget.day.eventText);
  }

  @override
  void dispose() {
    _eventTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          top: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: members.when(
          data: (List<Member> memberList) => _buildForm(context, memberList),
          error: (Object error, StackTrace stackTrace) {
            return Text('読み込みに失敗しました: $error');
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Member> members) {
    final bool hasSelectedMember = members.any(
      (Member member) => member.id == _memberId,
    );
    final String? selectedMemberId = hasSelectedMember ? _memberId : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('当番編集', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedMemberId,
          decoration: const InputDecoration(
            labelText: '当番者',
            border: OutlineInputBorder(),
          ),
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
          onChanged: _isActive
              ? (String? value) {
                  setState(() {
                    _memberId = value;
                  });
                }
              : null,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('対象日'),
          value: _isActive,
          onChanged: (bool value) {
            setState(() {
              _isActive = value;
              if (!value) {
                _memberId = null;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _eventTextController,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: 'イベント',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Future<void> _save() async {
    final CalendarDay updatedDay = widget.day.copyWith(
      memberId: _isActive ? _memberId : null,
      isActive: _isActive,
      eventText: _eventTextController.text.trim(),
    );
    final ScheduleMonth month = ScheduleMonth.fromDate(widget.day.date);

    await ref.read(scheduleProvider(month).notifier).updateDay(updatedDay);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(updatedDay);
  }
}
