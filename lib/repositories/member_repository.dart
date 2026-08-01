import 'package:hive/hive.dart';

import '../models/member.dart';
import '../models/member_setting.dart';
import 'repository_exception.dart';

class MemberRepository {
  MemberRepository({Box<Member>? box}) : _box = box;

  static const String boxName = 'members';

  Box<Member>? _box;

  Future<void> init() async {
    try {
      _box ??= await Hive.openBox<Member>(boxName);
    } catch (error) {
      throw RepositoryException(
        'Failed to initialize member repository.',
        error,
      );
    }
  }

  Future<List<Member>> getAll() async {
    try {
      final Box<Member> box = await _ensureBox();
      final List<Member> members = box.values.toList();
      members.sort((Member a, Member b) => a.sortOrder.compareTo(b.sortOrder));
      return members;
    } catch (error) {
      throw RepositoryException('Failed to load members.', error);
    }
  }

  Future<Member?> getById(String id) async {
    try {
      final Box<Member> box = await _ensureBox();
      return box.get(id);
    } catch (error) {
      throw RepositoryException('Failed to load member.', error);
    }
  }

  Future<void> save(Member member) async {
    try {
      final Box<Member> box = await _ensureBox();
      await box.put(member.id, member);
    } catch (error) {
      throw RepositoryException('Failed to save member.', error);
    }
  }

  Future<void> saveAll(List<Member> members) async {
    try {
      final Box<Member> box = await _ensureBox();
      await box.putAll(<String, Member>{
        for (final Member member in members) member.id: member,
      });
    } catch (error) {
      throw RepositoryException('Failed to save members.', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      final Box<Member> box = await _ensureBox();
      await box.delete(id);
    } catch (error) {
      throw RepositoryException('Failed to delete member.', error);
    }
  }

  Future<void> clear() async {
    try {
      final Box<Member> box = await _ensureBox();
      await box.clear();
    } catch (error) {
      throw RepositoryException('Failed to clear members.', error);
    }
  }

  Future<Box<Member>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }
}

class MemberSettingsRepository {
  MemberSettingsRepository({Box<MemberSetting>? box, Box<String>? selectionBox})
    : _box = box,
      _selectionBox = selectionBox;

  static const String boxName = 'member_settings';
  static const String selectionBoxName = 'member_setting_selection';
  static const String selectedSettingKey = 'selected_member_setting_id';

  Box<MemberSetting>? _box;
  Box<String>? _selectionBox;

  Future<void> init() async {
    try {
      _box ??= await Hive.openBox<MemberSetting>(boxName);
      _selectionBox ??= await Hive.openBox<String>(selectionBoxName);
    } catch (error) {
      throw RepositoryException(
        'Failed to initialize member setting repository.',
        error,
      );
    }
  }

  Future<List<MemberSetting>> getAll() async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      final List<MemberSetting> settings = box.values.toList();
      settings.sort(
        (MemberSetting a, MemberSetting b) => a.sortOrder.compareTo(b.sortOrder),
      );
      return settings;
    } catch (error) {
      throw RepositoryException('Failed to load member settings.', error);
    }
  }

  Future<MemberSetting?> getById(String id) async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      return box.get(id);
    } catch (error) {
      throw RepositoryException('Failed to load member setting.', error);
    }
  }

  Future<void> save(MemberSetting setting) async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      await box.put(setting.id, setting);
    } catch (error) {
      throw RepositoryException('Failed to save member setting.', error);
    }
  }

  Future<void> saveAll(List<MemberSetting> settings) async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      await box.putAll(<String, MemberSetting>{
        for (final MemberSetting setting in settings) setting.id: setting,
      });
    } catch (error) {
      throw RepositoryException('Failed to save member settings.', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      await box.delete(id);
    } catch (error) {
      throw RepositoryException('Failed to delete member setting.', error);
    }
  }

  Future<void> clear() async {
    try {
      final Box<MemberSetting> box = await _ensureBox();
      await box.clear();
    } catch (error) {
      throw RepositoryException('Failed to clear member settings.', error);
    }
  }

  Future<String?> getSelectedSettingId() async {
    try {
      final Box<String> box = await _ensureSelectionBox();
      return box.get(selectedSettingKey);
    } catch (error) {
      throw RepositoryException('Failed to load selected member setting.', error);
    }
  }

  Future<void> selectSetting(String id) async {
    try {
      final Box<String> box = await _ensureSelectionBox();
      await box.put(selectedSettingKey, id);
    } catch (error) {
      throw RepositoryException('Failed to save selected member setting.', error);
    }
  }

  Future<List<Member>> getSelectedMembers() async {
    final List<MemberSetting> settings = await getAll();
    if (settings.isEmpty) {
      return const <Member>[];
    }

    final String? selectedId = await getSelectedSettingId();
    final MemberSetting currentSetting = settings.firstWhere(
      (MemberSetting setting) => setting.id == selectedId,
      orElse: () => settings.first,
    );

    final List<Member> members = <Member>[...currentSetting.members];
    members.sort((Member a, Member b) => a.sortOrder.compareTo(b.sortOrder));
    return members;
  }

  Future<Box<MemberSetting>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  Future<Box<String>> _ensureSelectionBox() async {
    if (_selectionBox == null || !_selectionBox!.isOpen) {
      await init();
    }
    return _selectionBox!;
  }
}
