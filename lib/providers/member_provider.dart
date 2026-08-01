import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/member.dart';
import '../models/member_setting.dart';
import '../repositories/member_repository.dart';

final Provider<MemberRepository> memberRepositoryProvider =
    Provider<MemberRepository>((Ref ref) {
      return MemberRepository();
    });

final Provider<MemberSettingsRepository> memberSettingsRepositoryProvider =
    Provider<MemberSettingsRepository>((Ref ref) {
      return MemberSettingsRepository();
    });

final StateProvider<String?> selectedMemberSettingIdProvider =
    StateProvider<String?>((Ref ref) => null);

final AsyncNotifierProvider<MemberSettingsNotifier, List<MemberSetting>>
memberSettingsProvider = AsyncNotifierProvider<MemberSettingsNotifier, List<MemberSetting>>(
  MemberSettingsNotifier.new,
);

final AsyncNotifierProvider<MemberNotifier, List<Member>> memberProvider =
    AsyncNotifierProvider<MemberNotifier, List<Member>>(MemberNotifier.new);

class MemberSettingsNotifier extends AsyncNotifier<List<MemberSetting>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<MemberSetting>> build() async {
    final List<MemberSetting> settings = await ref
        .read(memberSettingsRepositoryProvider)
        .getAll();

    if (settings.isEmpty) {
      ref.read(selectedMemberSettingIdProvider.notifier).state = null;
      return const <MemberSetting>[];
    }

    final String? selectedId = await ref
        .read(memberSettingsRepositoryProvider)
        .getSelectedSettingId();
    final String resolvedId = settings.any(
              (MemberSetting setting) => setting.id == selectedId,
            )
            ? selectedId!
            : settings.first.id;

    await ref.read(memberSettingsRepositoryProvider).selectSetting(resolvedId);
    ref.read(selectedMemberSettingIdProvider.notifier).state = resolvedId;
    return settings;
  }

  Future<void> addSetting(String name) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final List<MemberSetting> currentSettings = await future;
    final MemberSetting setting = MemberSetting(
      id: _uuid.v4(),
      name: trimmedName,
      members: const <Member>[],
      sortOrder: currentSettings.length,
    );

    final List<MemberSetting> updatedSettings = <MemberSetting>[...
      currentSettings,
      setting,
    ];

    await ref.read(memberSettingsRepositoryProvider).save(setting);
    await ref.read(memberSettingsRepositoryProvider).selectSetting(setting.id);
    ref.read(selectedMemberSettingIdProvider.notifier).state = setting.id;
    state = AsyncData<List<MemberSetting>>(updatedSettings);
    ref.invalidate(memberProvider);
  }

  Future<void> deleteSetting(String id) async {
    final List<MemberSetting> currentSettings = await future;
    final List<MemberSetting> updatedSettings = currentSettings
        .where((MemberSetting setting) => setting.id != id)
        .toList();
    final List<MemberSetting> orderedSettings = _withSortOrder(updatedSettings);

    await ref.read(memberSettingsRepositoryProvider).delete(id);
    await ref.read(memberSettingsRepositoryProvider).saveAll(orderedSettings);

    if (orderedSettings.isEmpty) {
      await ref.read(memberSettingsRepositoryProvider).selectSetting('');
      ref.read(selectedMemberSettingIdProvider.notifier).state = null;
    } else {
      final String nextSettingId = orderedSettings.first.id;
      await ref.read(memberSettingsRepositoryProvider).selectSetting(nextSettingId);
      ref.read(selectedMemberSettingIdProvider.notifier).state = nextSettingId;
    }

    state = AsyncData<List<MemberSetting>>(orderedSettings);
    ref.invalidate(memberProvider);
  }

  Future<void> selectSetting(String id) async {
    final List<MemberSetting> currentSettings = await future;
    if (!currentSettings.any((MemberSetting setting) => setting.id == id)) {
      return;
    }

    await ref.read(memberSettingsRepositoryProvider).selectSetting(id);
    ref.read(selectedMemberSettingIdProvider.notifier).state = id;
    ref.invalidate(memberProvider);
  }

  List<MemberSetting> _withSortOrder(List<MemberSetting> settings) {
    return <MemberSetting>[
      for (int index = 0; index < settings.length; index++)
        settings[index].copyWith(sortOrder: index),
    ];
  }
}

class MemberNotifier extends AsyncNotifier<List<Member>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Member>> build() async {
    final List<MemberSetting> allSettings = await ref.watch(
      memberSettingsProvider.future,
    );
    final String? selectedId = ref.watch(selectedMemberSettingIdProvider);

    if (allSettings.isEmpty) {
      return const <Member>[];
    }

    final MemberSetting selectedSetting = allSettings.firstWhere(
      (MemberSetting setting) => setting.id == selectedId,
      orElse: () => allSettings.first,
    );

    final List<Member> members = <Member>[...selectedSetting.members];
    members.sort((Member a, Member b) => a.sortOrder.compareTo(b.sortOrder));
    return members;
  }

  Future<void> addMember(String name) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final String? selectedSettingId = ref.read(selectedMemberSettingIdProvider);
    if (selectedSettingId == null) {
      return;
    }

    final List<MemberSetting> currentSettings = await ref.read(
      memberSettingsProvider.future,
    );
    final int settingIndex = currentSettings.indexWhere(
      (MemberSetting setting) => setting.id == selectedSettingId,
    );
    if (settingIndex == -1) {
      return;
    }

    final MemberSetting currentSetting = currentSettings[settingIndex];
    final List<Member> currentMembers = <Member>[...currentSetting.members];
    final Member member = Member(
      id: _uuid.v4(),
      name: trimmedName,
      sortOrder: currentMembers.length,
    );

    final MemberSetting updatedSetting = currentSetting.copyWith(
      members: <Member>[...currentMembers, member],
    );
    final List<MemberSetting> updatedSettings = <MemberSetting>[...currentSettings];
    updatedSettings[settingIndex] = updatedSetting;

    await ref.read(memberSettingsRepositoryProvider).save(updatedSetting);
    ref.read(memberSettingsProvider.notifier).state = AsyncData<List<MemberSetting>>(
      updatedSettings,
    );
    state = AsyncData<List<Member>>(<Member>[...currentMembers, member]);
  }

  Future<void> deleteMember(String id) async {
    final String? selectedSettingId = ref.read(selectedMemberSettingIdProvider);
    if (selectedSettingId == null) {
      return;
    }

    final List<MemberSetting> currentSettings = await ref.read(
      memberSettingsProvider.future,
    );
    final int settingIndex = currentSettings.indexWhere(
      (MemberSetting setting) => setting.id == selectedSettingId,
    );
    if (settingIndex == -1) {
      return;
    }

    final MemberSetting currentSetting = currentSettings[settingIndex];
    final List<Member> currentMembers = <Member>[...currentSetting.members];
    final List<Member> updatedMembers = currentMembers
        .where((Member member) => member.id != id)
        .toList();
    final List<Member> orderedMembers = _withSortOrder(updatedMembers);

    final MemberSetting updatedSetting = currentSetting.copyWith(
      members: orderedMembers,
    );
    final List<MemberSetting> updatedSettings = <MemberSetting>[...currentSettings];
    updatedSettings[settingIndex] = updatedSetting;

    await ref.read(memberSettingsRepositoryProvider).save(updatedSetting);
    ref.read(memberSettingsProvider.notifier).state = AsyncData<List<MemberSetting>>(
      updatedSettings,
    );
    state = AsyncData<List<Member>>(orderedMembers);
  }

  Future<void> reorderMembers(int oldIndex, int newIndex) async {
    final String? selectedSettingId = ref.read(selectedMemberSettingIdProvider);
    if (selectedSettingId == null) {
      return;
    }

    final List<MemberSetting> currentSettings = await ref.read(
      memberSettingsProvider.future,
    );
    final int settingIndex = currentSettings.indexWhere(
      (MemberSetting setting) => setting.id == selectedSettingId,
    );
    if (settingIndex == -1) {
      return;
    }

    final MemberSetting currentSetting = currentSettings[settingIndex];
    final List<Member> currentMembers = <Member>[...currentSetting.members];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final Member movedMember = currentMembers.removeAt(oldIndex);
    currentMembers.insert(newIndex, movedMember);
    final List<Member> orderedMembers = _withSortOrder(currentMembers);

    final MemberSetting updatedSetting = currentSetting.copyWith(
      members: orderedMembers,
    );
    final List<MemberSetting> updatedSettings = <MemberSetting>[...currentSettings];
    updatedSettings[settingIndex] = updatedSetting;

    await ref.read(memberSettingsRepositoryProvider).save(updatedSetting);
    ref.read(memberSettingsProvider.notifier).state = AsyncData<List<MemberSetting>>(
      updatedSettings,
    );
    state = AsyncData<List<Member>>(orderedMembers);
  }

  List<Member> _withSortOrder(List<Member> members) {
    return <Member>[
      for (int index = 0; index < members.length; index++)
        members[index].copyWith(sortOrder: index),
    ];
  }
}
