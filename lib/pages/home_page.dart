import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/id_date.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_tile.dart';
import '../main.dart'; // To access flutterLocalNotificationsPlugin

/// Halaman utama HariKu: memuat tugas dari Todoist (FR-04 s.d. FR-12).
class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiService _api;
  late Future<List<TaskModel>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'Semua';

  /// Tugas yang dicentang pada sesi berjalan. Todoist mengeluarkannya dari
  /// daftar aktif begitu di-close, jadi kita simpan di sini agar tetap
  /// tampil (dengan coretan) dan tetap dihitung ke progres.
  final Map<String, TaskModel> _doneCache = {};

  /// Data terakhir yang berhasil dimuat — dipakai agar UI tetap tampil
  /// selama future baru masih loading (tanpa layar kosong/berkedip).
  List<TaskModel>? _lastData;

  static const _filters = [
    'Semua',
    'Terlambat',
    'Hari Ini',
    'Besok',
    'Mendatang',
    'Tanpa Tanggal',
  ];

  @override
  void initState() {
    super.initState();
    _api = ApiService(const String.fromEnvironment('TODOIST_TOKEN'));
    _future = _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<TaskModel>> _load() async {
    final active = await _api.fetchTasks();
    // Gabungkan cache: tugas yang baru dicentang tidak lagi ikut dari API
    // (sudah di-close), tapi tetap ditampilkan agar progres tidak mundur.
    final merged = <TaskModel>[];
    final seen = <String>{};
    for (final t in active) {
      seen.add(t.id);
      final cached = _doneCache[t.id];
      // Tugas yang ada di cache selalu dianggap selesai.
      merged.add(cached != null ? (t..completed = true) : t);
    }
    for (final t in _doneCache.values) {
      if (!seen.contains(t.id)) merged.add(t);
    }
    // Jadwalkan notifikasi untuk tugas aktif yang punya dueTime
    for (final t in active) {
      if (!t.completed) {
        _scheduleNotification(t);
      }
    }
    return merged;
  }

  void _refresh() {
    // Catatan: jangan pakai `setState(() => _future = _load())` — arrow
    // mengembalikan nilai Future dan Flutter akan melempar error
    // "setState() callback argument returned a Future".
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  // ---------------------------------------------------------------- aksi --

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (success != null) _snack(success);
      _refresh();
    } on ApiException catch (e) {
      _snack('Gagal: ${e.message}');
    } catch (e) {
      _snack('Gagal: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _scheduleNotification(TaskModel task) async {
    if (task.dueDay == null || task.dueTime == null || task.completed) {
      await flutterLocalNotificationsPlugin.cancel(id: task.id.hashCode);
      return;
    }

    try {
      final timeParts = task.dueTime!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledDate = tz.TZDateTime(
        tz.local,
        task.dueDay!.year,
        task.dueDay!.month,
        task.dueDay!.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: 'Deadline Tugas',
        body: task.title,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'hariku_tasks',
            'Pengingat Tugas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _addTask() async {
    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (_) => const TaskDialog(),
    );
    if (result == null) return;
    final task = TaskModel(
      id: '',
      title: result.title,
      completed: false,
      priority: result.priority,
      dueDay: result.due,
      dueTime: result.time,
    );
    await _run(() async {
      final id = await _api.createTask(task);
      final newTask = TaskModel(
        id: id,
        title: task.title,
        completed: task.completed,
        priority: task.priority,
        dueDay: task.dueDay,
        dueTime: task.dueTime,
      );
      await _scheduleNotification(newTask);
    }, success: 'Tugas dicatat');
  }

  Future<void> _editTask(TaskModel task) async {
    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (_) => TaskDialog(task: task),
    );
    if (result == null) return;
    task
      ..title = result.title
      ..priority = result.priority
      ..dueDay = result.due
      ..dueTime = result.time;
    await _run(() async {
      await _api.updateTask(task);
      await _scheduleNotification(task);
    }, success: 'Tugas diperbarui');
  }

  Future<void> _deleteTask(TaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: const Text('Hapus tugas?'),
        content: Text('"${task.title}" akan dihapus permanen dari Todoist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _doneCache.remove(task.id);
    await _run(() async {
      await _api.deleteTask(task.id);
      await flutterLocalNotificationsPlugin.cancel(id: task.id.hashCode);
    }, success: 'Tugas dihapus');
  }

  void _toggle(TaskModel task, bool value) {
    // Optimistis: ubah tampilan dulu, kembalikan bila API gagal.
    setState(() => task.completed = value);
    _api.setCompleted(task, value).then((_) {
      if (!mounted) return;
      setState(() {
        if (value) {
          // Ditutup di Todoist → hilang dari API, tapi tetap tampil di UI.
          _doneCache[task.id] = task;
        } else {
          // Dibuka lagi → kembali ke daftar aktif Todoist.
          _doneCache.remove(task.id);
        }
      });
      _scheduleNotification(task);
      _refresh();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => task.completed = !value);
      _snack('Gagal menyinkronkan: $e');
    });
  }

  // ------------------------------------------------------------- filtering --

  List<TaskModel> _apply(List<TaskModel> tasks) {
    var list = tasks;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    if (_filter != 'Semua') {
      list = list.where((t) => t.dueGroup == _filter).toList();
    }
    return list;
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HariKu', style: AppText.display(size: 26)),
            const SizedBox(height: 2),
            Text(
              '${dayName(DateTime.now())}, ${longDate(DateTime.now())}'
                  .toUpperCase(),
              style: AppText.mono(size: 10.5, color: cs.outline),
            ),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Mode terang / gelap',
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Catat Tugas'),
      ),
      body: !_api.hasToken
          ? _missingToken(cs)
          : FutureBuilder<List<TaskModel>>(
              future: _future,
              builder: (context, snap) {
                // Pertahankan data lama saat refresh/loading, agar halaman
                // tidak berkedip kosong setiap kali daftar dimuat ulang.
                final data = snap.data;
                if (data != null) _lastData = data;

                if (data == null && snap.hasError) {
                  return _errorView(cs, snap.error.toString());
                }
                if (data == null && _lastData == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _content(cs, data ?? _lastData!);
              },
            ),
    );
  }

  Widget _missingToken(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off_outlined, size: 42),
            const SizedBox(height: 14),
            Text('Token Todoist belum diisi', style: AppText.display(size: 20)),
            const SizedBox(height: 10),
            Text(
              'Salin env.example.json menjadi env.json, tempel token Todoist, '
              'lalu jalankan:\nflutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
              style: AppText.mono(size: 11, color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: cs.secondary),
            const SizedBox(height: 14),
            Text('Gagal memuat tugas', style: AppText.display(size: 20)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.mono(size: 11, color: cs.outline),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _refresh, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }

  Widget _content(ColorScheme cs, List<TaskModel> all) {
    // Progres dihitung berdasarkan filter/kategori yang sedang dipilih.
    final scopedTasks = _filter == 'Semua'
        ? all
        : all.where((t) => t.dueGroup == _filter).toList();
    final done = scopedTasks.where((t) => t.completed).length;
    final total = scopedTasks.length;

    final tasks = _apply(all);

    // Kelompokkan sesuai urutan tampilan.
    const order = ['Terlambat', 'Hari Ini', 'Besok', 'Mendatang', 'Tanpa Tanggal'];
    final groups = <String, List<TaskModel>>{
      for (final g in order) g: [],
    };
    for (final t in tasks) {
      groups[t.dueGroup]!.add(t);
    }

    return Column(
      children: [
        _summary(cs, done, total),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Cari tugas…',
              prefixIcon: Icon(Icons.search, color: cs.outline, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, color: cs.outline, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 12.5)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    _query.isNotEmpty || _filter != 'Semua'
                        ? 'Tidak ada tugas yang cocok.'
                        : 'Belum ada tugas. Catat yang pertama!',
                    style: AppText.mono(size: 12, color: cs.outline),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final g in order)
                      if (groups[g]!.isNotEmpty) ...[
                        _sectionHeader(cs, g, groups[g]!.length),
                        for (final t in groups[g]!)
                          TaskTile(
                            task: t,
                            onToggle: (v) => _toggle(t, v),
                            onEdit: () => _editTask(t),
                            onDelete: () => _deleteTask(t),
                          ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _summary(ColorScheme cs, int done, int total) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROGRES ${_filter.toUpperCase()}', style: AppText.mono(size: 10, color: cs.outline)),
                const SizedBox(height: 4),
                Text(
                  '$done dari $total tugas selesai',
                  style: AppText.display(size: 17),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 4,
                  backgroundColor: cs.outlineVariant,
                  color: cs.secondary,
                ),
                Center(
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: AppText.mono(size: 10, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppText.mono(size: 11, color: cs.onSurface)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: cs.outlineVariant)),
          const SizedBox(width: 8),
          Text('$count', style: AppText.mono(size: 11, color: cs.outline)),
        ],
      ),
    );
  }
}
