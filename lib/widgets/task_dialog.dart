import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/id_date.dart';

class TaskFormResult {
  final String title;
  final String priority;
  final DateTime? due;
  final String? time;
  const TaskFormResult(this.title, this.priority, this.due, this.time);
}

/// Dialog tambah / ubah tugas (FR-08, FR-09).
class TaskDialog extends StatefulWidget {
  final TaskModel? task;
  const TaskDialog({super.key, this.task});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late final TextEditingController _titleCtrl;
  late String _priority;
  DateTime? _due;
  String? _time; // HH:mm
  String? _error;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _priority = widget.task?.priority ?? 'Normal';
    _due = widget.task == null ? dateOnly(DateTime.now()) : widget.task!.dueDay;
    _time = widget.task?.dueTime;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Judul tugas tidak boleh kosong');
      return;
    }
    Navigator.of(context).pop(TaskFormResult(title, _priority, _due, _time));
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _due = dateOnly(picked));
      _showTimePicker();
    }
  }

  void _showTimePicker() async {
    final currentTime = _time ?? '00:00';
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(currentTime.split(':')[0]), minute: int.parse(currentTime.split(':')[1])),
    );
    if (selected != null) {
      setState(() => _time = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}');
    }
  }

  Widget _label(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: AppText.mono(size: 10.5, color: cs.outline)),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface,
          )),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final diff = _due == null ? null : daysBetween(_due!, today);
    final isCustom = _due != null && diff != 0 && diff != 1;

    return AlertDialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: cs.outlineVariant),
      ),
      title: Text(_isEdit ? 'Ubah tugas' : 'Catat tugas baru',
          style: AppText.display(size: 24)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Apa yang perlu dikerjakan?',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 22),
            _label('Prioritas'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskModel.priorities
                  .map((p) =>
                      _chip(p, _priority == p, () => setState(() => _priority = p)))
                  .toList(),
            ),
            const SizedBox(height: 22),
            _label('Tenggat'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Hari Ini', diff == 0, () => setState(() => _due = today)),
                _chip('Besok', diff == 1,
                    () => setState(() => _due = today.add(const Duration(days: 1)))),
                _chip(
                  isCustom ? shortDate(_due!) : (_time ?? 'Pilih tanggal & jam…'),
                  isCustom,
                  _pickDate,
                ),
                _chip('Tanpa Tanggal', _due == null, () => setState(() => _due = null)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Simpan' : 'Catat'),
        ),
      ],
    );
  }
}
