import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import '../providers/member_provider.dart';
import '../widgets/member_list_item.dart';
import '../widgets/member_name_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: members.when(
        data: (List<Member> memberList) {
          if (memberList.isEmpty) {
            return const Center(child: Text('名前が登録されていません'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: memberList.length,
            onReorder: (int oldIndex, int newIndex) {
              ref
                  .read(memberProvider.notifier)
                  .reorderMembers(oldIndex, newIndex);
            },
            itemBuilder: (BuildContext context, int index) {
              final Member member = memberList[index];
              return MemberListItem(
                key: ValueKey<String>(member.id),
                member: member,
                index: index,
                onDelete: () {
                  ref.read(memberProvider.notifier).deleteMember(member.id);
                },
              );
            },
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text('読み込みに失敗しました: $error'));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(context, ref),
        tooltip: '追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const MemberNameDialog(),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await ref.read(memberProvider.notifier).addMember(name);
  }
}
