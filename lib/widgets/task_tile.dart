import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/id_date.dart';

/// Satu baris tugas bergaya buku catatan: tanpa kartu, hanya garis tipis.
/// Prioritas dibaca dari cincin checkbox (tebal + aksen = Penting).
class TaskTile extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = task.completed;
    final isLate = task.isLate;

    final ringColor = switch (task.priority) {
      'Penting' => cs.secondary,
      'Normal' => cs.onSurface,
      _ => cs.outline,
    };
    final priorityColor = switch (task.priority) {
      'Penting' => cs.secondary,
      'Normal' => cs.onSurface,
      _ => cs.outline,
    };

    final meta = <InlineSpan>[];
    void add(String text, Color color, {FontWeight? weight}) {
      if (meta.isNotEmpty) {
        meta.add(TextSpan(
            text: '  ·  ', style: TextStyle(color: cs.outlineVariant)));
      }
      meta.add(TextSpan(
          text: text, style: TextStyle(color: color, fontWeight: weight)));
    }

    if (isLate) {
      add('TERLAMBAT ${task.lateDays} HARI', cs.secondary,
          weight: FontWeight.w700);
    } else if (task.dueGroup == 'Mendatang' && task.dueDay != null) {
      add(shortDate(task.dueDay!).toUpperCase(), cs.outline);
    }
    if (task.dueTime != null) add(task.dueTime!, cs.outline);
    add(task.priority.toUpperCase(), done ? cs.outline : priorityColor);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color: isLate ? cs.secondary : Colors.transparent, width: 3),
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.only(left: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 6,
        minVerticalPadding: 10,
        onTap: () => onToggle(!done),
        leading: Checkbox(
          value: done,
          onChanged: (v) => onToggle(v ?? false),
          shape: const CircleBorder(),
          side: BorderSide(
              color: ringColor, width: task.priority == 'Penting' ? 2.4 : 1.5),
          activeColor: cs.primary,
          checkColor: cs.onPrimary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: done ? cs.outline : cs.onSurface,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: cs.outline,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text.rich(
            TextSpan(
              style: AppText.mono(size: 10.5, color: cs.outline),
              children: meta,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, color: cs.outline),
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah Tugas')),
            PopupMenuItem(value: 'delete', child: Text('Hapus Tugas')),
          ],
        ),
      ),
    );
  }
}
