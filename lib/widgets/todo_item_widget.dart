import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../utils/app_theme.dart';

class TodoItemWidget extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (todo.priority) {
      case TodoPriority.high:
        return AppTheme.highPriority;
      case TodoPriority.medium:
        return AppTheme.mediumPriority;
      case TodoPriority.low:
        return AppTheme.lowPriority;
    }
  }

  String get _dDayLabel {
    final days = todo.daysRemaining;
    if (days == null) return '';
    if (days == 0) return 'D-Day!';
    if (days > 0) return 'D-$days';
    return 'D+${-days}';
  }

  Color get _dDayColor {
    final days = todo.daysRemaining;
    if (days == null) return Colors.grey;
    if (days <= 0) return AppTheme.error;
    if (days <= 3) return AppTheme.warning;
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(todo.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: '편집',
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: '삭제',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: todo.isCompleted
                            ? AppTheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: todo.isCompleted
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: todo.isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                todo.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.isCompleted
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (todo.isDDay && todo.dueDate != null)
                              _DDayBadge(label: _dDayLabel, color: _dDayColor),
                          ],
                        ),
                        if (todo.description != null &&
                            todo.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (todo.dueDate != null)
                              _InfoChip(
                                icon: Icons.calendar_today_rounded,
                                label: DateFormat('M/d').format(todo.dueDate!),
                                color: todo.isOverdue
                                    ? AppTheme.error
                                    : Colors.grey.shade600,
                              ),
                            if (todo.dueTime != null)
                              _InfoChip(
                                icon: Icons.access_time_rounded,
                                label: DateFormat('HH:mm').format(todo.dueTime!),
                                color: Colors.grey.shade600,
                              ),
                            if (todo.isRoutine)
                              _InfoChip(
                                icon: Icons.repeat_rounded,
                                label: '루틴',
                                color: AppTheme.accent,
                              ),
                            if (todo.repeatType != RepeatType.none)
                              _InfoChip(
                                icon: Icons.loop_rounded,
                                label: _repeatLabel(todo.repeatType),
                                color: AppTheme.primaryLight,
                              ),
                            if (todo.category != null &&
                                todo.category!.isNotEmpty)
                              _InfoChip(
                                icon: Icons.label_rounded,
                                label: todo.category!,
                                color: AppTheme.primary,
                              ),
                            if (todo.googleCalendarEventId != null)
                              _InfoChip(
                                icon: Icons.event_rounded,
                                label: 'Google',
                                color: const Color(0xFF4285F4),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _repeatLabel(RepeatType type) {
    switch (type) {
      case RepeatType.daily:
        return '매일';
      case RepeatType.weekly:
        return '매주';
      case RepeatType.monthly:
        return '매월';
      case RepeatType.custom:
        return '사용자 설정';
      case RepeatType.none:
        return '';
    }
  }
}

class _DDayBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DDayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
