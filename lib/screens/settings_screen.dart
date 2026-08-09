import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/member.dart';
import '../models/member_setting.dart';
import '../providers/member_provider.dart';
import '../widgets/member_list_item.dart';
import '../widgets/member_name_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MemberSetting>> settings = ref.watch(
      memberSettingsProvider,
    );
    final AsyncValue<List<Member>> members = ref.watch(memberProvider);
    final String? selectedSettingId = ref.watch(
      selectedMemberSettingIdProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('メンバー設定'),
        leading: IconButton(
          tooltip: 'ホーム',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: settings.when(
        data: (List<MemberSetting> settingsList) {
          if (settingsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('メンバーリストがありません'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddSettingDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('メンバーリストを追加'),
                  ),
                ],
              ),
            );
          }

          final MemberSetting currentSetting = settingsList.firstWhere(
            (MemberSetting setting) => setting.id == selectedSettingId,
            orElse: () => settingsList.first,
          );

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: <Widget>[
                    const Text('メンバーリスト名'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownField(
                        child: DropdownButton<String>(
                          value: currentSetting.id,
                          isExpanded: true,
                          items: <DropdownMenuItem<String>>[
                            for (final MemberSetting setting in settingsList)
                              DropdownMenuItem<String>(
                                value: setting.id,
                                child: Text(setting.name),
                              ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              ref
                                  .read(memberSettingsProvider.notifier)
                                  .selectSetting(value);
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'メンバーリストを追加',
                      icon: const Icon(Icons.playlist_add),
                      onPressed: () => _showAddSettingDialog(context, ref),
                    ),
                    IconButton(
                      tooltip: 'リストを削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _deleteSetting(context, ref, currentSetting.id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: <Widget>[const Text('メンバー')]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: members.when(
                  data: (List<Member> memberList) {
                    if (memberList.isEmpty) {
                      return const Center(child: Text('メンバーが登録されていません'));
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: memberList.length,
                      onReorderItem: (int oldIndex, int newIndex) {
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
                            ref
                                .read(memberProvider.notifier)
                                .deleteMember(member.id);
                          },
                        );
                      },
                    );
                  },
                  error: (Object error, StackTrace stackTrace) {
                    return Center(child: Text('読み込みに失敗しました: $error'));
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text('読み込みに失敗しました: $error'));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: settings.hasValue
            ? () => _showAddMemberDialog(context, ref)
            : null,
        tooltip: 'メンバーを追加',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  Future<void> _showAddSettingDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _SettingNameDialog(),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await ref.read(memberSettingsProvider.notifier).addSetting(name);
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const MemberNameDialog(),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      final bool added = await ref
          .read(memberProvider.notifier)
          .addMember(name);
      if (!added && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('同じ名前のメンバーは登録できません')));
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('メンバーの登録に失敗しました: $error')));
    }
  }

  Future<void> _deleteSetting(
    BuildContext context,
    WidgetRef ref,
    String settingId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('設定を削除'),
          content: const Text('このメンバー設定を削除しますか？'),
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

    await ref.read(memberSettingsProvider.notifier).deleteSetting(settingId);
  }
}

class _SettingNameDialog extends StatefulWidget {
  const _SettingNameDialog();

  @override
  State<_SettingNameDialog> createState() => _SettingNameDialogState();
}

class _SettingNameDialogState extends State<_SettingNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メンバー設定を追加'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '設定名'),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }
}
