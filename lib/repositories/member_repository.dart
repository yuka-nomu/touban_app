import 'package:hive/hive.dart';

import '../models/member.dart';
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
