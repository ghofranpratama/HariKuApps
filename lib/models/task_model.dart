import '../utils/id_date.dart';

/// Model tugas yang dipetakan dari respons Todoist REST API v1.
///
/// | JSON Todoist        | Atribut Dart | Aturan                                  |
/// |---------------------|--------------|-----------------------------------------|
/// | `id`                | `id`         | String                                  |
/// | `content`           | `title`      | –                                       |
/// | `checked`           | `completed`  | –                                       |
/// | `priority`          | `priority`   | 4,3 → Penting · 2 → Normal · 1 → Bisa Nanti |
/// | `due.date/datetime` | `dueDay`, `dueTime` | dibandingkan dengan hari ini → kelompok tanggal |
class TaskModel {
  final String id;
  String title;
  bool completed;
  String priority; // Penting | Normal | Bisa Nanti
  DateTime? dueDay;
  String? dueTime; // HH:mm

  static const priorities = ['Penting', 'Normal', 'Bisa Nanti'];

  TaskModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.priority,
    this.dueDay,
    this.dueTime,
  });

  /// Konversi prioritas Todoist (1–4) ke label HariKu.
  /// Todoist: 4 = paling mendesak → 1 = biasa.
  static String priorityFromApi(int p) => switch (p) {
        4 || 3 => 'Penting',
        2 => 'Normal',
        _ => 'Bisa Nanti',
      };

  /// Konversi label HariKu ke prioritas Todoist.
  static int priorityToApi(String label) => switch (label) {
        'Penting' => 4,
        'Normal' => 2,
        _ => 1,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? dueDay;
    String? dueTime;

    final due = json['due'];
    if (due is Map<String, dynamic>) {
      // `due.date` = yyyy-MM-dd · `due.datetime` = yyyy-MM-ddTHH:mm:ss
      final raw = (due['datetime'] ?? due['date'])?.toString();
      if (raw != null && raw.isNotEmpty) {
        final datePart = raw.split('T').first;
        final parts = datePart.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            dueDay = DateTime(y, m, d);
          }
        }
        if (raw.contains('T')) {
          final timePart = raw.split('T').last;
          final hm = timePart.split(':');
          if (hm.length >= 2) {
            dueTime = '${hm[0].padLeft(2, '0')}:${hm[1].padLeft(2, '0')}';
          }
        }
      }
    }

    final priorityApi = (json['priority'] as num?)?.toInt() ?? 1;

    return TaskModel(
      id: json['id'].toString(),
      title: (json['content'] ?? '') as String,
      completed: (json['checked'] ?? json['is_completed'] ?? false) as bool,
      priority: priorityFromApi(priorityApi),
      dueDay: dueDay,
      dueTime: dueTime,
    );
  }

  /// Payload untuk dikirim kembali ke Todoist (create / update).
  Map<String, dynamic> toApiJson() => {
        'content': title,
        'priority': priorityToApi(priority),
        if (dueDay == null)
          'due_string': 'no date' // hapus tenggat di Todoist
        else if (dueTime != null)
          'due_datetime': '${formatApiDate(dueDay!)}T${dueTime!}:00'
        else
          'due_date': formatApiDate(dueDay!),
      };

  /// Kelompok tanggal berdasarkan hari ini.
  String get dueGroup {
    if (dueDay == null) return 'Tanpa Tanggal';
    final diff = daysBetween(dueDay!, dateOnly(DateTime.now()));
    if (diff < 0) return 'Terlambat';
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Besok';
    return 'Mendatang';
  }

  /// Lewat tenggat dan belum selesai.
  bool get isLate =>
      dueDay != null &&
      !completed &&
      daysBetween(dateOnly(DateTime.now()), dueDay!) > 0;

  /// Jumlah hari keterlambatan (0 bila bukan tugas terlambat).
  int get lateDays {
    if (!isLate) return 0;
    return daysBetween(dateOnly(DateTime.now()), dueDay!);
  }
}
