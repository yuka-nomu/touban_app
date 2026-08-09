import 'package:hive/hive.dart';

import '../models/month_schedule.dart';
import 'repository_exception.dart';

class ScheduleRepository {
  ScheduleRepository({Box<MonthSchedule>? box}) : _box = box;

  static const String boxName = 'schedules';

  Box<MonthSchedule>? _box;
  Future<void>? _initializing;

  Future<void> init() async {
    if (_box?.isOpen == true) {
      return;
    }
    if (_initializing != null) {
      return _initializing!;
    }

    final Future<void> initialization = _openBox();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      if (identical(_initializing, initialization)) {
        _initializing = null;
      }
    }
  }

  Future<void> _openBox() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box<MonthSchedule>(boxName);
      } else {
        _box = await Hive.openBox<MonthSchedule>(boxName);
      }
    } catch (error) {
      throw RepositoryException(
        'Failed to initialize schedule repository. Close other app instances and restart the app.',
        error,
      );
    }
  }

  Future<List<MonthSchedule>> getAll() async {
    try {
      final Box<MonthSchedule> box = await _ensureBox();
      final List<MonthSchedule> schedules = box.values.toList();
      schedules.sort((MonthSchedule a, MonthSchedule b) {
        final int yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return a.month.compareTo(b.month);
      });
      return schedules;
    } catch (error) {
      throw RepositoryException('Failed to load schedules.', error);
    }
  }

  Future<MonthSchedule?> getByMonth(int year, int month) async {
    try {
      final Box<MonthSchedule> box = await _ensureBox();
      return box.get(_key(year, month));
    } catch (error) {
      throw RepositoryException('Failed to load schedule.', error);
    }
  }

  Future<void> save(MonthSchedule schedule) async {
    try {
      final Box<MonthSchedule> box = await _ensureBox();
      await box.put(_key(schedule.year, schedule.month), schedule);
    } catch (error) {
      throw RepositoryException('Failed to save schedule.', error);
    }
  }

  Future<void> delete(int year, int month) async {
    try {
      final Box<MonthSchedule> box = await _ensureBox();
      await box.delete(_key(year, month));
    } catch (error) {
      throw RepositoryException('Failed to delete schedule.', error);
    }
  }

  Future<void> clear() async {
    try {
      final Box<MonthSchedule> box = await _ensureBox();
      await box.clear();
    } catch (error) {
      throw RepositoryException('Failed to clear schedules.', error);
    }
  }

  Future<Box<MonthSchedule>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  String _key(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
