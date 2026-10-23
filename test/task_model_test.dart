import 'package:flutter_test/flutter_test.dart';
import 'package:hariku_app/models/task_model.dart';
import 'package:hariku_app/utils/id_date.dart';

Map<String, dynamic> _json({
  Object? due,
  int priority = 1,
  bool checked = false,
}) =>
    {
      'id': '6abc',
      'content': 'Kerjakan laporan UTS',
      'priority': priority,
      'checked': checked,
      'due': due,
    };

String _dayOffset(int days) =>
    formatApiDate(DateTime.now().add(Duration(days: days)));

void main() {
  group('TaskModel.fromJson', () {
    test('memetakan field dasar', () {
      final t = TaskModel.fromJson(_json(priority: 4, checked: true));
      expect(t.id, '6abc');
      expect(t.title, 'Kerjakan laporan UTS');
      expect(t.completed, true);
      expect(t.priority, 'Penting');
    });

    test('prioritas Todoist dipetakan ke label HariKu', () {
      expect(TaskModel.priorityFromApi(4), 'Penting');
      expect(TaskModel.priorityFromApi(3), 'Penting');
      expect(TaskModel.priorityFromApi(2), 'Normal');
      expect(TaskModel.priorityFromApi(1), 'Bisa Nanti');
      expect(TaskModel.priorityToApi('Penting'), 4);
    });

    test('tanpa due -> Tanpa Tanggal', () {
      expect(TaskModel.fromJson(_json()).dueGroup, 'Tanpa Tanggal');
    });

    test('kelompok tanggal dihitung dari hari ini', () {
      String group(int offset) => TaskModel.fromJson(
              _json(due: {'date': _dayOffset(offset)}))
          .dueGroup;
      expect(group(-2), 'Terlambat');
      expect(group(0), 'Hari Ini');
      expect(group(1), 'Besok');
      expect(group(5), 'Mendatang');
    });

    test('tugas lewat tenggat dan belum selesai ditandai terlambat', () {
      final t = TaskModel.fromJson(_json(due: {'date': _dayOffset(-3)}));
      expect(t.isLate, true);
      expect(t.lateDays, 3);
      t.completed = true;
      expect(t.isLate, false);
    });

    test('jam tenggat dibaca dari due yang memiliki waktu', () {
      final t = TaskModel.fromJson(
          _json(due: {'date': '${_dayOffset(0)}T14:30:00'}));
      expect(t.dueTime, '14:30');
      expect(t.dueGroup, 'Hari Ini');
    });
  });
}
